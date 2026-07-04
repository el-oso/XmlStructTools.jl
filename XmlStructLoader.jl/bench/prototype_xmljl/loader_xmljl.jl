# Phase 2 spike: XmlStructLoader.load's algorithm re-hosted on XML.jl instead of EzXML, for a
# head-to-head benchmark. NOT wired into the real package - a throwaway prototype per the plan
# (~/.claude/plans/dynamic-churning-abelson.md, Phase 2). If XML.jl wins the bake-off, this is
# promoted (Phase 3); if not, discarded.
#
# Design: xml_parser_in_module.jl and xml_parser_not_module.jl in the real package are already
# backend-agnostic (they call only the small abstraction surface - content/attributes/name/
# haschildren/AbstractTrees glue - never EzXML directly), so this file supplies that same
# abstraction surface for XML.Node instead, then re-runs the identical algorithm. The two real
# source files are `include`d unmodified below - this is the actual, exact production algorithm,
# not a reimplementation of it, which is what makes this a fair comparison.
#
# One thing changes structurally, not just the backend: XML.jl exposes root-element xmlns:*
# declarations as ordinary attributes (verified directly against XML.jl v0.4.0), unlike EzXML/
# LightXML which need `root_attributes_workaround`'s regex re-scan. So this prototype has no
# equivalent workaround at all - if XML.jl wins, that whole hack (xml_parser.jl:19-54) can be
# deleted in Phase 3.

module XmlJLLoaderProto

using XML
using AbstractTrees
using AbstractTrees: parent, isroot
using AbstractXsdTypes
using Dates, TimeZones, Parsers

const UnifiedXMLElement = XML.Node

# mutable + precomputed children/next_sibling: XML.jl's raw Node (unlike EzXML's) doesn't track
# its own parent or sibling position at the C-struct level, so those links have to live somewhere
# on the Julia side. An earlier version of this prototype used 3 separate IdDicts (parent map,
# children-list-per-parent, sibling-index-per-child) looked up on every AbstractTrees call during
# traversal - correct, but ~2x slower than the EzXML baseline on the 20,000-record large_synthetic
# fixture, because every parent/children/nextsibling call paid a hash lookup where EzXML pays a
# raw pointer dereference. Precomputing the whole wrapper tree ONCE (_build_node_tree, below) and
# storing parent/children/next_sibling as real struct fields turns every AbstractTrees call back
# into a field access, matching EzXML's zero-cost-lookup shape - the cost is paid once, up front,
# instead of once per traversal step.
mutable struct XmlStructLoaderNode{XML_T<:UnifiedXMLElement,T<:Union{DataType,Union}}
    node::XML_T
    type::T
    parent::Union{Nothing,XmlStructLoaderNode{XML_T}}
    children::Vector{XmlStructLoaderNode{XML_T}}
    next_sibling::Union{Nothing,XmlStructLoaderNode{XML_T}}
end

# --- abstraction surface (the part that's actually backend-specific) ---

# EzXML.nodename strips any namespace prefix (e.g. "TestFoo:document" -> "document");
# XML.tag returns the raw literal tag string including the prefix. Match EzXML's behavior -
# only the root element ever carries a prefix in this convention, but strip generally for parity.
# split(tag, ':') allocates a Vector on every call even when there's no ':' to split on - since
# that's true for ~every non-root element, this was 136MB/load on the large_synthetic fixture
# (dominant cost in the whole prototype). Check for ':' first; only split in the rare case it's there.
function name(node::XML.Node)::String
    tag = XML.tag(node)
    idx = findlast(==(':'), tag)
    return isnothing(idx) ? tag : tag[(idx + 1):end]
end

# Not XML.is_simple_value: it returns `nothing` whenever the element has ANY attributes, even
# with genuine direct text content (e.g. <TestComplex2 extended_simple="extend">UYTY</TestComplex2>,
# a simpleContent/extension shape - real, attributes-plus-text is a normal XSD pattern here).
# Concatenate direct Text children instead, matching EzXML.nodecontent's semantics for a leaf.
function content(node::XML.Node)::String
    kids = XML.children(node)
    # common case: a leaf has exactly one Text child (or none) - skip the IOBuffer entirely
    if isempty(kids)
        return ""
    elseif length(kids) == 1
        return XML.nodetype(kids[1]) == XML.Text ? strip(XML.value(kids[1])) : ""
    end
    buf = IOBuffer()
    for c in kids
        XML.nodetype(c) == XML.Text && print(buf, XML.value(c))
    end
    return strip(String(take!(buf)))
end
get_node_content(node::XML.Node)::String = content(node)

function haschildren(node::XML.Node)::Bool
    for c in XML.children(node)
        XML.nodetype(c) == XML.Element && return true
    end
    return false
end

# only Element children - mirrors EzXML.eachelement, which skips Text/Comment nodes
element_children(node::XML.Node) = Iterators.filter(c -> XML.nodetype(c) == XML.Element, XML.children(node))

function getattributes_dict(node::XML.Node)::Dict{String,String}
    attrs = XML.attributes(node)
    isnothing(attrs) && return Dict{String,String}()
    return Dict{String,String}(String(k) => String(v) for (k, v) in attrs)
end

function docroot(doc::XML.Node)::XML.Node
    for c in XML.children(doc)
        XML.nodetype(c) == XML.Element && return c
    end
    error("no root element found")
end

# Build the whole XmlStructLoaderNode tree in a single pass, wiring parent/children/next_sibling
# as real fields - see the struct docstring above for why (turns every AbstractTrees call during
# the actual traversal into a field access instead of a dict lookup). One dict remains: the shared
# xml_parser_in_module.jl calls AbstractTrees.parent on the RAW node directly (to key its
# per-parent accumulator dict, xml_parser_in_module.jl:75) - a single raw-node -> raw-parent map,
# not the earlier 3-dict approach, since children/sibling links now live on the wrapper itself.
const _raw_parent_map = IdDict{XML.Node,XML.Node}()
AbstractTrees.parent(node::XML.Node) = _raw_parent_map[node]

# shared, reused for every leaf node instead of allocating a fresh empty Vector each time -
# most nodes in a realistic document (e.g. 120,000 of 140,001 in large_synthetic) are leaves.
const EMPTY_CHILDREN = XmlStructLoaderNode{XML.Node}[]

function _build_node_tree(
    raw::XML.Node,
    type::T,
    parent::Union{Nothing,XmlStructLoaderNode{XML.Node}},
) where {T}
    self = XmlStructLoaderNode{XML.Node,T}(raw, type, parent, EMPTY_CHILDREN, nothing)
    kids_raw = collect(element_children(raw))
    isempty(kids_raw) && return self
    kids = Vector{XmlStructLoaderNode{XML.Node}}(undef, length(kids_raw))
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

# The shared xml_parser_in_module.jl constructs wrappers via the plain 3-arg
# XmlStructLoaderNode(node, type, parent) call in two situations: once for the true document
# root (parent===nothing) - which needs the FULL tree built, since PostOrderDFS traverses it -
# and once to reinterpret an already-visited leaf node under a different declared type (unwrapping
# a simpleType restriction's `value` field, xml_parser_in_module.jl:30) - which is never traversed
# again, so an empty children/next_sibling is fine there.
XmlStructLoaderNode(node::XML.Node, type, ::Nothing) = _build_node_tree(node, type, nothing)
XmlStructLoaderNode(node::XML.Node, type, parent::XmlStructLoaderNode) =
    XmlStructLoaderNode(node, type, parent, EMPTY_CHILDREN, nothing)

function readxmlfile(f::Function, filename::AbstractString)
    @debug "Loading with XML.jl..."
    return f(XML.read(filename, XML.Node))
end
function readxmlfile(f::Function, io::IO)
    @debug "Loading with XML.jl..."
    return f(XML.read(io, XML.Node))
end

AbstractTrees.parent(node::XmlStructLoaderNode) = isnothing(node.parent) ? node.node : node.parent
AbstractTrees.isroot(node::XmlStructLoaderNode) = isnothing(node.parent)
AbstractTrees.children(node::XmlStructLoaderNode) = node.children

Base.IteratorEltype(::Type{<:AbstractTrees.TreeIterator{<:XmlStructLoaderNode}}) = Base.HasEltype()
Base.eltype(::Type{<:AbstractTrees.TreeIterator{T}}) where {T<:XmlStructLoaderNode} = T
AbstractTrees.ParentLinks(::Type{<:XmlStructLoaderNode}) = AbstractTrees.ImplicitParents()
AbstractTrees.SiblingLinks(::Type{<:XmlStructLoaderNode}) = AbstractTrees.StoredSiblings()

AbstractTrees.nextsibling(node::XmlStructLoaderNode) = node.next_sibling

function _get_default(@nospecialize(ParentType::Type), child::XML.Node)
    defaults = AbstractXsdTypes.defaults(ParentType)
    return get(defaults, tag_symbol(name(child)), nothing)
end
get_default(node::XmlStructLoaderNode) = _get_default(node.parent.type, node.node)

# --- type-info helpers (pure Julia reflection, no backend dependency - identical to the real
#     package's xml_parser_type_info.jl, copied verbatim rather than included to keep this
#     module fully self-contained/independent for a clean A/B benchmark) ---

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

# --- the actual production algorithm (backend-agnostic - see module docstring above) ---

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

function construct_xml_root_object(xml_root::XML.Node, module_ref::Module, validate::Bool)
    root_type = module_ref.__meta.root_type
    root_attributes = getattributes_dict(xml_root)
    root_attributes["__root_name"] = name(xml_root)

    empty!(_raw_parent_map)
    child_object_dict = construct_xml_node_child_objects(xml_root, module_ref, validate)
    merge!(child_object_dict, Dict(:__xml_attributes => root_attributes, :__validated => validate))
    return root_type(; child_object_dict...)
end

function construct_xml_object(xml::Union{IO,AbstractString}, module_ref::Module; validate::Bool = true)
    return readxmlfile(xml) do doc
        root = docroot(doc)
        return construct_xml_root_object(root, module_ref, validate)
    end
end

load(xml_path::AbstractString, module_ref::Module; validate::Bool = true) =
    Base.@invokelatest construct_xml_object(xml_path, module_ref; validate = validate)

end # module
