module TestDateFormats_struct

using Reexport
@reexport using Dates
@reexport using TimeZones
import AbstractXsdTypes
using LazilyInitializedFields
import XmlStructLoader

@lazy struct TestComplexType1 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_dateTime::Vector{Union{ZonedDateTime, DateTime}} = _init_Element_dateTime
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType1(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType1(node, LazilyInitializedFields.uninit, attribs, false)
end

function TestComplexType1(__lazy_arg_1, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(nothing, convert(Vector{Union{ZonedDateTime, DateTime}}, __lazy_arg_1), __xml_attributes, __validated)
end

function TestComplexType1(; Element_dateTime, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(Element_dateTime, __xml_attributes, __validated)
end

function _init_Element_dateTime(o::TestComplexType1)
    return Union{ZonedDateTime, DateTime}[(let owner = child.owner; GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Union{ZonedDateTime, DateTime}, @__MODULE__, false, nothing); end) for child in XmlStructLoader.lazy_children_with_name(o._node, "Element_dateTime")]
end

@doc """
An example of a complex xsd type with a vector of date times.
""" TestComplexType1

export TestComplexType1

@lazy struct documentType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy TestElement1::TestComplexType1 = _init_TestElement1
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function documentType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return documentType(node, LazilyInitializedFields.uninit, attribs, false)
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
    return TestComplexType1(child)
end

export documentType

end
