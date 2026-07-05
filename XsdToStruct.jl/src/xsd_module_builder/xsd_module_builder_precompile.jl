const SAMPLE_SCALAR_VALUES = Dict(
    "String" => "x",
    "Float64" => "0",
    "Bool" => "false",
    "Int64" => "0",
    "UInt64" => "0",
    "Union{ZonedDateTime, DateTime}" => "2000-01-01T00:00:00",
)

function find_defined_node(
    qualified_type_name::AbstractString,
    xsd_module_builder::XSDStructModuleBuilderType,
)::Union{Nothing,AbstractTreeNode}
    idx = findfirst(==(qualified_type_name) ∘ qualified_name, xsd_module_builder.defined_nodes)
    return isnothing(idx) ? nothing : xsd_module_builder.defined_nodes[idx]
end

"""
    sample_xml_for_type(qualified_type_name, julia_type, xsd_module_builder)::Union{Nothing,String}

Returns the inner XML text/content for a value of the given type — a scalar literal for a
built-in Julia type, or the recursively-built child-element XML for a defined complex/simple
type. Returns `nothing` if the type can't be resolved (unhandled tree-node kind, e.g. a union or
extension) — callers must treat `nothing` as "omit this field", never as an error.
"""
function sample_xml_for_type(
    qualified_type_name::AbstractString,
    julia_type::AbstractString,
    xsd_module_builder::XSDStructModuleBuilderType,
)::Union{Nothing,String}
    haskey(SAMPLE_SCALAR_VALUES, julia_type) && return SAMPLE_SCALAR_VALUES[julia_type]

    node = find_defined_node(qualified_type_name, xsd_module_builder)
    isnothing(node) && return nothing

    if node isa ComplexTreeNode
        return sample_xml_for_complex(node, xsd_module_builder)
    elseif node isa SimpleTreeNode
        # a restricted simple type wraps a base scalar type; recurse one level using that base
        # type's own julia_type as both the qualified name and the julia type to look up — this
        # naturally handles arbitrarily-stacked simple types (a simple type restricting another
        # simple type) since it just recurses again.
        return sample_xml_for_type(node.field.julia_type, node.field.julia_type, xsd_module_builder)
    else
        # UnionTreeNode, ExtensionTreeNode, or any future node kind — not handled in v1, treat as
        # unresolvable so the caller omits the field. Safe: the generated module's
        # @compile_workload block wraps the actual load() call in a try/catch, so an incomplete
        # sample instance only forfeits the warm-up for this one schema, never breaks it.
        return nothing
    end
end

function sample_xml_for_complex(node::ComplexTreeNode, xsd_module_builder::XSDStructModuleBuilderType)::String
    parts = String[]
    for field in get_all_fields(node)
        field_xml = sample_xml_for_field(field, xsd_module_builder)
        isnothing(field_xml) || push!(parts, field_xml)
    end
    return join(parts)
end

sample_xml_for_field(::GroupFieldData, ::XSDStructModuleBuilderType)::Nothing = nothing

function sample_xml_for_field(field::FieldData, xsd_module_builder::XSDStructModuleBuilderType)::Union{Nothing,String}
    field.can_be_missing && return nothing
    inner = sample_xml_for_type(qualified_type(field), field.julia_type, xsd_module_builder)
    isnothing(inner) && return nothing
    return "<$(field.name)>$inner</$(field.name)>"
end

function sample_xml_for_field(
    field::ChoiceFieldData,
    xsd_module_builder::XSDStructModuleBuilderType,
)::Union{Nothing,String}
    field.can_be_missing && return nothing
    isempty(field.choice_options) && return nothing
    return sample_xml_for_field(first(field.choice_options), xsd_module_builder)
end

"""
    synthesize_sample_xml(xsd_module_builder::XSDStructModuleBuilderType)::Union{Nothing,String}

Builds a minimal, type-parseable (not restriction-satisfying) XML instance for the schema's root
type, for use in the generated module's own `@compile_workload` warm-up block. Must be called after
`write_struct_module_to_io` has populated `xsd_module_builder.defined_nodes` — the type lookups
here depend on every complex/simple/union type in the schema already being registered there.

Returns `nothing` only if the root type itself can't be resolved (shouldn't happen in practice —
the root type is always a defined node by the time struct-writing completes).
"""
function synthesize_sample_xml(xsd_module_builder::XSDStructModuleBuilderType)::Union{Nothing,String}
    root_field = xsd_module_builder.xsd_tree.root_field
    inner = sample_xml_for_type(qualified_type(root_field), root_field.julia_type, xsd_module_builder)
    isnothing(inner) && return nothing
    return "<$(root_field.name)>$inner</$(root_field.name)>"
end
