# Phase 2 spike: XmlStructLoader.load's algorithm re-hosted on the pugixml C shim
# (bench/pugixml_shim/) instead of EzXML. Same design as bench/prototype_xmljl/loader_xmljl.jl -
# xml_parser_in_module.jl / xml_parser_not_module.jl included unmodified, only the small
# abstraction surface is backend-specific. See that file's header comment for the full rationale;
# this one only notes what differs for pugixml.
#
# pugixml's node/attribute handles are raw pointers (Ptr{Cvoid}) into the document's own memory
# pool - unlike XML.jl's Node, pugixml DOES expose parent/next-sibling-element traversal natively
# via ccall (pugishim doesn't currently expose a "parent" accessor, but next-sibling-element is
# free), so the wrapper design here is lighter than XML.jl's: only a raw-node -> raw-parent map is
# needed (same as XML.jl needed for `AbstractTrees.parent` on a raw node), no separate
# children-list/sibling-index cache, since pugixml's own C++ linked list makes next-sibling O(1)
# without needing Julia-side precomputation.

module PugixmlLoaderProto

using AbstractTrees
using AbstractTrees: parent, isroot
using AbstractXsdTypes
using Dates, TimeZones, Parsers

const HERE = @__DIR__
const LIB = joinpath(HERE, "..", "pugixml_shim", "libpugixml_shim.so")

const UnifiedXMLElement = Ptr{Cvoid}  # pugixml node handle

# --- abstraction surface (backend-specific) ---

# pugishim_node_name doesn't strip namespace prefixes (pugixml treats "Foo:bar" as a literal
# name) - same fix as the XML.jl prototype: check for ':' first, only split in the rare case.
function name(node::Ptr{Cvoid})::String
    raw = unsafe_string(ccall((:pugishim_node_name, LIB), Cstring, (Ptr{Cvoid},), node))
    idx = findlast(==(':'), raw)
    return isnothing(idx) ? raw : raw[(idx + 1):end]
end

function content(node::Ptr{Cvoid})::String
    return strip(unsafe_string(ccall((:pugishim_node_text, LIB), Cstring, (Ptr{Cvoid},), node)))
end
get_node_content(node::Ptr{Cvoid})::String = content(node)

haschildren(node::Ptr{Cvoid})::Bool = ccall((:pugishim_has_element_children, LIB), Cint, (Ptr{Cvoid},), node) != 0

first_child_element(node::Ptr{Cvoid})::Ptr{Cvoid} =
    ccall((:pugishim_first_child_element, LIB), Ptr{Cvoid}, (Ptr{Cvoid},), node)
next_sibling_element(node::Ptr{Cvoid})::Ptr{Cvoid} =
    ccall((:pugishim_next_sibling_element, LIB), Ptr{Cvoid}, (Ptr{Cvoid},), node)

function element_children(node::Ptr{Cvoid})
    result = Ptr{Cvoid}[]
    c = first_child_element(node)
    while c != C_NULL
        push!(result, c)
        c = next_sibling_element(c)
    end
    return result
end

function getattributes_dict(node::Ptr{Cvoid})::Dict{String,String}
    dct = Dict{String,String}()
    attr = ccall((:pugishim_first_attribute, LIB), Ptr{Cvoid}, (Ptr{Cvoid},), node)
    while attr != C_NULL
        k = unsafe_string(ccall((:pugishim_attribute_name, LIB), Cstring, (Ptr{Cvoid},), attr))
        v = unsafe_string(ccall((:pugishim_attribute_value, LIB), Cstring, (Ptr{Cvoid},), attr))
        dct[k] = v
        attr = ccall((:pugishim_next_attribute, LIB), Ptr{Cvoid}, (Ptr{Cvoid},), attr)
    end
    return dct
end

function docroot(doc_handle::Ptr{Cvoid})::Ptr{Cvoid}
    return ccall((:pugishim_root, LIB), Ptr{Cvoid}, (Ptr{Cvoid},), doc_handle)
end

function readxmlfile(f::Function, filename::AbstractString)
    @debug "Loading with pugixml..."
    doc = ccall((:pugishim_parse_file, LIB), Ptr{Cvoid}, (Cstring,), filename)
    doc == C_NULL && error("pugixml failed to parse $filename")
    try
        return f(doc)
    finally
        ccall((:pugishim_free_doc, LIB), Cvoid, (Ptr{Cvoid},), doc)
    end
end

mutable struct XmlStructLoaderNode{XML_T<:UnifiedXMLElement,T<:Union{DataType,Union}}
    node::XML_T
    type::T
    parent::Union{Nothing,XmlStructLoaderNode{XML_T}}
    children::Vector{XmlStructLoaderNode{XML_T}}
    next_sibling::Union{Nothing,XmlStructLoaderNode{XML_T}}
end

const _raw_parent_map = IdDict{Ptr{Cvoid},Ptr{Cvoid}}()
AbstractTrees.parent(node::Ptr{Cvoid}) = _raw_parent_map[node]

const EMPTY_CHILDREN = XmlStructLoaderNode{Ptr{Cvoid}}[]

function _build_node_tree(raw::Ptr{Cvoid}, type::T, parent::Union{Nothing,XmlStructLoaderNode{Ptr{Cvoid}}}) where {T}
    self = XmlStructLoaderNode{Ptr{Cvoid},T}(raw, type, parent, EMPTY_CHILDREN, nothing)
    kids_raw = element_children(raw)
    isempty(kids_raw) && return self
    kids = Vector{XmlStructLoaderNode{Ptr{Cvoid}}}(undef, length(kids_raw))
    for (i, craw) in enumerate(kids_raw)
        _raw_parent_map[craw] = raw
        ctype = get_base_field_type(type, tag_symbol(name(craw)))
        kids[i] = _build_node_tree(craw, ctype, self)
    end
    self.children = kids
    for i in 1:(length(kids) - 1)
        kids[i].next_sibling = kids[i + 1]
    end
    return self
end

XmlStructLoaderNode(node::Ptr{Cvoid}, type, ::Nothing) = _build_node_tree(node, type, nothing)
XmlStructLoaderNode(node::Ptr{Cvoid}, type, parent::XmlStructLoaderNode) =
    XmlStructLoaderNode(node, type, parent, EMPTY_CHILDREN, nothing)

AbstractTrees.parent(node::XmlStructLoaderNode) = isnothing(node.parent) ? node.node : node.parent
AbstractTrees.isroot(node::XmlStructLoaderNode) = isnothing(node.parent)
AbstractTrees.children(node::XmlStructLoaderNode) = node.children

Base.IteratorEltype(::Type{<:AbstractTrees.TreeIterator{<:XmlStructLoaderNode}}) = Base.HasEltype()
Base.eltype(::Type{<:AbstractTrees.TreeIterator{T}}) where {T<:XmlStructLoaderNode} = T
AbstractTrees.ParentLinks(::Type{<:XmlStructLoaderNode}) = AbstractTrees.ImplicitParents()
AbstractTrees.SiblingLinks(::Type{<:XmlStructLoaderNode}) = AbstractTrees.StoredSiblings()
AbstractTrees.nextsibling(node::XmlStructLoaderNode) = node.next_sibling

function _get_default(@nospecialize(ParentType::Type), child::Ptr{Cvoid})
    defaults = AbstractXsdTypes.defaults(ParentType)
    return get(defaults, tag_symbol(name(child)), nothing)
end
get_default(node::XmlStructLoaderNode) = _get_default(node.parent.type, node.node)

# --- type-info helpers (identical to the XML.jl prototype - pure Julia reflection) ---

function type_in_module(@nospecialize(T::Type), module_ref::Module)::Bool
    m = parentmodule(T)
    while true
        m === module_ref && return true
        parent = parentmodule(m)
        parent === m && return false
        m = parent
    end
end
type_in_module(::Type{T}, ::Module) where {T<:Dates.AbstractTime} = false

function get_base_field_type(@nospecialize(T::Type), field_index::Int)::DataType
    field_type = fieldtype(T, field_index)
    if typeof(field_type) == Union
        field_type = first(filter(a -> a != Nothing, Base.uniontypes(field_type)))
    end
    return field_type
end

const field_type_cache = Dict{Tuple{DataType,Symbol},DataType}()
get_type_from_symbol(type_symbol::Tuple{DataType,Symbol}) = get(field_type_cache, type_symbol, Nothing)

function get_base_field_type(@nospecialize(T::Type), field_symbol::Symbol)
    field_type = get_type_from_symbol((T, field_symbol))
    if field_type == Nothing
        if isprimitivetype(T)
            field_type = T
        elseif hasfield(T, field_symbol)
            field_type = fieldtype(T, field_symbol)
        elseif T <: AbstractVector
            field_type = fieldtype(eltype(T), field_symbol)
        else
            named_tuples = filter(field_type -> field_type <: NamedTuple, fieldtypes(T))
            matching_named_tuple = first(filter(named_tuple -> hasfield(named_tuple, field_symbol), named_tuples))
            field_type = fieldtype(matching_named_tuple, field_symbol)
        end
        if typeof(field_type) == Union
            field_type = first(filter(a -> a !== Nothing, Base.uniontypes(field_type)))
        end
        field_type_cache[(T, field_symbol)] = field_type
    end
    return field_type
end

const tag_symbol_cache = Dict{String,Symbol}()
tag_symbol(tag_name::AbstractString)::Symbol = get!(() -> Symbol(tag_name), tag_symbol_cache, tag_name)

# --- the actual production algorithm (backend-agnostic) ---

include(joinpath(@__DIR__, "..", "..", "src", "xml_parser", "xml_parser_in_module.jl"))
include(joinpath(@__DIR__, "..", "..", "src", "xml_parser", "xml_parser_not_module.jl"))

function construct_xml_node_object(node::XmlStructLoaderNode, module_ref::Module, validate::Bool)
    if type_in_module(node.type, module_ref)
        return parse_xml_node_in_module(node, module_ref, validate)
    elseif node.type <: AbstractVector
        return _parse_xml_node_not_module(node, module_ref, validate)
    else
        return parse_xml_node_not_module(node.node, node.type, module_ref, validate, get_default(node))
    end
end

function construct_xml_root_object(xml_root::Ptr{Cvoid}, module_ref::Module, validate::Bool)
    root_type = module_ref.__meta.root_type
    root_attributes = getattributes_dict(xml_root)
    root_attributes["__root_name"] = name(xml_root)

    empty!(_raw_parent_map)
    child_object_dict = construct_xml_node_child_objects(xml_root, module_ref, validate)
    merge!(child_object_dict, Dict(:__xml_attributes => root_attributes, :__validated => validate))
    return root_type(; child_object_dict...)
end

function construct_xml_object(xml_path::AbstractString, module_ref::Module; validate::Bool = true)
    return readxmlfile(xml_path) do doc
        root = docroot(doc)
        return construct_xml_root_object(root, module_ref, validate)
    end
end

load(xml_path::AbstractString, module_ref::Module; validate::Bool = true) =
    Base.@invokelatest construct_xml_object(xml_path, module_ref; validate = validate)

end # module
