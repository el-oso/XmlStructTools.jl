module TestDecimalRestrictions_struct

import AbstractXsdTypes
using LazilyInitializedFields
import XmlStructLoader

"""
An example of a totalDigits restricted decimal type.
"""
Base.@kwdef struct TestSimpleType1 <: AbstractXsdTypes.AbstractXSDFloat
    value::Float64
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
    function TestSimpleType1(
        value::Number,
        __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
        __validated::Bool=true)
        if __validated
            AbstractXsdTypes.check_restrictions(TestSimpleType1, value)
        end
        return new(value, __xml_attributes, __validated)
    end
end

@inline AbstractXsdTypes.get_max_total_digits(::Type{TestSimpleType1})::Int = 4

@inline AbstractXsdTypes.get_restriction_checks(::Type{TestSimpleType1}) = (
    AbstractXsdTypes.total_digits_check,)

export TestSimpleType1

"""
An example of a fractionDigits restricted decimal type.
"""
Base.@kwdef struct TestSimpleType2 <: AbstractXsdTypes.AbstractXSDFloat
    value::Float64
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

@inline AbstractXsdTypes.get_max_fraction_digits(::Type{TestSimpleType2})::Int = 3

@inline AbstractXsdTypes.get_restriction_checks(::Type{TestSimpleType2}) = (
    AbstractXsdTypes.fraction_digits_check,)

export TestSimpleType2

"""
An example of a maxInclusive restricted decimal type.
"""
Base.@kwdef struct TestSimpleType3 <: AbstractXsdTypes.AbstractXSDFloat
    value::Float64
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
    function TestSimpleType3(
        value::Number,
        __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
        __validated::Bool=true)
        if __validated
            AbstractXsdTypes.check_restrictions(TestSimpleType3, value)
        end
        return new(value, __xml_attributes, __validated)
    end
end

@inline AbstractXsdTypes.get_max_value(::Type{TestSimpleType3})::Float64 = 10.1

@inline AbstractXsdTypes.is_max_exclusive(::Type{TestSimpleType3})::Bool = false

@inline AbstractXsdTypes.get_restriction_checks(::Type{TestSimpleType3}) = (
    AbstractXsdTypes.bound_restriction_check,)

export TestSimpleType3

"""
An example of a maxExclusive restricted decimal type.
"""
Base.@kwdef struct TestSimpleType4 <: AbstractXsdTypes.AbstractXSDFloat
    value::Float64
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

@inline AbstractXsdTypes.get_max_value(::Type{TestSimpleType4})::Float64 = 15.22

@inline AbstractXsdTypes.is_max_exclusive(::Type{TestSimpleType4})::Bool = true

@inline AbstractXsdTypes.get_restriction_checks(::Type{TestSimpleType4}) = (
    AbstractXsdTypes.bound_restriction_check,)

export TestSimpleType4

"""
An example of a minInclusive restricted decimal type.
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

@inline AbstractXsdTypes.get_min_value(::Type{TestSimpleType5})::Float64 = -11.6

@inline AbstractXsdTypes.is_min_exclusive(::Type{TestSimpleType5})::Bool = false

@inline AbstractXsdTypes.get_restriction_checks(::Type{TestSimpleType5}) = (
    AbstractXsdTypes.bound_restriction_check,)

export TestSimpleType5

"""
An example of a minExclusive restricted decimal type.
"""
Base.@kwdef struct TestSimpleType6 <: AbstractXsdTypes.AbstractXSDFloat
    value::Float64
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
    function TestSimpleType6(
        value::Number,
        __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
        __validated::Bool=true)
        if __validated
            AbstractXsdTypes.check_restrictions(TestSimpleType6, value)
        end
        return new(value, __xml_attributes, __validated)
    end
end

@inline AbstractXsdTypes.get_min_value(::Type{TestSimpleType6})::Float64 = -77.8

@inline AbstractXsdTypes.is_min_exclusive(::Type{TestSimpleType6})::Bool = true

@inline AbstractXsdTypes.get_restriction_checks(::Type{TestSimpleType6}) = (
    AbstractXsdTypes.bound_restriction_check,)

export TestSimpleType6

@lazy struct documentType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy TestElement1::TestSimpleType1 = _init_TestElement1
    @lazy TestElement2::TestSimpleType2 = _init_TestElement2
    @lazy TestElement3::TestSimpleType3 = _init_TestElement3
    @lazy TestElement4::TestSimpleType4 = _init_TestElement4
    @lazy TestElement5::TestSimpleType5 = _init_TestElement5
    @lazy TestElement6::TestSimpleType6 = _init_TestElement6
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function documentType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return documentType(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, attribs, false)
end

function documentType(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __lazy_arg_5, __lazy_arg_6, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(nothing, convert(TestSimpleType1, __lazy_arg_1), convert(TestSimpleType2, __lazy_arg_2), convert(TestSimpleType3, __lazy_arg_3), convert(TestSimpleType4, __lazy_arg_4), convert(TestSimpleType5, __lazy_arg_5), convert(TestSimpleType6, __lazy_arg_6), __xml_attributes, __validated)
end

function documentType(; TestElement1, TestElement2, TestElement3, TestElement4, TestElement5, TestElement6, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(TestElement1, TestElement2, TestElement3, TestElement4, TestElement5, TestElement6, __xml_attributes, __validated)
end

function _init_TestElement1(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement1", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType1, parent_node), @__MODULE__, false)
end

function _init_TestElement2(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement2", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType2, parent_node), @__MODULE__, false)
end

function _init_TestElement3(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement3", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType3, parent_node), @__MODULE__, false)
end

function _init_TestElement4(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement4", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType4, parent_node), @__MODULE__, false)
end

function _init_TestElement5(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement5", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType5, parent_node), @__MODULE__, false)
end

function _init_TestElement6(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement6", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType6, parent_node), @__MODULE__, false)
end

export documentType

end
