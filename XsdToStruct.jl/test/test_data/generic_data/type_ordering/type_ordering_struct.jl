module TestOutOfOrder_struct

import AbstractXsdTypes
using LazilyInitializedFields
import XmlStructLoader

"""
An example of an xsd type which used by another type that is defined before this one is defined.
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

@lazy struct TestComplexType1 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_order::TestSimpleType1 = _init_Element_order
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType1(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType1(node, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function TestComplexType1(__lazy_arg_1, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(nothing, convert(TestSimpleType1, __lazy_arg_1), __xml_attributes, __validated)
end

function TestComplexType1(; Element_order, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(Element_order, __xml_attributes, __validated)
end

function _init_Element_order(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_order", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType1, parent_node), @__MODULE__, false)
end

@doc """
An example of an xsd type which uses another type that is defined after this one.
""" TestComplexType1

export TestComplexType1

"""
An example of an xsd type which uses another type that is defined after this one.
"""
Base.@kwdef struct TestSimpleType2 <: AbstractXsdTypes.AbstractXSDString
    value::TestSimpleType1
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
    function TestSimpleType2(
        value::AbstractString,
        __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
        __validated::Bool=true)
        if __validated
            AbstractXsdTypes.check_restrictions(TestSimpleType2, value)
        end
        return new(value, __xml_attributes, __validated)
    end
end

export TestSimpleType2

@lazy struct documentType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy TestElement1::TestComplexType1 = _init_TestElement1
    @lazy TestElement2::TestSimpleType2 = _init_TestElement2
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function documentType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return documentType(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function documentType(__lazy_arg_1, __lazy_arg_2, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(nothing, convert(TestComplexType1, __lazy_arg_1), convert(TestSimpleType2, __lazy_arg_2), __xml_attributes, __validated)
end

function documentType(; TestElement1, TestElement2, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(TestElement1, TestElement2, __xml_attributes, __validated)
end

function _init_TestElement1(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement1", false)
    isnothing(child) && return nothing
    return TestComplexType1(child)
end

function _init_TestElement2(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement2", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType2, parent_node), @__MODULE__, false)
end

export documentType

end
