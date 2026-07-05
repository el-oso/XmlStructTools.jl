include("xsd_module_builder_simple.jl")
include("xsd_module_builder_union.jl")

function write_struct_module_to_io(xsd_module_builder::XSDStructModuleBuilderType)::Nothing
    print(xsd_module_builder.io_struct, "module $(xsd_module_builder.module_name_struct)\n\n")

    if xsd_module_builder.xsd_tree.requires_TimeZones
        print(xsd_module_builder.io_struct, "using Reexport\n")
        print(xsd_module_builder.io_struct, "@reexport using Dates\n")
        print(xsd_module_builder.io_struct, "@reexport using TimeZones\n")
    end

    writeln(xsd_module_builder, IOStruct, "import $ABSTRACT_TYPE_PACKAGE")
    writeln(xsd_module_builder, IOStruct, "using LazilyInitializedFields")
    writeln(xsd_module_builder, IOStruct, "import XmlStructLoader")
    write(xsd_module_builder, IOStruct, "\n")

    # first pass
    for child_node in xsd_module_builder.xsd_tree.child_nodes
        write_node(child_node, xsd_module_builder)
    end

    @debug "Defined node names:\n$(defined_node_names(xsd_module_builder))"
    @debug "Skipped node names:\n$(skipped_node_names(xsd_module_builder))"

    # loop skipped until done
    loops = 0
    previous_missing_nodes = length(xsd_module_builder.skipped_nodes)
    while previous_missing_nodes > 0
        skipped_nodes = copy(xsd_module_builder.skipped_nodes)
        resize!(xsd_module_builder.skipped_nodes, 0)
        for node in skipped_nodes
            write_node(node, xsd_module_builder)
        end

        loops += 1
        missing_nodes = length(xsd_module_builder.skipped_nodes)
        @debug "Loops over skipped nodes =  $loops, $missing_nodes nodes still missing."

        @debug "Defined node names:\n$(defined_node_names(xsd_module_builder))"
        @debug "Skipped node names:\n$(skipped_node_names(xsd_module_builder))"

        if missing_nodes == previous_missing_nodes
            @warn "No more nodes defined with respect to previous loop, stopping the loop over missed nodes."
            @warn "Still missing:\n$(xsd_module_builder.skipped_nodes)"
            break
        elseif missing_nodes > previous_missing_nodes
            error(
                "Amount of missing nodes has increased from $previous_missing_nodes to $missing_nodes;" *
                "something is wrong, stopping here.",
            )
        end

        previous_missing_nodes = missing_nodes
    end

    println(xsd_module_builder.io_struct, "end")

    return nothing
end

function write_node_specific(
    xsd_node::ComplexTreeNode,
    xsd_module_builder::XSDStructModuleBuilderType,
    indent_level::Int,
)::Bool
    @debug "Writing as $(ComplexTreeNode)"

    undefined_child_nodes =
        filter(child_node -> qualified_name(child_node) ∉ defined_node_names(xsd_module_builder), xsd_node.child_nodes)

    if !isempty(undefined_child_nodes)
        write_child_submodule(
            sub_module_name(name(xsd_node)),
            undefined_child_nodes,
            xsd_module_builder,
            indent_level = indent_level,
        )
    end

    choice_fields = get_all_fields_of_type(xsd_node, ChoiceFieldData)

    if isempty(choice_fields)
        # write_node_no_choice writes its own docstring (write_lazy_docstring), placed after the
        # @lazy struct block - see that function's docstring for why.
        write_node_no_choice(xsd_node, xsd_module_builder, indent_level)
    else
        write_docstring(xsd_node, xsd_module_builder, indent_level)
        @debug "Found choice fields: $(getproperty.(choice_fields, :name))"
        write_node_with_choice(xsd_node, choice_fields, xsd_module_builder, indent_level)
    end

    return true
end

function write_child_submodule(
    sub_module_name::AbstractString,
    sub_module_nodes::Vector{AbstractTreeNode},
    xsd_module_builder::XSDStructModuleBuilderType;
    indent_level::Int,
)::Nothing
    @debug "Writing submodule $(sub_module_name) for nodes:\n$(name.(sub_module_nodes))"

    writeln(xsd_module_builder, IOStruct, "module $(sub_module_name)", indent_level = indent_level)

    write(xsd_module_builder, IOStruct, "\n")

    write(xsd_module_builder, IOStruct, "\n")

    writeln(xsd_module_builder, IOStruct, "import AbstractXsdTypes", indent_level = indent_level + 1)
    # A node written into this submodule may itself be choice-free (write_node_no_choice emits
    # @lazy struct unconditionally) - @lazy must be brought into scope here too, since `using` in
    # the enclosing module is not inherited by a nested module.
    writeln(xsd_module_builder, IOStruct, "using LazilyInitializedFields", indent_level = indent_level + 1)
    writeln(xsd_module_builder, IOStruct, "import XmlStructLoader", indent_level = indent_level + 1)

    write(xsd_module_builder, IOStruct, "\n")

    writeln(
        xsd_module_builder,
        IOStruct,
        "using ..$(xsd_module_builder.module_name_struct)",
        indent_level = indent_level + 1,
    )

    write(xsd_module_builder, IOStruct, "\n")

    for node in sub_module_nodes
        write_node(node, xsd_module_builder, export_line = false, indent_level = indent_level + 1)
    end

    writeln(xsd_module_builder, IOStruct, "end", indent_level = indent_level)

    write(xsd_module_builder, IOStruct, "\n")

    writeln(xsd_module_builder, IOStruct, "export $(sub_module_name)", indent_level = indent_level)

    return write(xsd_module_builder, IOStruct, "\n")
end

function write_node_no_choice(
    xsd_node::ComplexTreeNode,
    xsd_module_builder::XSDStructModuleBuilderType,
    indent_level::Int,
)
    @debug "writing with no choice fields"

    all_fields = get_all_fields(xsd_node)

    if !is_lazy_capable(xsd_node)
        # Zero real (non-GroupFieldData) data fields - e.g. an inline `<complexType/>` with no
        # content. LazilyInitializedFields.@lazy requires at least one @lazy-tagged field, and
        # there's nothing to gain from laziness on a type with no fields anyway, so fall back to
        # the plain (pre-Task-3) struct - exactly what write_node_with_choice's sibling used to
        # emit for every choice-free node before this task.
        return write_plain_node(xsd_node, xsd_module_builder, all_fields, indent_level)
    end

    writeln(
        xsd_module_builder,
        IOStruct,
        struct_line_string(name(xsd_node), "$ABSTRACT_TYPE_PACKAGE.AbstractXSDComplex"; lazy = true),
        indent_level = indent_level,
    )

    writeln(
        xsd_module_builder,
        IOStruct,
        "_node::Union{Nothing, XmlStructLoader.LazyNode}";
        indent_level = indent_level + 1,
    )

    @debug "Writing fields: $(getproperty.(all_fields, :name))"
    for field in all_fields
        field isa GroupFieldData && continue
        field_string = generate_lazy_field_string(field)
        writeln(xsd_module_builder, IOStruct, field_string, indent_level = indent_level + 1)
    end

    # No inline "= default" here (unlike the eager Base.@kwdef path): @lazy struct expands into a
    # plain `mutable struct`, which - like any non-@kwdef struct - rejects field-level default
    # value syntax. Both constructors below supply __xml_attributes/__validated explicitly instead.
    writeln(
        xsd_module_builder,
        IOStruct,
        "__xml_attributes::Union{Nothing, Dict{String, String}}";
        indent_level = indent_level + 1,
    )
    writeln(xsd_module_builder, IOStruct, "__validated::Bool"; indent_level = indent_level + 1)

    write(xsd_module_builder, IOStruct, "end\n\n", indent_level = indent_level)

    write_defaults_function(xsd_module_builder, name(xsd_node), all_fields, indent_level = indent_level)
    write_lazy_node_constructor(xsd_module_builder, xsd_node, all_fields, indent_level)
    write_lazy_outer_kwdef_constructor(xsd_module_builder, xsd_node, all_fields, indent_level)
    write_lazy_field_accessors(xsd_module_builder, xsd_node, all_fields, indent_level)
    write_lazy_docstring(xsd_module_builder, xsd_node, indent_level)

    return push!(xsd_module_builder.defined_nodes, xsd_node)
end

"""
    write_plain_node(xsd_module_builder, xsd_node, all_fields, indent_level)

The pre-Task-3 choice-free struct: plain `Base.@kwdef struct`, no `_node`, no `@lazy` fields. Used
only for the zero-data-field edge case `is_lazy_capable` excludes - see `write_node_no_choice`.
"""
function write_plain_node(
    xsd_node::ComplexTreeNode,
    xsd_module_builder::XSDStructModuleBuilderType,
    all_fields::Vector{<:AbstractFieldData},
    indent_level::Int,
)::Nothing
    write_docstring(xsd_node, xsd_module_builder, indent_level)

    writeln(
        xsd_module_builder,
        IOStruct,
        struct_line_string(name(xsd_node), "$ABSTRACT_TYPE_PACKAGE.AbstractXSDComplex"),
        indent_level = indent_level,
    )

    for field in all_fields
        field_string = generate_field_string(field)
        writeln(xsd_module_builder, IOStruct, field_string, indent_level = indent_level + 1)
    end

    writeln(
        xsd_module_builder,
        IOStruct,
        "__xml_attributes::Union{Nothing, Dict{String, String}} = nothing";
        indent_level = indent_level + 1,
    )
    writeln(xsd_module_builder, IOStruct, "__validated::Bool = true"; indent_level = indent_level + 1)

    write(xsd_module_builder, IOStruct, "end\n\n", indent_level = indent_level)
    write_defaults_function(xsd_module_builder, name(xsd_node), all_fields, indent_level = indent_level)
    push!(xsd_module_builder.defined_nodes, xsd_node)
    return nothing
end

"""
    write_lazy_docstring(xsd_module_builder, xsd_node, indent_level)

`@lazy struct ... end` macroexpands to several separate top-level forms (the struct itself, plus
`islazyfield`/`getproperty` method definitions) - Julia's docsystem cannot attach a docstring
literal placed directly above a macro call whose expansion is a multi-statement block ("cannot
document the following expression"), unlike the plain `struct ... end` the choice-bearing path
still emits. Attaching the docstring after the fact with the `@doc str Name` form sidesteps this;
it is the documented workaround for exactly this class of macro, not a new invention.
"""
function write_lazy_docstring(
    xsd_module_builder::XSDStructModuleBuilderType,
    xsd_node::ComplexTreeNode,
    indent_level::Int,
)::Nothing
    docstring = xsd_docstring(xsd_node)
    isnothing(docstring) && return nothing

    writeln(xsd_module_builder, IOStruct, "@doc \"\"\"", indent_level = indent_level)
    writeln(xsd_module_builder, IOStruct, docstring, indent_level = indent_level)
    writeln(xsd_module_builder, IOStruct, "\"\"\" $(name(xsd_node))", indent_level = indent_level)
    return write(xsd_module_builder, IOStruct, "\n")
end

"""
    generate_lazy_field_string(field_data::AbstractFieldData)::String

Same field-type computation as `generate_field_string`, but declares the field `@lazy` with a
named initializer function `_init_<field_name>` - `LazilyInitializedFields.jl`'s own macro-generated
`getproperty` override calls this function automatically on first access to the field and caches
the result, so no manual "check uninit, call, cache" code is needed anywhere else.
"""
function generate_lazy_field_string(field_data::AbstractFieldData)::String
    full_field_type = qualified_type(field_data)

    full_field_type = lazy_field_full_type(field_data)
    return "@lazy $(field_data.name)::$(full_field_type) = _init_$(field_data.name)"
end

"""
    lazy_field_full_type(field_data::AbstractFieldData)::String

The Vector/Union{Nothing,...}-wrapped field type string (same computation `generate_lazy_field_string`
uses for the `@lazy` field declaration itself) - reused by the constructors below so a supplied
value can be `convert`ed to this *exact* type before reaching the struct's own default constructor.
"""
function lazy_field_full_type(field_data::AbstractFieldData)::String
    full_field_type = qualified_type(field_data)

    if field_data.is_vector
        full_field_type = "Vector{$(full_field_type)}"
    end

    if field_data.can_be_missing
        full_field_type = "Union{Nothing, $(full_field_type)}"
    end

    return full_field_type
end

"""
    write_lazy_node_constructor(xsd_module_builder, xsd_node, all_fields, indent_level)

Emit `StructName(node::XmlStructLoader.LazyNode)` - the entry point `ReadOnAccess` uses. Stores the
node, marks every data field `uninit`, and builds `__xml_attributes` eagerly (cheap, always needed
together) using the same `lazy_attributes_dict` helper `_init_<field>` bodies use elsewhere.
"""
function write_lazy_node_constructor(
    xsd_module_builder::XSDStructModuleBuilderType,
    xsd_node::ComplexTreeNode,
    all_fields::Vector{<:AbstractFieldData},
    indent_level::Int,
)::Nothing
    struct_name = name(xsd_node)
    data_fields = filter(f -> !(f isa GroupFieldData), all_fields)
    uninit_args = repeat("LazilyInitializedFields.uninit, ", length(data_fields))

    ctor = """
    function $struct_name(node::XmlStructLoader.LazyNode)
        attribs = XmlStructLoader.lazy_attributes_dict(node)
        return $struct_name(node, $(uninit_args)isempty(attribs) ? nothing : attribs, false)
    end
    """
    write(xsd_module_builder, IOStruct, ctor, indent_level = indent_level)
    return write(xsd_module_builder, IOStruct, "\n")
end

"""
    write_lazy_outer_kwdef_constructor(xsd_module_builder, xsd_node, all_fields, indent_level)

Emit two constructors that both forward to the `_node`-first raw constructor Julia auto-generates
for the `@lazy struct` (there's no custom inner constructor - `@lazy` only rewrites field types,
see `LazilyInitializedFields.lazy_struct`):

1. A plain positional constructor `StructName(__lazy_arg_1, ..., __lazy_arg_N, __xml_attributes=nothing,
   __validated=true)` - no `_node`, matching exactly the shape
   `AbstractXsdTypes.jl`'s generic `(::Type{T})(values::Vararg; __xml_attributes, __validated) where
   {T<:AbstractXSDComplex}` fallback calls (`T(public_values..., attrs, validated)`), which many
   existing eager-path call sites rely on (`documentType(complex, simple, complex2)`). Only the
   trailing two params get defaults - a data field never gets one here even if `can_be_missing`,
   since Julia requires optional positional args to be trailing and XSD field order can freely
   interleave optional/required fields. The parameters are named `__lazy_arg_<i>`, not the field's
   own name: an XSD element commonly shares its name with its type (e.g. field `Foo::Foo`), and a
   parameter named after the field would shadow that type name inside the function body, breaking
   the `convert` call below (`convert(Foo, Foo)` resolving both operands to the same local value).
   Each argument is explicitly `convert`ed to its true (un-widened) field type before forwarding: the
   raw constructor's own field types are `Union{Uninitialized, T}` for lazy fields, and
   `AbstractXsdTypes`'s `Base.convert(::Type{T}, value) where {T<:AbstractXSDUnion}` only fires when
   `T` is bindable to a bare `AbstractXSDUnion` subtype - it never matches once the type is
   `Union{Uninitialized,...}`-widened. Converting to the bare field type here, before that raw call,
   sidesteps the widened type entirely.
2. A keyword constructor `StructName(; field1=.., ..., __xml_attributes=nothing, __validated=true)`,
   replicating what `Base.@kwdef` would have generated (this and `Base.@kwdef` can't be composed
   directly) - the shape the *eager* `ReadAllData` path calls (see `xml_parser_in_module.jl`'s
   `field_type(; __xml_attributes=..., __validated=..., child_object_dict...)`). Delegates to (1)
   rather than duplicating the `convert` logic; keyword arguments have no "defaults must trail"
   restriction, so `can_be_missing` fields keep their `= nothing` default here.
"""
function write_lazy_outer_kwdef_constructor(
    xsd_module_builder::XSDStructModuleBuilderType,
    xsd_node::ComplexTreeNode,
    all_fields::Vector{<:AbstractFieldData},
    indent_level::Int,
)::Nothing
    struct_name = name(xsd_node)
    data_fields = filter(f -> !(f isa GroupFieldData), all_fields)
    arg_names = ["__lazy_arg_$(i)" for i = 1:length(data_fields)]

    positional_params = copy(arg_names)
    converted_args =
        ["convert($(lazy_field_full_type(field)), $(arg_name))" for (field, arg_name) in zip(data_fields, arg_names)]
    kwarg_params = String[]
    kwarg_args = String[]
    for field in data_fields
        push!(kwarg_params, field.can_be_missing ? "$(field.name) = nothing" : field.name)
        push!(kwarg_args, field.name)
    end
    push!(positional_params, "__xml_attributes = nothing")
    push!(positional_params, "__validated::Bool = true")
    push!(converted_args, "__xml_attributes")
    push!(converted_args, "__validated")
    push!(kwarg_params, "__xml_attributes = nothing")
    push!(kwarg_params, "__validated::Bool = true")
    push!(kwarg_args, "__xml_attributes")
    push!(kwarg_args, "__validated")

    ctor = """
    function $struct_name($(join(positional_params, ", ")))
        return $struct_name(nothing, $(join(converted_args, ", ")))
    end

    function $struct_name(; $(join(kwarg_params, ", ")))
        return $struct_name($(join(kwarg_args, ", ")))
    end
    """
    write(xsd_module_builder, IOStruct, ctor, indent_level = indent_level)
    return write(xsd_module_builder, IOStruct, "\n")
end

"""
    write_lazy_field_accessors(xsd_module_builder, xsd_node, all_fields, indent_level)

Emit one `_init_<field>(o::StructName)` function per data field. Three cases per field:

1. Built-in scalar type (`julia_type in values(built_in_data_type_dict)`) - parse the child node's
   text content directly via the existing `XmlStructLoader.parse_xml_node_not_module`, reusing 100%
   of the eager path's scalar conversion logic (Number/String/DateTime/ZonedDateTime/Date/Time),
   zero duplication.
2. A field whose type is itself a lazy-capable complex node (registered in `defined_nodes`, no
   choice fields) - recurse via that type's own node-based constructor, `FieldType(child)`. Still
   lazy all the way down: nothing under it is touched until its own fields are accessed.
3. Everything else (a restricted "simple type", a choice-bearing complex type, or any type not yet
   resolvable in `defined_nodes` at this point in codegen) - fall back to the *existing* eager
   construction function, `XmlStructLoader.construct_xml_node_object`, confined to just this one
   subtree. There is no meaningful sub-laziness to gain inside a single-value simple type or an
   already-eager choice type, so reusing the proven eager code here (rather than reimplementing
   attribute/restriction/default handling a second time) is a deliberate, lower-risk choice.

Vector fields apply the same three-way dispatch per matched child element.
"""
function write_lazy_field_accessors(
    xsd_module_builder::XSDStructModuleBuilderType,
    xsd_node::ComplexTreeNode,
    all_fields::Vector{<:AbstractFieldData},
    indent_level::Int,
)::Nothing
    struct_name = name(xsd_node)

    for field in all_fields
        field isa GroupFieldData && continue

        full_field_type = qualified_type(field)
        element_name = field.name
        is_scalar = field.julia_type in values(built_in_data_type_dict)
        lazy_capable_child = !is_scalar && is_lazy_capable_field_type(field, xsd_module_builder)

        default_value_string =
            isnothing(field.base_default_value) ? "nothing" :
            (field.julia_type == "String" ? "\"$(field.base_default_value)\"" : field.base_default_value)

        body = if field.is_vector
            generate_vector_accessor_body(element_name, full_field_type, is_scalar, lazy_capable_child)
        else
            generate_scalar_or_node_accessor_body(
                element_name,
                full_field_type,
                field.can_be_missing,
                is_scalar,
                lazy_capable_child,
                default_value_string,
            )
        end

        accessor = """
        function _init_$(field.name)(o::$struct_name)
        $body
        end
        """
        write(xsd_module_builder, IOStruct, accessor, indent_level = indent_level)
        writeln(xsd_module_builder, IOStruct)
    end

    return nothing
end

"""
    is_lazy_capable_field_type(field::AbstractFieldData, xsd_module_builder)::Bool

Whether `field`'s type resolves to a `ComplexTreeNode` already registered in `defined_nodes` with
no choice fields (see `is_lazy_capable`). Simple types, choice-bearing complex types, and
not-yet-defined/unresolvable types (unions, extensions) all return `false`, routing the field to
the eager-construction fallback instead.
"""
function is_lazy_capable_field_type(field::AbstractFieldData, xsd_module_builder::XSDStructModuleBuilderType)::Bool
    idx = findfirst(==(qualified_type(field)) ∘ qualified_name, xsd_module_builder.defined_nodes)
    isnothing(idx) && return false
    node = xsd_module_builder.defined_nodes[idx]
    return node isa ComplexTreeNode && is_lazy_capable(node)
end

function generate_scalar_or_node_accessor_body(
    element_name::AbstractString,
    full_field_type::AbstractString,
    can_be_missing::Bool,
    is_scalar::Bool,
    lazy_capable_child::Bool,
    default_value_string::AbstractString,
)::String
    lines = String[]
    push!(lines, "    child = XmlStructLoader.lazy_child_with_name(o._node, \"$element_name\", $can_be_missing)")
    push!(lines, "    isnothing(child) && return nothing")
    if is_scalar
        # child.ptr is a raw Ptr{Cvoid} - GC.@preserve is required around any call that touches it,
        # exactly like every helper in lazy_xml_node.jl does internally (Task 1). This is the one
        # place in codegen where a raw pointer briefly leaves that file's own helpers, because
        # parse_xml_node_not_module/construct_xml_node_object (the reused eager-path functions) take
        # a bare Ptr{Cvoid}, not a LazyNode. GC.@preserve requires a bare variable, not a `child.owner`
        # field-access expression, hence binding `owner` first.
        push!(lines, "    owner = child.owner")
        push!(
            lines,
            "    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, $full_field_type, @__MODULE__, false, $default_value_string)",
        )
    elseif lazy_capable_child
        push!(lines, "    return $full_field_type(child)")
    else
        push!(lines, "    owner = child.owner")
        push!(
            lines,
            "    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, $full_field_type, nothing), @__MODULE__, false)",
        )
    end
    return join(lines, "\n")
end

function generate_vector_accessor_body(
    element_name::AbstractString,
    full_field_type::AbstractString,
    is_scalar::Bool,
    lazy_capable_child::Bool,
)::String
    # Same GC.@preserve requirement as the scalar/non-vector case above - child.ptr must never be
    # touched without it. GC.@preserve needs a bare variable, so each element wraps its own
    # `owner = child.owner` binding in a `let` (a comprehension body is a single expression).
    element_expr = if is_scalar
        "(let owner = child.owner; GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, $full_field_type, @__MODULE__, false, nothing); end)"
    elseif lazy_capable_child
        "$full_field_type(child)"
    else
        "(let owner = child.owner; GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, $full_field_type, nothing), @__MODULE__, false); end)"
    end
    return "    return [$element_expr for child in XmlStructLoader.lazy_children_with_name(o._node, \"$element_name\")]"
end

function write_node_with_choice(
    xsd_node::ComplexTreeNode,
    choice_fields::Vector{ChoiceFieldData},
    xsd_module_builder::XSDStructModuleBuilderType,
    indent_level::Int,
)::Nothing
    @debug "writing with choice fields"

    field_strings = Vector{String}()

    writeln(
        xsd_module_builder,
        IOStruct,
        struct_line_string(name(xsd_node), "$ABSTRACT_TYPE_PACKAGE.AbstractXSDComplex", kwdef = false),
    )

    all_fields = get_all_fields(xsd_node)
    for field in all_fields
        field_string = generate_field_string(field)
        push!(field_strings, field_string)

        no_default_field_string = split(field_string, "=") |> first |> strip # remove default values
        writeln(xsd_module_builder, IOStruct, no_default_field_string, indent_level = indent_level + 1)
    end

    writeln(
        xsd_module_builder,
        IOStruct,
        "__xml_attributes::Union{Nothing, Dict{String, String}}";
        indent_level = indent_level + 1,
    )
    writeln(xsd_module_builder, IOStruct, "__validated::Bool"; indent_level = indent_level + 1)

    write(xsd_module_builder, IOStruct, "end\n\n", indent_level = indent_level)
    write_defaults_function(xsd_module_builder, name(xsd_node), all_fields, indent_level = indent_level)
    push!(xsd_module_builder.defined_nodes, xsd_node)

    # Write additional method overrides for choice fields
    write_choice_outer_constructor(xsd_node, field_strings, choice_fields, xsd_module_builder, indent_level)
    writeln(xsd_module_builder, IOStruct)
    write_choice_properties(name(xsd_node), all_fields, choice_fields, xsd_module_builder, indent_level)

    return nothing
end

function write_choice_outer_constructor(
    xsd_node::ComplexTreeNode,
    field_strings::Vector{String},
    choice_fields::Vector{ChoiceFieldData},
    xsd_module_builder::XSDStructModuleBuilderType,
    indent_level::Int,
)::Nothing

    # print function signature
    writeln(xsd_module_builder, IOStruct, "function $(name(xsd_node))(;", indent_level = indent_level)
    write(
        xsd_module_builder,
        IOStruct,
        join(inner_constructor_arguments(get_all_fields(xsd_node), field_strings), ",\n"),
        indent_level = indent_level + 1,
    )
    writeln(xsd_module_builder, IOStruct, ")", indent_level = indent_level)

    writeln(xsd_module_builder, IOStruct)

    # print checks for choice fields
    write_choice_checks(choice_fields, xsd_module_builder, indent_level)

    # print new call
    writeln(xsd_module_builder, IOStruct, "else", indent_level = indent_level + 1)

    constructor_arguments = constructor_arguments_string(get_all_fields(xsd_node))
    writeln(xsd_module_builder, IOStruct, "$(name(xsd_node))($constructor_arguments)", indent_level = indent_level + 2)

    writeln(xsd_module_builder, IOStruct, "end", indent_level = indent_level + 1)

    writeln(xsd_module_builder, IOStruct, "end", indent_level = indent_level)

    return
end

function inner_constructor_arguments(fields::Vector{AbstractFieldData}, field_strings::Vector{String})::Vector{String}
    string_vector = String[]
    for (field, field_string) in zip(fields, field_strings)
        if field isa ChoiceFieldData
            matches = eachmatch(r"(Union{[\w.]+, Nothing})+", field_string)
            for (sub_field, sub_field_match) in zip(field.choice_options, matches)
                print_string = "$(sub_field.name)::"
                print_string *= first(sub_field_match.captures)
                print_string *= "=nothing"

                push!(string_vector, print_string)
            end
        else
            push!(string_vector, field_string)
        end
    end

    # add extra __xml_attributes
    push!(string_vector, "__xml_attributes::Union{Nothing, Dict{<:AbstractString, <:AbstractString}} = nothing")

    # add extra __validated
    push!(string_vector, "__validated::Bool = true")

    return string_vector
end

function write_choice_checks(
    choice_fields::Vector{ChoiceFieldData},
    xsd_module_builder::XSDStructModuleBuilderType,
    indent_level::Int,
)::Nothing
    choice_fields_copy = deepcopy(choice_fields)
    choice_field = popfirst!(choice_fields_copy)
    choice_names = [choice.name for choice in choice_field.choice_options]

    writeln(
        xsd_module_builder,
        IOStruct,
        "if count(!isnothing, [$(join(choice_names, ", "))]) > 1",
        indent_level = indent_level + 1,
    )
    writeln(
        xsd_module_builder,
        IOStruct,
        "error(\"Only one of $(join(choice_names, " or ")) can be not nothing\")",
        indent_level = indent_level + 2,
    )

    while !isempty(choice_fields_copy)
        choice_field = popfirst!(choice_fields_copy)
        choice_names = [choice.name for choice in choice_field.choice_options]

        writeln(
            xsd_module_builder,
            IOStruct,
            "elseif count(!isnothing, [$(join(choice_names, ", "))]) > 1",
            indent_level = indent_level + 1,
        )

        writeln(
            xsd_module_builder,
            IOStruct,
            "error(\"Only one of $(join(choice_names, " or ")) can be not nothing\")",
            indent_level = indent_level + 2,
        )
    end

    return nothing
end

function constructor_arguments_string(fields::Vector{AbstractFieldData})::String
    call_arguments = String[]

    for field in fields
        if field isa ChoiceFieldData
            named_tuple_arguments = String[]
            for choice in field.choice_options
                push!(named_tuple_arguments, choice.name)
            end
            push!(call_arguments, "($(join(["$arg=$arg" for arg in named_tuple_arguments], ", ")))")
        else
            push!(call_arguments, field.name)
        end
    end

    # add extra __xml_attributes
    push!(call_arguments, "__xml_attributes")

    # add extra __validated
    push!(call_arguments, "__validated")

    return join(call_arguments, ", ")
end

function write_choice_properties(
    parent_name::AbstractString,
    all_fields::Vector{<:AbstractFieldData},
    choice_fields::Vector{ChoiceFieldData},
    xsd_module_builder::XSDStructModuleBuilderType,
    indent_level::Int,
)
    # Build the property list in true document order: a plain field contributes its own name, a
    # choice field is expanded in-place into its options' names - not filtered out then appended
    # at the end, which would silently reorder every field that followed a choice in the schema.
    full_field_names_list = String[]
    for field in all_fields
        if field isa ChoiceFieldData
            for choice in field.choice_options
                push!(full_field_names_list, ":" * choice.name)
            end
        else
            push!(full_field_names_list, ":" * field.name)
        end
    end
    push!(full_field_names_list, ":__xml_attributes")
    push!(full_field_names_list, ":__validated")

    writeln(
        xsd_module_builder,
        IOStruct,
        "Base.propertynames(x::$parent_name, private::Bool=false) = ($(join(full_field_names_list, ", ")),)",
        indent_level = indent_level,
    )

    choice_fields_tmp = deepcopy(choice_fields)

    # start function
    writeln(
        xsd_module_builder,
        IOStruct,
        "function Base.getproperty(x::$parent_name, s::Symbol)",
        indent_level = indent_level,
    )

    # write first case
    current_field = popfirst!(choice_fields_tmp)
    current_field_choices = join([":" * field.name for field in current_field.choice_options], ", ")

    writeln(xsd_module_builder, IOStruct, "if s in [$current_field_choices]", indent_level = indent_level + 1)
    writeln(
        xsd_module_builder,
        IOStruct,
        "return getfield(getfield(x, Symbol(\"$(current_field.name)\")), s)",
        indent_level = indent_level + 2,
    )

    # write remaining cases
    while !isempty(choice_fields_tmp)
        current_field = popfirst!(choice_fields_tmp)
        current_field_choices = join([":" * field.name for field in current_field.choice_options], ", ")

        writeln(xsd_module_builder, IOStruct, "elseif s in [$current_field_choices]", indent_level = indent_level + 1)

        writeln(
            xsd_module_builder,
            IOStruct,
            "return getfield(getfield(x, Symbol(\"$(current_field.name)\")), s)",
            indent_level = indent_level + 2,
        )
    end

    # write fallback
    writeln(xsd_module_builder, IOStruct, "else", indent_level = indent_level + 1)

    writeln(xsd_module_builder, IOStruct, "return getfield(x, s)", indent_level = indent_level + 2)

    writeln(xsd_module_builder, IOStruct, "end", indent_level = indent_level + 1)

    # close function
    write(xsd_module_builder, IOStruct, "end", indent_level = indent_level)

    return write(xsd_module_builder, IOStruct, "\n\n")
end

# TODO: Change this to a version for FieldData and one for ChoiceFieldData!!!
function generate_field_string(field_data::AbstractFieldData)::String
    full_field_type = qualified_type(field_data)

    # handle Vector types
    if field_data.is_vector
        full_field_type = "Vector{$(full_field_type)}"
    end

    # handle minOccurs=0
    if field_data.can_be_missing
        full_field_type = "Union{Nothing, $(full_field_type)}"
        field_string = "$(field_data.name)::$(full_field_type) = nothing"
    else
        field_string = "$(field_data.name)::$(full_field_type)"
    end

    return field_string
end

function generate_defaults_string(
    field_data::AbstractFieldData,
    xsd_module_builder::XSDStructModuleBuilderType,
)::Union{Nothing,String}
    full_field_type = qualified_type(field_data)

    # handle default values
    default_value = field_data.base_default_value

    if !isnothing(default_value)
        # special case if julia_type is a String or based on a String since in this case we need extra "" marks
        if field_data.julia_type == "String" || is_based_on_string(field_data, xsd_module_builder)
            default_value = "\"$(default_value)\""
        end

        # wrap default value with appropriate constructor
        if field_data.julia_type == "Union{ZonedDateTime, DateTime}"
            defaults_value = construct_time_default_value(default_value)
        else
            defaults_value = "$(full_field_type)($(default_value))"
        end
        defaults_string = "$(field_data.name) = $defaults_value"
    else
        defaults_string = nothing
    end

    return defaults_string
end

# Regex inspired by section 3.2.7.3 Timezones of
# https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/datatypes.html#dateTime
const timezone_regex = r"((\+|-)\d\d:\d\d)|Z"
function construct_time_default_value(default_value::AbstractString)::String
    timezone_match = match(timezone_regex, default_value)
    is_not_timezone_string = isnothing(timezone_match)
    return if is_not_timezone_string
        defaults_value = "DateTime(\"$default_value\")"
    else
        defaults_value = "ZonedDateTime(\"$default_value\", \"yyyy-mm-ddTHH:MM:SSzzzzzz\")"
    end
end

function write_defaults_function(
    xsd_module_builder::XSDStructModuleBuilderType,
    struct_name::AbstractString,
    all_fields::Vector{AbstractFieldData};
    indent_level::Int,
)::Nothing
    function_signature = "AbstractXsdTypes.defaults(::Type{$struct_name})"

    default_strings = String[]

    for field_data in all_fields
        if !isnothing(field_data.base_default_value)
            field_string = generate_defaults_string(field_data, xsd_module_builder)
            isnothing(field_string) || push!(default_strings, field_string)
        end
    end

    if !isempty(default_strings)
        defaults_named_tuple = "(" * join(default_strings, ", ") * ", )"  # trailing , to ensure NamedTuple
        function_string = function_signature * " = " * defaults_named_tuple

        @debug "Writing defaults function: $function_string"
        writeln(xsd_module_builder, IOStruct, function_string, indent_level = indent_level)
        write(xsd_module_builder, IOStruct, "\n", indent_level = indent_level)
    end

    return nothing
end

function write_node_specific(
    xsd_node::ExtensionTreeNode,
    xsd_module_builder::XSDStructModuleBuilderType,
    indent_level::Int = 1,
)::Bool
    @debug "Writing as $(ExtensionTreeNode)"

    xsd_own_node = xsd_node.node_content

    # First write submodule child types for own content
    undefined_child_nodes = filter(
        child_node -> qualified_name(child_node) ∉ defined_node_names(xsd_module_builder),
        xsd_own_node.child_nodes,
    )

    if !isempty(undefined_child_nodes)
        write_child_submodule(
            sub_module_name(name(xsd_node)),
            undefined_child_nodes,
            xsd_module_builder,
            indent_level = indent_level,
        )
    end

    # construct temporary complex node and use this node to write the struct definition
    combined_fields = [xsd_node.base_fields; xsd_node.base_child_fields; get_all_fields(xsd_own_node)]
    combined_children = [xsd_node.base_children; xsd_own_node.child_nodes]
    combined_order = [xsd_node.base_field_ordering; xsd_own_node.field_ordering]

    tmp_node = ComplexTreeNode(
        common_data = xsd_node.common_data,
        fields = combined_fields,
        child_nodes = combined_children,
        field_ordering = combined_order,
    )

    choice_fields = get_all_fields_of_type(tmp_node, ChoiceFieldData)

    if isempty(choice_fields)
        # write_node_no_choice writes its own docstring, placed after the @lazy struct block.
        write_node_no_choice(tmp_node, xsd_module_builder, indent_level)
    else
        write_docstring(tmp_node, xsd_module_builder, indent_level)
        write_node_with_choice(tmp_node, choice_fields, xsd_module_builder, indent_level)
    end

    return true
end

function write_node(
    xsd_node::AbstractTreeNode,
    xsd_module_builder::XSDStructModuleBuilderType;
    export_line::Bool = true,
    indent_level::Int = 0,
)::Nothing

    # nothing to do if already defined
    if qualified_name(xsd_node) in defined_node_names(xsd_module_builder)
        return nothing
    end

    if check_node_ready(xsd_node, xsd_module_builder)
        @debug "Begin writing struct $(name(xsd_node))"

        write_node_specific(xsd_node, xsd_module_builder, indent_level)

        if export_line
            write_export(xsd_node, xsd_module_builder, indent_level)
        end

        @debug "Finished writing struct $(name(xsd_node))"
    else
        @debug "Skipping node $xsd_node"

        push!(xsd_module_builder.skipped_nodes, xsd_node)
    end

    return nothing
end

function write_export(xsd_node::AbstractTreeNode, xsd_module_builder::XSDStructModuleBuilderType, indent_level::Int = 0)
    writeln(xsd_module_builder, IOStruct, "export $(name(xsd_node))", indent_level = indent_level)
    return write(xsd_module_builder, IOStruct, "\n")
end

function write_docstring(
    xsd_node::AbstractTreeNode,
    xsd_module_builder::XSDStructModuleBuilderType,
    indent_level::Int,
)::Nothing
    docstring = xsd_docstring(xsd_node)
    if !isnothing(docstring)
        writeln(xsd_module_builder, IOStruct, "\"\"\"", indent_level = indent_level)
        writeln(xsd_module_builder, IOStruct, docstring, indent_level = indent_level)
        writeln(xsd_module_builder, IOStruct, "\"\"\"", indent_level = indent_level)
    end

    return nothing
end
