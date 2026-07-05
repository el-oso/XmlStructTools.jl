module TestSimpleUnion_struct

import AbstractXsdTypes
using LazilyInitializedFields
import XmlStructLoader

module TestDoubleRestrictedDoubleTypes


    import AbstractXsdTypes
    using LazilyInitializedFields
    import XmlStructLoader

    using ..TestSimpleUnion_struct

    Base.@kwdef struct type_1 <: AbstractXsdTypes.AbstractXSDFloat
        value::Float64
        __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
        __validated::Bool = true
        function type_1(
            value::Number,
            __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
            __validated::Bool=true)
            if __validated
                AbstractXsdTypes.check_restrictions(type_1, value)
            end
            return new(value, __xml_attributes, __validated)
        end
    end

    @inline AbstractXsdTypes.get_max_value(::Type{type_1})::Float64 = 1.0

    @inline AbstractXsdTypes.is_max_exclusive(::Type{type_1})::Bool = false

    @inline AbstractXsdTypes.get_min_value(::Type{type_1})::Float64 = 0.0

    @inline AbstractXsdTypes.is_min_exclusive(::Type{type_1})::Bool = false

    @inline AbstractXsdTypes.get_restriction_checks(::Type{type_1}) = (
        AbstractXsdTypes.bound_restriction_check,)

    Base.@kwdef struct type_2 <: AbstractXsdTypes.AbstractXSDFloat
        value::Float64
        __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
        __validated::Bool = true
        function type_2(
            value::Number,
            __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
            __validated::Bool=true)
            if __validated
                AbstractXsdTypes.check_restrictions(type_2, value)
            end
            return new(value, __xml_attributes, __validated)
        end
    end

end

export TestDoubleRestrictedDoubleTypes

"""
An example of a union of the same base types.
"""
Base.@kwdef struct TestDoubleRestrictedDouble <: AbstractXsdTypes.AbstractXSDUnion
    value :: Union{TestDoubleRestrictedDoubleTypes.type_1, TestDoubleRestrictedDoubleTypes.type_2}
    __validated::Bool = true
end

AbstractXsdTypes.union_types(::Type{<:TestDoubleRestrictedDouble}) = (TestDoubleRestrictedDoubleTypes.type_1, TestDoubleRestrictedDoubleTypes.type_2)

export TestDoubleRestrictedDouble

module UnionTypeTypes


    import AbstractXsdTypes
    using LazilyInitializedFields
    import XmlStructLoader

    using ..TestSimpleUnion_struct

    Base.@kwdef struct type_1 <: AbstractXsdTypes.AbstractXSDFloat
        value::Float64
        __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
        __validated::Bool = true
        function type_1(
            value::Number,
            __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
            __validated::Bool=true)
            if __validated
                AbstractXsdTypes.check_restrictions(type_1, value)
            end
            return new(value, __xml_attributes, __validated)
        end
    end

    @inline AbstractXsdTypes.get_max_value(::Type{type_1})::Float64 = 1.0

    @inline AbstractXsdTypes.is_max_exclusive(::Type{type_1})::Bool = false

    @inline AbstractXsdTypes.get_min_value(::Type{type_1})::Float64 = 0.0

    @inline AbstractXsdTypes.is_min_exclusive(::Type{type_1})::Bool = false

    @inline AbstractXsdTypes.get_restriction_checks(::Type{type_1}) = (
        AbstractXsdTypes.bound_restriction_check,)

    Base.@kwdef struct type_2 <: AbstractXsdTypes.AbstractXSDSigned
        value::Int64
        __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
        __validated::Bool = true
    end

end

export UnionTypeTypes

"""
An example of a union of two different types.
"""
Base.@kwdef struct UnionType <: AbstractXsdTypes.AbstractXSDUnion
    value :: Union{UnionTypeTypes.type_1, UnionTypeTypes.type_2}
    __validated::Bool = true
end

AbstractXsdTypes.union_types(::Type{<:UnionType}) = (UnionTypeTypes.type_1, UnionTypeTypes.type_2)

export UnionType

@lazy struct documentType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy TestDoubleRestrictedDouble::TestDoubleRestrictedDouble = _init_TestDoubleRestrictedDouble
    @lazy UnionType::UnionType = _init_UnionType
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function documentType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return documentType(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function documentType(__lazy_arg_1, __lazy_arg_2, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(nothing, convert(TestDoubleRestrictedDouble, __lazy_arg_1), convert(UnionType, __lazy_arg_2), __xml_attributes, __validated)
end

function documentType(; TestDoubleRestrictedDouble, UnionType, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(TestDoubleRestrictedDouble, UnionType, __xml_attributes, __validated)
end

function _init_TestDoubleRestrictedDouble(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestDoubleRestrictedDouble", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestDoubleRestrictedDouble, parent_node), @__MODULE__, false)
end

function _init_UnionType(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "UnionType", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, UnionType, parent_node), @__MODULE__, false)
end

export documentType

end
