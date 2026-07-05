"""
    PugixmlDocumentHandle

Julia-GC-managed owner of a pugixml document pointer. `XmlStructPugixml.parse_file`/`parse_buffer`
return a raw `Ptr{Cvoid}` into a C++-managed, single-owner document that must be freed exactly
once (`XmlStructPugixml.free_doc`) - this wrapper ties that free to Julia's own garbage collector
via a finalizer, so a document parsed for `ReadOnAccess` stays alive for as long as any [`LazyNode`](@ref)
derived from it is still reachable, instead of being freed the instant `load()` returns (as the
eager `ReadAllData` path still correctly does, unchanged).

Call [`close`](@ref) for deterministic release instead of waiting for GC if loading many large
documents in a loop. The finalizer is idempotent - closing explicitly and then letting the
finalizer also run later is safe.
"""
mutable struct PugixmlDocumentHandle
    ptr::Ptr{Cvoid}

    function PugixmlDocumentHandle(ptr::Ptr{Cvoid})
        handle = new(ptr)
        finalizer(_free_pugixml_document_handle!, handle)
        return handle
    end
end

function _free_pugixml_document_handle!(handle::PugixmlDocumentHandle)::Nothing
    if handle.ptr != C_NULL
        XmlStructPugixml.free_doc(handle.ptr)
        handle.ptr = C_NULL
    end
    return nothing
end

"""
    close(handle::PugixmlDocumentHandle)::Nothing

Free the underlying pugixml document now. Idempotent: safe to call more than once, and safe even
after the finalizer has already run. Any [`LazyNode`](@ref) still referencing this handle becomes
unsafe to use after this call - there is no per-access "is this closed" check (matching the
posture of reading a closed `IOStream`), so this is a documented caller contract, not a defended
error path.
"""
Base.close(handle::PugixmlDocumentHandle)::Nothing = _free_pugixml_document_handle!(handle)

"""
    LazyNode

A pugixml node handle paired with the [`PugixmlDocumentHandle`](@ref) that owns its document. As
long as any `LazyNode` is reachable, Julia's GC keeps `owner` (and therefore the underlying
document) alive. Never extract and use `.ptr` outside this file without a `GC.@preserve node.owner`
around the call - see the accessor functions below for the pattern.
"""
struct LazyNode
    ptr::Ptr{Cvoid}
    owner::PugixmlDocumentHandle
end

"""
    lazy_name(node::LazyNode)::String

The node's tag name (namespace-prefix-stripped, same as [`name`](@ref) on a raw pugixml pointer).
"""
function lazy_name(node::LazyNode)::String
    owner = node.owner
    return GC.@preserve owner name(node.ptr)
end

"""
    lazy_content(node::LazyNode)::String

The node's direct text content, stripped (same as [`content`](@ref) on a raw pugixml pointer).
"""
function lazy_content(node::LazyNode)::String
    owner = node.owner
    return GC.@preserve owner content(node.ptr)
end

"""
    lazy_haschildren(node::LazyNode)::Bool
"""
function lazy_haschildren(node::LazyNode)::Bool
    owner = node.owner
    return GC.@preserve owner haschildren(node.ptr)
end

"""
    lazy_attributes_dict(node::LazyNode)::Dict{String,String}
"""
function lazy_attributes_dict(node::LazyNode)::Dict{String,String}
    owner = node.owner
    return GC.@preserve owner getattributes_dict(node.ptr)
end

"""
    lazy_children(node::LazyNode)::Vector{LazyNode}

All element children of `node`, each wrapped with the same `owner` as `node` - the whole subtree
shares one document handle, so the document stays alive as long as anything anywhere under it does.
"""
function lazy_children(node::LazyNode)::Vector{LazyNode}
    owner = node.owner
    child_ptrs = GC.@preserve owner XmlStructPugixml.element_children(node.ptr)
    return [LazyNode(ptr, owner) for ptr in child_ptrs]
end

"""
    lazy_child_with_name(node::LazyNode, child_name::AbstractString, is_optional::Bool)::Union{Nothing,LazyNode}

The first element child of `node` named `child_name`, or `nothing` if `is_optional` and no such
child exists. Raises an error if the child is required (`is_optional == false`) and missing -
matching the eager path's own "missing required element" behavior.
"""
function lazy_child_with_name(node::LazyNode, child_name::AbstractString, is_optional::Bool)::Union{Nothing,LazyNode}
    for child in lazy_children(node)
        lazy_name(child) == child_name && return child
    end
    is_optional || error("Name: $(child_name) is not an element of node $(lazy_name(node))")
    return nothing
end

"""
    lazy_children_with_name(node::LazyNode, child_name::AbstractString)::Vector{LazyNode}

Every element child of `node` named `child_name`, in document order - for repeated (vector) fields.
"""
function lazy_children_with_name(node::LazyNode, child_name::AbstractString)::Vector{LazyNode}
    return filter(child -> lazy_name(child) == child_name, lazy_children(node))
end
