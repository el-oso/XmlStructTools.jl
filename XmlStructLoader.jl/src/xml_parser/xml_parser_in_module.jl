"""
	_child_fields(T, raw, module_ref, validate)

The constructor arguments for one complex element of type `T`, as field names and their values in
matching order: every child element under its field name, with repeated elements of a
`Vector`-typed field accumulated in document order. Any other field that repeats appears twice in
`names`, which the keyword constructor rejects as a duplicate name.

Siblings are a loop and only nesting recurses, so the call depth is the document's nesting depth
and not its element count: a flat document with 120,000 sibling records descends one level.
"""
function _child_fields(
        @nospecialize(T::Type),
        @nospecialize(raw::UnifiedXMLElement),
        module_ref::Module,
        validate::Bool,
    )
    names = Symbol[]
    values = Any[]
    field_defaults = AbstractXsdTypes.defaults(T)
    renames = element_field_mapping(module_ref)
    child = XmlStructPugixml.first_child_element(raw)
    while child != C_NULL
        field_symbol = mapped_field_symbol(name_symbol(child), renames)
        field_type = get_base_field_type(T, field_symbol)
        default_value = get(field_defaults, field_symbol, nothing)

        # A byte vector is the decoded content of ONE element, not a field that repeats:
        # `xs:base64Binary` maps to `Vector{UInt8}`, which would otherwise look like a repeated
        # element and have each byte parsed from the whole base64 text.
        if field_type <: AbstractVector && !(field_type <: AbstractVector{UInt8})
            element = construct_element(eltype(field_type), child, default_value, module_ref, validate)
            index = findfirst(isequal(field_symbol), names)
            if isnothing(index)
                elements = field_type()
                push!(elements, element)
                push!(names, field_symbol)
                push!(values, elements)
            else
                push!(values[index], element)
            end
        else
            push!(names, field_symbol)
            push!(values, construct_element(field_type, child, default_value, module_ref, validate))
        end

        child = XmlStructPugixml.next_sibling_element(child)
    end
    return names, values
end

"""
	construct_from_fields(T, names, values, xml_attributes, validate)

Call the keyword constructor of `T` with the fields from [`_child_fields`](@ref).

The call goes through a builder compiled for `T` and the names present, from
[`keyword_builder`](@ref): a `NamedTuple` built from names known only at run time costs several
times more than the constructor itself.
"""
function construct_from_fields(@nospecialize(T::Type), names::Vector{Symbol}, values::Vector{Any}, xml_attributes, validate::Bool)
    push!(names, :__xml_attributes, :__validated)
    push!(values, xml_attributes, validate)
    return keyword_builder(T, names)(values)
end

# Each value is asserted to be of its field's type, so the `NamedTuple` and the keyword call are
# concrete. A keyword that is not a field, such as a choice member, stays `Any`.
@generated function build_with_keywords(::Type{T}, ::Val{N}, values::Vector{Any}) where {T, N}
    arguments = [:(values[$i]::$(N[i] in fieldnames(T) ? fieldtype(T, N[i]) : Any)) for i in eachindex(N)]
    return :(Core.kwcall(NamedTuple{$N}(($(arguments...),)), T))
end

const KEYWORD_BUILDERS = IdDict{Type, Vector{Pair{Vector{Symbol}, Function}}}()
const KEYWORD_BUILDERS_LOCK = ReentrantLock()

"""
	keyword_builder(T, names)

The function that calls the keyword constructor of `T` with the keywords `names`, given their
values as a `Vector{Any}` in the same order.

One builder is compiled per type and set of names and kept for the session. A precompile workload
that loads a document saves the code compiled for its builders with the package that ran it; a
set of names that the precompile sample does not contain is compiled when a document first
contains it.
"""
function keyword_builder(@nospecialize(T::Type), names::Vector{Symbol})::Function
    return lock(KEYWORD_BUILDERS_LOCK) do
        builders = get!(() -> Pair{Vector{Symbol}, Function}[], KEYWORD_BUILDERS, T)
        for (known_names, builder) in builders
            known_names == names && return builder
        end
        keyword_names = Val(Tuple(names))
        builder = values -> build_with_keywords(T, keyword_names, values)
        push!(builders, copy(names) => builder)
        return builder
    end
end

"""
	construct_element(::Type{T}, raw, default_value, module_ref, validate)

The object for the XML element `raw` at field type `T`, children first.

`T` is a static parameter rather than a struct field, which keeps everything below this call
specialized: the one dynamic call per element happens here, where the field type is only known
at run time.
"""
function construct_element(
        ::Type{T},
        @nospecialize(raw::UnifiedXMLElement),
        default_value,
        module_ref::Module,
        validate::Bool,
    ) where {T}
    if haschildren(raw)
        names, values = _child_fields(T, raw, module_ref, validate)
        return construct_from_fields(T, names, values, getattributes_dict(raw), validate)
    end

    type_in_module(T, module_ref) ||
        return parse_xml_node_not_module(raw, T, module_ref, validate, default_value)

    if isempty(content(raw))
        isnothing(default_value) || return T(value = default_value)
        # An empty element still produces an object for these: a string type gets the empty
        # string, a complex type its own defaults. Anything else has no value to carry.
        T <: AbstractXsdTypes.AbstractXSDString && return T(value = "")
        T <: AbstractXsdTypes.AbstractXSDComplex && return T()
        return nothing
    end

    # Simple content: `T` wraps one public field whose type parses the element's text, so the
    # same element is read again under that type.
    value = if T <: AbstractXsdTypes.AbstractXSDUnion
        construct_union_member(T, raw, default_value, module_ref, validate)
    else
        construct_element(get_base_field_type(T, 1), raw, default_value, module_ref, validate)
    end
    return T(value, getattributes_dict(raw), validate)
end

# XSD reads a union's text as the first of its member types that accepts it.
function construct_union_member(
        ::Type{T},
        @nospecialize(raw::UnifiedXMLElement),
        default_value,
        module_ref::Module,
        validate::Bool,
    ) where {T}
    failures = String[]
    for member in AbstractXsdTypes.union_types(T)
        try
            return construct_element(member, raw, default_value, module_ref, validate)
        catch e
            e isa InterruptException && rethrow()
            push!(failures, "  $member: " * first(split(sprint(showerror, e), '\n')))
        end
    end
    throw(ArgumentError("\"$(content(raw))\" is not a value of any member of the union $T:\n" * join(failures, "\n")))
end
