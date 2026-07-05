module TestSimpleContent_struct

import AbstractXsdTypes
using LazilyInitializedFields
import XmlStructLoader

"""
An example of a simple xsd type.
"""
Base.@kwdef struct TestSimpleType1 <: AbstractXsdTypes.AbstractXSDString
    value::String
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
    function TestSimpleType1(
        value::AbstractString,
        __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
        __validated::Bool=true)
        if __validated
            AbstractXsdTypes.check_restrictions(TestSimpleType1, value)
        end
        return new(value, __xml_attributes, __validated)
    end
end

export TestSimpleType1

"""
Example of a complex XSD type that uses an extended simple type.
"""
Base.@kwdef struct TestComplexType1 <: AbstractXsdTypes.AbstractXSDString
    value::TestSimpleType1
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
end

export TestComplexType1

@lazy struct documentType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy TestElement1::TestComplexType1 = _init_TestElement1
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function documentType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return documentType(node, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function documentType(__lazy_arg_1, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(nothing, convert(TestComplexType1, __lazy_arg_1), __xml_attributes, __validated)
end

function documentType(; TestElement1, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(TestElement1, __xml_attributes, __validated)
end

function _init_TestElement1(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement1", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestComplexType1, parent_node), @__MODULE__, false)
end

export documentType

end
