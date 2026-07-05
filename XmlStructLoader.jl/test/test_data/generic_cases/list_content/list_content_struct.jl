module TestList_struct

import AbstractXsdTypes
using LazilyInitializedFields
import XmlStructLoader

@lazy struct TestComplexType1 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_list_double::Vector{Float64} = _init_Element_list_double
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType1(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType1(node, LazilyInitializedFields.uninit, attribs, false)
end

function TestComplexType1(__lazy_arg_1, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(nothing, convert(Vector{Float64}, __lazy_arg_1), __xml_attributes, __validated)
end

function TestComplexType1(; Element_list_double, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(Element_list_double, __xml_attributes, __validated)
end

function _init_Element_list_double(o::TestComplexType1)
    return Float64[(let owner = child.owner; GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Float64, @__MODULE__, false, nothing); end) for child in XmlStructLoader.lazy_children_with_name(o._node, "Element_list_double")]
end

@doc """
An example of a complex xsd type with an unbounded list.
""" TestComplexType1

export TestComplexType1

@lazy struct TestComplexType2 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_list_string::Vector{String} = _init_Element_list_string
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType2(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType2(node, LazilyInitializedFields.uninit, attribs, false)
end

function TestComplexType2(__lazy_arg_1, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType2(nothing, convert(Vector{String}, __lazy_arg_1), __xml_attributes, __validated)
end

function TestComplexType2(; Element_list_string, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType2(Element_list_string, __xml_attributes, __validated)
end

function _init_Element_list_string(o::TestComplexType2)
    return String[(let owner = child.owner; GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, nothing); end) for child in XmlStructLoader.lazy_children_with_name(o._node, "Element_list_string")]
end

@doc """
An example of a complex xsd type with a bounded list.
""" TestComplexType2

export TestComplexType2

@lazy struct TestComplexType4 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_string::String = _init_Element_string
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType4(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType4(node, LazilyInitializedFields.uninit, attribs, false)
end

function TestComplexType4(__lazy_arg_1, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType4(nothing, convert(String, __lazy_arg_1), __xml_attributes, __validated)
end

function TestComplexType4(; Element_string, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType4(Element_string, __xml_attributes, __validated)
end

function _init_Element_string(o::TestComplexType4)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_string", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, nothing)
end

@doc """
An example of a complex xsd type with no list.
""" TestComplexType4

export TestComplexType4

@lazy struct TestComplexType5 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_string::String = _init_Element_string
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType5(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType5(node, LazilyInitializedFields.uninit, attribs, false)
end

function TestComplexType5(__lazy_arg_1, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType5(nothing, convert(String, __lazy_arg_1), __xml_attributes, __validated)
end

function TestComplexType5(; Element_string, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType5(Element_string, __xml_attributes, __validated)
end

function _init_Element_string(o::TestComplexType5)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_string", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, nothing)
end

@doc """
An example of a complex xsd type with no list.
""" TestComplexType5

export TestComplexType5

@lazy struct TestComplexType3 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_type4_list::Vector{TestComplexType4} = _init_Element_type4_list
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType3(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType3(node, LazilyInitializedFields.uninit, attribs, false)
end

function TestComplexType3(__lazy_arg_1, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType3(nothing, convert(Vector{TestComplexType4}, __lazy_arg_1), __xml_attributes, __validated)
end

function TestComplexType3(; Element_type4_list, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType3(Element_type4_list, __xml_attributes, __validated)
end

function _init_Element_type4_list(o::TestComplexType3)
    return TestComplexType4[TestComplexType4(child) for child in XmlStructLoader.lazy_children_with_name(o._node, "Element_type4_list")]
end

@doc """
An example of a complex xsd type with no list.
""" TestComplexType3

export TestComplexType3

@lazy struct documentType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy TestElement1::TestComplexType1 = _init_TestElement1
    @lazy TestElement2::TestComplexType2 = _init_TestElement2
    @lazy TestElement3::TestComplexType3 = _init_TestElement3
    @lazy TestElement5::TestComplexType5 = _init_TestElement5
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function documentType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return documentType(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, attribs, false)
end

function documentType(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(nothing, convert(TestComplexType1, __lazy_arg_1), convert(TestComplexType2, __lazy_arg_2), convert(TestComplexType3, __lazy_arg_3), convert(TestComplexType5, __lazy_arg_4), __xml_attributes, __validated)
end

function documentType(; TestElement1, TestElement2, TestElement3, TestElement5, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(TestElement1, TestElement2, TestElement3, TestElement5, __xml_attributes, __validated)
end

function _init_TestElement1(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement1", false)
    isnothing(child) && return nothing
    return TestComplexType1(child)
end

function _init_TestElement2(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement2", false)
    isnothing(child) && return nothing
    return TestComplexType2(child)
end

function _init_TestElement3(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement3", false)
    isnothing(child) && return nothing
    return TestComplexType3(child)
end

function _init_TestElement5(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement5", false)
    isnothing(child) && return nothing
    return TestComplexType5(child)
end

export documentType

end
