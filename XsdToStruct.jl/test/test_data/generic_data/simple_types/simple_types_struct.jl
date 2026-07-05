module TestSimpleTyping_struct

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
An example of a simple xsd type.
"""
Base.@kwdef struct TestSimpleType2 <: AbstractXsdTypes.AbstractXSDSigned
    value::Int64
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
    function TestSimpleType2(
        value::Number,
        __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
        __validated::Bool=true)
        if __validated
            AbstractXsdTypes.check_restrictions(TestSimpleType2, value)
        end
        return new(value, __xml_attributes, __validated)
    end
end

@inline AbstractXsdTypes.get_max_value(::Type{TestSimpleType2})::Int64 = 500

@inline AbstractXsdTypes.is_max_exclusive(::Type{TestSimpleType2})::Bool = false

@inline AbstractXsdTypes.get_min_value(::Type{TestSimpleType2})::Int64 = 100

@inline AbstractXsdTypes.is_min_exclusive(::Type{TestSimpleType2})::Bool = false

@inline AbstractXsdTypes.get_restriction_checks(::Type{TestSimpleType2}) = (
    AbstractXsdTypes.bound_restriction_check,)

export TestSimpleType2

"""
An example of a simple xsd type.
"""
Base.@kwdef struct TestSimpleType4 <: AbstractXsdTypes.AbstractXSDUnsigned
    value::UInt64
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
    function TestSimpleType4(
        value::Number,
        __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
        __validated::Bool=true)
        if __validated
            AbstractXsdTypes.check_restrictions(TestSimpleType4, value)
        end
        return new(value, __xml_attributes, __validated)
    end
end

@inline AbstractXsdTypes.get_max_value(::Type{TestSimpleType4})::UInt64 = 50

@inline AbstractXsdTypes.is_max_exclusive(::Type{TestSimpleType4})::Bool = false

@inline AbstractXsdTypes.get_min_value(::Type{TestSimpleType4})::UInt64 = 10

@inline AbstractXsdTypes.is_min_exclusive(::Type{TestSimpleType4})::Bool = false

@inline AbstractXsdTypes.get_restriction_checks(::Type{TestSimpleType4}) = (
    AbstractXsdTypes.bound_restriction_check,)

export TestSimpleType4

"""
An example of a simple xsd type.
"""
Base.@kwdef struct TestSimpleType5 <: AbstractXsdTypes.AbstractXSDFloat
    value::Float64
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
    function TestSimpleType5(
        value::Number,
        __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
        __validated::Bool=true)
        if __validated
            AbstractXsdTypes.check_restrictions(TestSimpleType5, value)
        end
        return new(value, __xml_attributes, __validated)
    end
end

@inline AbstractXsdTypes.get_max_value(::Type{TestSimpleType5})::Float64 = 200.0

@inline AbstractXsdTypes.is_max_exclusive(::Type{TestSimpleType5})::Bool = false

@inline AbstractXsdTypes.get_min_value(::Type{TestSimpleType5})::Float64 = -200.0

@inline AbstractXsdTypes.is_min_exclusive(::Type{TestSimpleType5})::Bool = false

@inline AbstractXsdTypes.get_restriction_checks(::Type{TestSimpleType5}) = (
    AbstractXsdTypes.bound_restriction_check,)

export TestSimpleType5

@lazy struct TestComplexType1 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy TestElement1::TestSimpleType1 = _init_TestElement1
    @lazy TestElement2::TestSimpleType2 = _init_TestElement2
    @lazy TestElement3::Bool = _init_TestElement3
    @lazy TestElement4::TestSimpleType4 = _init_TestElement4
    @lazy TestElement5::TestSimpleType5 = _init_TestElement5
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType1(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType1(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, attribs, false)
end

function TestComplexType1(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __lazy_arg_5, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(nothing, convert(TestSimpleType1, __lazy_arg_1), convert(TestSimpleType2, __lazy_arg_2), convert(Bool, __lazy_arg_3), convert(TestSimpleType4, __lazy_arg_4), convert(TestSimpleType5, __lazy_arg_5), __xml_attributes, __validated)
end

function TestComplexType1(; TestElement1, TestElement2, TestElement3, TestElement4, TestElement5, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(TestElement1, TestElement2, TestElement3, TestElement4, TestElement5, __xml_attributes, __validated)
end

function _init_TestElement1(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement1", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType1, parent_node), @__MODULE__, false)
end

function _init_TestElement2(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement2", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType2, parent_node), @__MODULE__, false)
end

function _init_TestElement3(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement3", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Bool, @__MODULE__, false, nothing)
end

function _init_TestElement4(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement4", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType4, parent_node), @__MODULE__, false)
end

function _init_TestElement5(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement5", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType5, parent_node), @__MODULE__, false)
end

export TestComplexType1

@lazy struct TestComplexType2 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy TestElement11::TestSimpleType1 = _init_TestElement11
    @lazy TestElement12::TestSimpleType1 = _init_TestElement12
    @lazy TestElement21::TestSimpleType2 = _init_TestElement21
    @lazy TestElement22::TestSimpleType2 = _init_TestElement22
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

AbstractXsdTypes.defaults(::Type{TestComplexType2}) = (TestElement11 = TestSimpleType1("DEFA"), TestElement21 = TestSimpleType2(100), )

function TestComplexType2(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType2(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, attribs, false)
end

function TestComplexType2(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType2(nothing, convert(TestSimpleType1, __lazy_arg_1), convert(TestSimpleType1, __lazy_arg_2), convert(TestSimpleType2, __lazy_arg_3), convert(TestSimpleType2, __lazy_arg_4), __xml_attributes, __validated)
end

function TestComplexType2(; TestElement11, TestElement12, TestElement21, TestElement22, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType2(TestElement11, TestElement12, TestElement21, TestElement22, __xml_attributes, __validated)
end

function _init_TestElement11(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement11", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType1, parent_node), @__MODULE__, false)
end

function _init_TestElement12(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement12", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType1, parent_node), @__MODULE__, false)
end

function _init_TestElement21(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement21", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType2, parent_node), @__MODULE__, false)
end

function _init_TestElement22(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement22", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType2, parent_node), @__MODULE__, false)
end

@doc """
An example of a type with string based elements both with and without default values.
""" TestComplexType2

export TestComplexType2

@lazy struct documentType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy TestElement1::TestComplexType1 = _init_TestElement1
    @lazy TestElement2::TestComplexType2 = _init_TestElement2
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function documentType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return documentType(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, attribs, false)
end

function documentType(__lazy_arg_1, __lazy_arg_2, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(nothing, convert(TestComplexType1, __lazy_arg_1), convert(TestComplexType2, __lazy_arg_2), __xml_attributes, __validated)
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
    return TestComplexType2(child)
end

export documentType

end
