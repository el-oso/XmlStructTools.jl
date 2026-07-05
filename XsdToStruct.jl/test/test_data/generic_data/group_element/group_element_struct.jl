module TestGroup_struct

import AbstractXsdTypes
using LazilyInitializedFields
import XmlStructLoader

@lazy struct TestComplexType1 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_string::String = _init_Element_string
    @lazy Element_double::Float64 = _init_Element_double
    @lazy Element_boolean::Bool = _init_Element_boolean
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType1(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType1(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function TestComplexType1(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(nothing, convert(String, __lazy_arg_1), convert(Float64, __lazy_arg_2), convert(Bool, __lazy_arg_3), __xml_attributes, __validated)
end

function TestComplexType1(; Element_string, Element_double, Element_boolean, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(Element_string, Element_double, Element_boolean, __xml_attributes, __validated)
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

@doc """
Example of a complex XSD type that uses a group.
""" TestComplexType1

export TestComplexType1

@lazy struct TestComplexType2 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_string::String = _init_Element_string
    @lazy Element_double::Float64 = _init_Element_double
    @lazy Element_boolean::Bool = _init_Element_boolean
    @lazy Element_boolean_second::Bool = _init_Element_boolean_second
    @lazy Element_string_2::String = _init_Element_string_2
    @lazy Element_double_2::Float64 = _init_Element_double_2
    @lazy Element_boolean_2::Bool = _init_Element_boolean_2
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType2(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType2(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function TestComplexType2(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __lazy_arg_5, __lazy_arg_6, __lazy_arg_7, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType2(nothing, convert(String, __lazy_arg_1), convert(Float64, __lazy_arg_2), convert(Bool, __lazy_arg_3), convert(Bool, __lazy_arg_4), convert(String, __lazy_arg_5), convert(Float64, __lazy_arg_6), convert(Bool, __lazy_arg_7), __xml_attributes, __validated)
end

function TestComplexType2(; Element_string, Element_double, Element_boolean, Element_boolean_second, Element_string_2, Element_double_2, Element_boolean_2, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType2(Element_string, Element_double, Element_boolean, Element_boolean_second, Element_string_2, Element_double_2, Element_boolean_2, __xml_attributes, __validated)
end

function _init_Element_string(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_string", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, nothing)
end

function _init_Element_double(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_double", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Float64, @__MODULE__, false, nothing)
end

function _init_Element_boolean(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_boolean", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Bool, @__MODULE__, false, nothing)
end

function _init_Element_boolean_second(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_boolean_second", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Bool, @__MODULE__, false, nothing)
end

function _init_Element_string_2(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_string_2", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, nothing)
end

function _init_Element_double_2(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_double_2", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Float64, @__MODULE__, false, nothing)
end

function _init_Element_boolean_2(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_boolean_2", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Bool, @__MODULE__, false, nothing)
end

@doc """
Example of a complex XSD type that uses a group and an element.
""" TestComplexType2

export TestComplexType2

@lazy struct TestComplexType3 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_string::String = _init_Element_string
    @lazy Element_double::Float64 = _init_Element_double
    @lazy Element_boolean::Bool = _init_Element_boolean
    @lazy Element_boolean2::Bool = _init_Element_boolean2
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType3(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType3(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function TestComplexType3(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType3(nothing, convert(String, __lazy_arg_1), convert(Float64, __lazy_arg_2), convert(Bool, __lazy_arg_3), convert(Bool, __lazy_arg_4), __xml_attributes, __validated)
end

function TestComplexType3(; Element_string, Element_double, Element_boolean, Element_boolean2, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType3(Element_string, Element_double, Element_boolean, Element_boolean2, __xml_attributes, __validated)
end

function _init_Element_string(o::TestComplexType3)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_string", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, nothing)
end

function _init_Element_double(o::TestComplexType3)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_double", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Float64, @__MODULE__, false, nothing)
end

function _init_Element_boolean(o::TestComplexType3)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_boolean", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Bool, @__MODULE__, false, nothing)
end

function _init_Element_boolean2(o::TestComplexType3)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_boolean2", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Bool, @__MODULE__, false, nothing)
end

@doc """
Example of a complex XSD type that uses a nested group.
""" TestComplexType3

export TestComplexType3

@lazy struct documentType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy TestElement1::TestComplexType1 = _init_TestElement1
    @lazy TestElement2::TestComplexType2 = _init_TestElement2
    @lazy TestElement3::TestComplexType3 = _init_TestElement3
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function documentType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return documentType(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function documentType(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(nothing, convert(TestComplexType1, __lazy_arg_1), convert(TestComplexType2, __lazy_arg_2), convert(TestComplexType3, __lazy_arg_3), __xml_attributes, __validated)
end

function documentType(; TestElement1, TestElement2, TestElement3, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(TestElement1, TestElement2, TestElement3, __xml_attributes, __validated)
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

export documentType

end
