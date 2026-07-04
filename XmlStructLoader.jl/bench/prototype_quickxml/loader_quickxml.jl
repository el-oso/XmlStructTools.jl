# Phase 2 spike: XmlStructLoader.load's algorithm re-hosted on the quick-xml Rust shim
# (bench/quickxml_shim/) instead of EzXML. Same design as the XML.jl/pugixml prototypes - see
# bench/prototype_xmljl/loader_xmljl.jl's header comment for the full rationale.
#
# quick-xml's shim is arena/index-based (a document handle + int32 node indices), not
# pointer-based like pugixml's - a "node" here is really (doc, index) together, so the raw
# element type is a small immutable struct wrapping both rather than a bare Ptr/handle. Like
# XML.jl, this backend has no native parent/sibling tracking, so the same precomputed-tree-with-
# real-struct-fields pattern is used (not a dict lookup per traversal step) from the start.

module QuickxmlLoaderProto

using AbstractTrees
using AbstractTrees: parent, isroot
using AbstractXsdTypes
using Dates, TimeZones, Parsers

const HERE = @__DIR__
const LIB = joinpath(HERE, "..", "quickxml_shim", "target", "release", "libquickxml_shim.so")

struct QxNode
    doc::Ptr{Cvoid}
    idx::Int32
end
Base.:(==)(a::QxNode, b::QxNode) = a.doc == b.doc && a.idx == b.idx

const UnifiedXMLElement = QxNode

# --- abstraction surface (backend-specific) ---

function name(node::QxNode)::String
    raw = unsafe_string(ccall((:quickxml_tag_name, LIB), Cstring, (Ptr{Cvoid}, Int32), node.doc, node.idx))
    idx = findlast(==(':'), raw)
    return isnothing(idx) ? raw : raw[(idx + 1):end]
end

function content(node::QxNode)::String
    ptr = ccall((:quickxml_text, LIB), Cstring, (Ptr{Cvoid}, Int32), node.doc, node.idx)
    return ptr == C_NULL ? "" : strip(unsafe_string(ptr))
end
get_node_content(node::QxNode)::String = content(node)

haschildren(node::QxNode)::Bool =
    ccall((:quickxml_has_element_children, LIB), Int32, (Ptr{Cvoid}, Int32), node.doc, node.idx) != 0

function element_children(node::QxNode)
    n = ccall((:quickxml_child_count, LIB), Int32, (Ptr{Cvoid}, Int32), node.doc, node.idx)
    result = Vector{QxNode}(undef, n)
    for i in 0:(n - 1)
        cidx = ccall((:quickxml_child_at, LIB), Int32, (Ptr{Cvoid}, Int32, Int32), node.doc, node.idx, i)
        result[i + 1] = QxNode(node.doc, cidx)
    end
    return result
end

function getattributes_dict(node::QxNode)::Dict{String,String}
    n = ccall((:quickxml_attr_count, LIB), Int32, (Ptr{Cvoid}, Int32), node.doc, node.idx)
    dct = Dict{String,String}()
    for i in 0:(n - 1)
        k = unsafe_string(ccall((:quickxml_attr_name, LIB), Cstring, (Ptr{Cvoid}, Int32, Int32), node.doc, node.idx, i))
        v =
            unsafe_string(ccall((:quickxml_attr_value, LIB), Cstring, (Ptr{Cvoid}, Int32, Int32), node.doc, node.idx, i))
        dct[k] = v
    end
    return dct
end

function docroot(doc::Ptr{Cvoid})::QxNode
    idx = ccall((:quickxml_root, LIB), Int32, (Ptr{Cvoid},), doc)
    idx < 0 && error("quick-xml: no root element")
    return QxNode(doc, idx)
end

function readxmlfile(f::Function, filename::AbstractString)
    @debug "Loading with quick-xml..."
    doc = ccall((:quickxml_parse_file, LIB), Ptr{Cvoid}, (Cstring,), filename)
    doc == C_NULL && error("quick-xml failed to parse $filename")
    try
        return f(doc)
    finally
        ccall((:quickxml_free, LIB), Cvoid, (Ptr{Cvoid},), doc)
    end
end

mutable struct XmlStructLoaderNode{XML_T<:UnifiedXMLElement,T<:Union{DataType,Union}}
    node::XML_T
    type::T
    parent::Union{Nothing,XmlStructLoaderNode{XML_T}}
    children::Vector{XmlStructLoaderNode{XML_T}}
    next_sibling::Union{Nothing,XmlStructLoaderNode{XML_T}}
end

const _raw_parent_map = IdDict{QxNode,QxNode}()
AbstractTrees.parent(node::QxNode) = _raw_parent_map[node]

const EMPTY_CHILDREN = XmlStructLoaderNode{QxNode}[]

function _build_node_tree(raw::QxNode, type::T, parent::Union{Nothing,XmlStructLoaderNode{QxNode}}) where {T}
    self = XmlStructLoaderNode{QxNode,T}(raw, type, parent, EMPTY_CHILDREN, nothing)
    kids_raw = element_children(raw)
    isempty(kids_raw) && return self
    kids = Vector{XmlStructLoaderNode{QxNode}}(undef, length(kids_raw))
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

XmlStructLoaderNode(node::QxNode, type, ::Nothing) = _build_node_tree(node, type, nothing)
XmlStructLoaderNode(node::QxNode, type, parent::XmlStructLoaderNode) =
    XmlStructLoaderNode(node, type, parent, EMPTY_CHILDREN, nothing)

AbstractTrees.parent(node::XmlStructLoaderNode) = isnothing(node.parent) ? node.node : node.parent
AbstractTrees.isroot(node::XmlStructLoaderNode) = isnothing(node.parent)
AbstractTrees.children(node::XmlStructLoaderNode) = node.children

Base.IteratorEltype(::Type{<:AbstractTrees.TreeIterator{<:XmlStructLoaderNode}}) = Base.HasEltype()
Base.eltype(::Type{<:AbstractTrees.TreeIterator{T}}) where {T<:XmlStructLoaderNode} = T
AbstractTrees.ParentLinks(::Type{<:XmlStructLoaderNode}) = AbstractTrees.ImplicitParents()
AbstractTrees.SiblingLinks(::Type{<:XmlStructLoaderNode}) = AbstractTrees.StoredSiblings()
AbstractTrees.nextsibling(node::XmlStructLoaderNode) = node.next_sibling

function _get_default(@nospecialize(ParentType::Type), child::QxNode)
    defaults = AbstractXsdTypes.defaults(ParentType)
    return get(defaults, tag_symbol(name(child)), nothing)
end
get_default(node::XmlStructLoaderNode) = _get_default(node.parent.type, node.node)

# --- type-info helpers (identical to the other prototypes - pure Julia reflection) ---

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

function construct_xml_root_object(xml_root::QxNode, module_ref::Module, validate::Bool)
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
