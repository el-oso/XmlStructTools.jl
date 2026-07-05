module TestTypeInElement_struct

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

@inline AbstractXsdTypes.get_max_fraction_digits(::Type{TestSimpleType2})::Int = 4

@inline AbstractXsdTypes.get_restriction_checks(::Type{TestSimpleType2}) = (
    AbstractXsdTypes.fraction_digits_check,)

export TestSimpleType2

module documentTypeTypes


    import AbstractXsdTypes
    using LazilyInitializedFields
    import XmlStructLoader

    using ..TestTypeInElement_struct

    """
    An example of a simple xsd type.
    """
    Base.@kwdef struct TestSimple2 <: AbstractXsdTypes.AbstractXSDString
        value::String
        __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
        __validated::Bool = true
        function TestSimple2(
            value::AbstractString,
            __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
            __validated::Bool=true)
            if __validated
                AbstractXsdTypes.check_restrictions(TestSimple2, value)
            end
            return new(value, __xml_attributes, __validated)
        end
    end

    @lazy struct TestComplex1 <: AbstractXsdTypes.AbstractXSDComplex
        _node::Union{Nothing, XmlStructLoader.LazyNode}
        @lazy Element_string::String = _init_Element_string
        @lazy Element_double::Float64 = _init_Element_double
        @lazy Element_boolean::Bool = _init_Element_boolean
        __xml_attributes::Union{Nothing, Dict{String, String}}
        __validated::Bool
    end

    function TestComplex1(node::XmlStructLoader.LazyNode)
        attribs = XmlStructLoader.lazy_attributes_dict(node)
        return TestComplex1(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, attribs, false)
    end

    function TestComplex1(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __xml_attributes = nothing, __validated::Bool = true)
        return TestComplex1(nothing, convert(String, __lazy_arg_1), convert(Float64, __lazy_arg_2), convert(Bool, __lazy_arg_3), __xml_attributes, __validated)
    end

    function TestComplex1(; Element_string, Element_double, Element_boolean, __xml_attributes = nothing, __validated::Bool = true)
        return TestComplex1(Element_string, Element_double, Element_boolean, __xml_attributes, __validated)
    end

    function _init_Element_string(o::TestComplex1)
        child = XmlStructLoader.lazy_child_with_name(o._node, "Element_string", false)
        isnothing(child) && return nothing
        owner = child.owner
        return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, nothing)
    end

    function _init_Element_double(o::TestComplex1)
        child = XmlStructLoader.lazy_child_with_name(o._node, "Element_double", false)
        isnothing(child) && return nothing
        owner = child.owner
        return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Float64, @__MODULE__, false, nothing)
    end

    function _init_Element_boolean(o::TestComplex1)
        child = XmlStructLoader.lazy_child_with_name(o._node, "Element_boolean", false)
        isnothing(child) && return nothing
        owner = child.owner
        return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Bool, @__MODULE__, false, nothing)
    end

    @doc """
    An example of a complex xsd type.
    """ TestComplex1

    """
    An example of an extended simple xsd type.
    """
    Base.@kwdef struct TestComplex2 <: AbstractXsdTypes.AbstractXSDString
        value::TestSimpleType1
        __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
        __validated::Bool = true
    end

    """
    An example of an restricted simple xsd type.
    """
    Base.@kwdef struct TestComplex3 <: AbstractXsdTypes.AbstractXSDFloat
        value::TestSimpleType2
        __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
        __validated::Bool = true
        function TestComplex3(
            value::Number,
            __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
            __validated::Bool=true)
            if __validated
                AbstractXsdTypes.check_restrictions(TestComplex3, value)
            end
            return new(value, __xml_attributes, __validated)
        end
    end

    @inline AbstractXsdTypes.get_min_value(::Type{TestComplex3})::TestSimpleType2 = TestSimpleType2(0.00)

    @inline AbstractXsdTypes.is_min_exclusive(::Type{TestComplex3})::Bool = false

    @inline AbstractXsdTypes.get_restriction_checks(::Type{TestComplex3}) = (
        AbstractXsdTypes.bound_restriction_check,)

end

export documentTypeTypes

@lazy struct documentType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy TestSimple2::documentTypeTypes.TestSimple2 = _init_TestSimple2
    @lazy TestComplex1::documentTypeTypes.TestComplex1 = _init_TestComplex1
    @lazy TestComplex2::documentTypeTypes.TestComplex2 = _init_TestComplex2
    @lazy TestComplex3::documentTypeTypes.TestComplex3 = _init_TestComplex3
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function documentType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return documentType(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, attribs, false)
end

function documentType(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(nothing, convert(documentTypeTypes.TestSimple2, __lazy_arg_1), convert(documentTypeTypes.TestComplex1, __lazy_arg_2), convert(documentTypeTypes.TestComplex2, __lazy_arg_3), convert(documentTypeTypes.TestComplex3, __lazy_arg_4), __xml_attributes, __validated)
end

function documentType(; TestSimple2, TestComplex1, TestComplex2, TestComplex3, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(TestSimple2, TestComplex1, TestComplex2, TestComplex3, __xml_attributes, __validated)
end

function _init_TestSimple2(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestSimple2", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, documentTypeTypes.TestSimple2, parent_node), @__MODULE__, false)
end

function _init_TestComplex1(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestComplex1", false)
    isnothing(child) && return nothing
    return documentTypeTypes.TestComplex1(child)
end

function _init_TestComplex2(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestComplex2", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, documentTypeTypes.TestComplex2, parent_node), @__MODULE__, false)
end

function _init_TestComplex3(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestComplex3", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, documentTypeTypes.TestComplex3, parent_node), @__MODULE__, false)
end

export documentType

end
