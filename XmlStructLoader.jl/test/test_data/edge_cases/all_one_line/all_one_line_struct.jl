module TestRootElementFirst_struct

using Reexport
@reexport using Dates
@reexport using TimeZones
import AbstractXsdTypes
using LazilyInitializedFields
import XmlStructLoader

@lazy struct TestComplexType1 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_string::String = _init_Element_string
    @lazy Element_double::Float64 = _init_Element_double
    @lazy Element_boolean::Bool = _init_Element_boolean
    @lazy Element_decimal::Float64 = _init_Element_decimal
    @lazy Element_dateTime::Union{ZonedDateTime, DateTime} = _init_Element_dateTime
    @lazy Element_integer::Int64 = _init_Element_integer
    @lazy Element_nonNegativeInteger::UInt64 = _init_Element_nonNegativeInteger
    @lazy Element_positiveInteger::UInt64 = _init_Element_positiveInteger
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType1(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType1(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function TestComplexType1(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __lazy_arg_5, __lazy_arg_6, __lazy_arg_7, __lazy_arg_8, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(nothing, convert(String, __lazy_arg_1), convert(Float64, __lazy_arg_2), convert(Bool, __lazy_arg_3), convert(Float64, __lazy_arg_4), convert(Union{ZonedDateTime, DateTime}, __lazy_arg_5), convert(Int64, __lazy_arg_6), convert(UInt64, __lazy_arg_7), convert(UInt64, __lazy_arg_8), __xml_attributes, __validated)
end

function TestComplexType1(; Element_string, Element_double, Element_boolean, Element_decimal, Element_dateTime, Element_integer, Element_nonNegativeInteger, Element_positiveInteger, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(Element_string, Element_double, Element_boolean, Element_decimal, Element_dateTime, Element_integer, Element_nonNegativeInteger, Element_positiveInteger, __xml_attributes, __validated)
end

function _init_Element_string(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_string", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, nothing)
end

function _init_Element_double(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_double", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Float64, @__MODULE__, false, nothing)
end

function _init_Element_boolean(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_boolean", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Bool, @__MODULE__, false, nothing)
end

function _init_Element_decimal(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_decimal", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Float64, @__MODULE__, false, nothing)
end

function _init_Element_dateTime(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_dateTime", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Union{ZonedDateTime, DateTime}, @__MODULE__, false, nothing)
end

function _init_Element_integer(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_integer", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Int64, @__MODULE__, false, nothing)
end

function _init_Element_nonNegativeInteger(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_nonNegativeInteger", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, UInt64, @__MODULE__, false, nothing)
end

function _init_Element_positiveInteger(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_positiveInteger", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, UInt64, @__MODULE__, false, nothing)
end

@doc """
An example of a complex xsd type.
""" TestComplexType1

export TestComplexType1

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

@lazy struct documentType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy TestElement1::TestComplexType1 = _init_TestElement1
    @lazy TestElement2::TestSimpleType1 = _init_TestElement2
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function documentType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return documentType(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function documentType(__lazy_arg_1, __lazy_arg_2, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(nothing, convert(TestComplexType1, __lazy_arg_1), convert(TestSimpleType1, __lazy_arg_2), __xml_attributes, __validated)
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
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType1, nothing), @__MODULE__, false)
end

export documentType

end
