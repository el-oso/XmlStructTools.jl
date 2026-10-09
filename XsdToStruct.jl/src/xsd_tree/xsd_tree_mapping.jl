"""
    NameMapping(mapping::AbstractDict)

Renames applied to an xsd tree: `fields` maps xsd element names to Julia field names, `types` maps
xsd type names to Julia type names.

`mapping` takes one of two forms. A flat `"xsd_name" => "julia_name"` dictionary applies to element
and type names alike. A dictionary with the keys `"Fields"` and `"Types"` holds the two separately,
and either key may be left out.
"""
struct NameMapping
    fields::Dict{String, String}
    types::Dict{String, String}
end

const MAPPING_KEYS = ("Fields", "Types")

function NameMapping(mapping::AbstractDict)
    if any(in(MAPPING_KEYS), keys(mapping))
        unknown = filter(!in(MAPPING_KEYS), collect(keys(mapping)))
        isempty(unknown) || throw(
            ArgumentError(
                "a mapping with \"Fields\" or \"Types\" may hold only those two keys, found $(repr(unknown))",
            ),
        )
        return NameMapping(
            Dict{String, String}(get(mapping, "Fields", ())),
            Dict{String, String}(get(mapping, "Types", ())),
        )
    end
    flat = Dict{String, String}(mapping)
    return NameMapping(flat, flat)
end

Base.isempty(mapping::NameMapping) = isempty(mapping.fields) && isempty(mapping.types)

# The name part of an xsd reference is renamed and any namespace prefix kept: "ns:Name" -> "ns:New".
function map_xsd_name(xsd_name::AbstractString, renames::Dict{String, String})::String
    colon = findlast(==(':'), xsd_name)
    prefix, name_part = isnothing(colon) ? ("", xsd_name) : (xsd_name[1:colon], xsd_name[(colon + 1):end])
    return prefix * get(renames, name_part, name_part)
end

# A sub-module path is a chain of `sub_module_name(type_name)` components, so each component
# follows its type's rename; otherwise a renamed type would declare a sub-module its fields no
# longer refer to.
function map_sub_module(sub_module::Union{Nothing, AbstractString}, renames::Dict{String, String})
    isnothing(sub_module) && return nothing
    components = map(split(sub_module, ".")) do component
        endswith(component, "Types") || return component
        type_name = chop(component; tail = length("Types"))
        return sub_module_name(get(renames, type_name, type_name))
    end
    return join(components, ".")
end

function map_common_data!(common_data::CommonNodeData, mapping::NameMapping)::Nothing
    common_data.name = map_xsd_name(common_data.name, mapping.types)
    common_data.sub_module = map_sub_module(common_data.sub_module, mapping.types)
    return nothing
end

"""
    apply_mapping!(xsd_tree::SchemaTreeNode, mapping::NameMapping)::Nothing

Rename the elements and types of `xsd_tree` in place.

The schema name, which becomes the module name, cannot be renamed: types that restrict a namespaced
base refer to it as a bare module path, which the renames do not reach.
"""
function apply_mapping!(xsd_tree::SchemaTreeNode, mapping::NameMapping)::Nothing
    isempty(mapping) && return nothing
    schema_name = name(xsd_tree)
    haskey(mapping.types, schema_name) && throw(
        ArgumentError(
            "the mapping renames \"$schema_name\", which names the schema and so the generated module; " *
                "the module name cannot be renamed",
        ),
    )
    apply_mapping!(xsd_tree.root_field, mapping)
    for node in xsd_tree.child_nodes
        apply_mapping!(node, mapping)
    end
    return nothing
end

function apply_mapping!(xsd_node::SimpleTreeNode, mapping::NameMapping)::Nothing
    map_common_data!(xsd_node.common_data, mapping)
    # The field of a simple type is always `value`; only the type it holds is renamed.
    map_field_type!(xsd_node.field, mapping)
    return nothing
end

function apply_mapping!(xsd_node::ComplexTreeNode, mapping::NameMapping)::Nothing
    xsd_name = name(xsd_node)
    map_common_data!(xsd_node.common_data, mapping)
    rename_choice_fields!(xsd_node.fields, xsd_name, name(xsd_node))
    map!(field_name -> choice_field_name(field_name, xsd_name, name(xsd_node)), xsd_node.field_ordering, xsd_node.field_ordering)
    foreach(field -> apply_mapping!(field, mapping), xsd_node.fields)
    foreach(field -> apply_mapping!(field, mapping), xsd_node.child_fields)
    foreach(node -> apply_mapping!(node, mapping), xsd_node.child_nodes)
    map!(name -> map_xsd_name(name, mapping.fields), xsd_node.field_ordering, xsd_node.field_ordering)
    return nothing
end

# The base fields and base children of an extension are the base type's own objects, which are
# renamed with the base type; only the extension's copy of the base field order is its own.
function apply_mapping!(xsd_node::ExtensionTreeNode, mapping::NameMapping)::Nothing
    map_common_data!(xsd_node.common_data, mapping)
    xsd_base_name = xsd_node.base_name
    xsd_node.base_name = map_xsd_name(xsd_base_name, mapping.types)
    apply_mapping!(xsd_node.node_content, mapping)
    map!(
        field_name -> map_xsd_name(choice_field_name(field_name, xsd_base_name, xsd_node.base_name), mapping.fields),
        xsd_node.base_field_ordering,
        xsd_node.base_field_ordering,
    )
    return nothing
end

# A choice field is named `__<Type>_choice_<n>` after the type that holds it, and the generated
# `propertynames` hides the type's fields by that prefix, so the field follows the type's rename.
function choice_field_name(field_name::AbstractString, xsd_type_name::AbstractString, julia_type_name::AbstractString)
    xsd_prefix = "__$(xsd_type_name)_choice_"
    startswith(field_name, xsd_prefix) || return field_name
    return "__$(julia_type_name)_choice_" * field_name[(ncodeunits(xsd_prefix) + 1):end]
end

function rename_choice_fields!(fields, xsd_type_name::AbstractString, julia_type_name::AbstractString)::Nothing
    for field in fields
        field isa ChoiceFieldData || continue
        field.name = choice_field_name(field.name, xsd_type_name, julia_type_name)
    end
    return nothing
end

function apply_mapping!(xsd_node::UnionTreeNode, mapping::NameMapping)::Nothing
    map_common_data!(xsd_node.common_data, mapping)
    foreach(node -> apply_mapping!(node, mapping), xsd_node.union_nodes)
    return nothing
end

function apply_mapping!(field_data::FieldData, mapping::NameMapping)::Nothing
    field_data.name = map_xsd_name(field_data.name, mapping.fields)
    map_field_type!(field_data, mapping)
    return nothing
end

# The Julia type is derived again from the renamed xsd type rather than renamed itself: a built-in
# xsd type such as "double" must stay `Float64` even when a schema type named "Float64" is renamed.
function map_field_type!(field_data::FieldData, mapping::NameMapping)::Nothing
    field_data.xsd_type = map_xsd_name(field_data.xsd_type, mapping.types)
    field_data.julia_type = parse_xsd_type_to_julia_type(field_data.xsd_type)
    field_data.sub_module = map_sub_module(field_data.sub_module, mapping.types)
    return nothing
end

function apply_mapping!(field_data::ChoiceFieldData, mapping::NameMapping)::Nothing
    field_data.name = map_xsd_name(field_data.name, mapping.fields)
    foreach(option -> apply_mapping!(option, mapping), field_data.choice_options)
    field_data.julia_type = choice_julia_type(Vector{AbstractFieldData}(field_data.choice_options))
    field_data.sub_module = map_sub_module(field_data.sub_module, mapping.types)
    return nothing
end

# Groups are substituted into their parents before the mapping is applied.
apply_mapping!(::GroupFieldData, ::NameMapping)::Nothing = nothing
