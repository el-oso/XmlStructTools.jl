module TestTypeInType_struct

using Reexport
@reexport using Dates
@reexport using TimeZones
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

module TestComplexType1Types


    import AbstractXsdTypes
    using LazilyInitializedFields
    import XmlStructLoader

    using ..TestTypeInType_struct

    @lazy struct A <: AbstractXsdTypes.AbstractXSDComplex
        _node::Union{Nothing, XmlStructLoader.LazyNode}
        @lazy Element_string::String = _init_Element_string
        @lazy Element_double::Float64 = _init_Element_double
        @lazy Element_boolean::Bool = _init_Element_boolean
        @lazy Element_dateTime::Union{ZonedDateTime, DateTime} = _init_Element_dateTime
        __xml_attributes::Union{Nothing, Dict{String, String}}
        __validated::Bool
    end

    function A(node::XmlStructLoader.LazyNode)
        attribs = XmlStructLoader.lazy_attributes_dict(node)
        return A(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
    end

    function A(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __xml_attributes = nothing, __validated::Bool = true)
        return A(nothing, convert(String, __lazy_arg_1), convert(Float64, __lazy_arg_2), convert(Bool, __lazy_arg_3), convert(Union{ZonedDateTime, DateTime}, __lazy_arg_4), __xml_attributes, __validated)
    end

    function A(; Element_string, Element_double, Element_boolean, Element_dateTime, __xml_attributes = nothing, __validated::Bool = true)
        return A(Element_string, Element_double, Element_boolean, Element_dateTime, __xml_attributes, __validated)
    end

    function _init_Element_string(o::A)
        child = XmlStructLoader.lazy_child_with_name(o._node, "Element_string", false)
        isnothing(child) && return nothing
        owner = child.owner
        return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, nothing)
    end

    function _init_Element_double(o::A)
        child = XmlStructLoader.lazy_child_with_name(o._node, "Element_double", false)
        isnothing(child) && return nothing
        owner = child.owner
        return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Float64, @__MODULE__, false, nothing)
    end

    function _init_Element_boolean(o::A)
        child = XmlStructLoader.lazy_child_with_name(o._node, "Element_boolean", false)
        isnothing(child) && return nothing
        owner = child.owner
        return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Bool, @__MODULE__, false, nothing)
    end

    function _init_Element_dateTime(o::A)
        child = XmlStructLoader.lazy_child_with_name(o._node, "Element_dateTime", false)
        isnothing(child) && return nothing
        owner = child.owner
        return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Union{ZonedDateTime, DateTime}, @__MODULE__, false, nothing)
    end

    @doc """
    An example of a complex xsd type.
    """ A

    """
    An example of an extended simple xsd type.
    """
    Base.@kwdef struct B <: AbstractXsdTypes.AbstractXSDString
        value::TestSimpleType1
        __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
        __validated::Bool = true
    end

    @lazy struct C <: AbstractXsdTypes.AbstractXSDComplex
        _node::Union{Nothing, XmlStructLoader.LazyNode}
        @lazy Element_string::String = _init_Element_string
        @lazy Element_double::Float64 = _init_Element_double
        @lazy Element_boolean::Bool = _init_Element_boolean
        @lazy Element_dateTime::Union{ZonedDateTime, DateTime} = _init_Element_dateTime
        __xml_attributes::Union{Nothing, Dict{String, String}}
        __validated::Bool
    end

    function C(node::XmlStructLoader.LazyNode)
        attribs = XmlStructLoader.lazy_attributes_dict(node)
        return C(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
    end

    function C(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __xml_attributes = nothing, __validated::Bool = true)
        return C(nothing, convert(String, __lazy_arg_1), convert(Float64, __lazy_arg_2), convert(Bool, __lazy_arg_3), convert(Union{ZonedDateTime, DateTime}, __lazy_arg_4), __xml_attributes, __validated)
    end

    function C(; Element_string, Element_double, Element_boolean, Element_dateTime, __xml_attributes = nothing, __validated::Bool = true)
        return C(Element_string, Element_double, Element_boolean, Element_dateTime, __xml_attributes, __validated)
    end

    function _init_Element_string(o::C)
        child = XmlStructLoader.lazy_child_with_name(o._node, "Element_string", false)
        isnothing(child) && return nothing
        owner = child.owner
        return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, nothing)
    end

    function _init_Element_double(o::C)
        child = XmlStructLoader.lazy_child_with_name(o._node, "Element_double", false)
        isnothing(child) && return nothing
        owner = child.owner
        return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Float64, @__MODULE__, false, nothing)
    end

    function _init_Element_boolean(o::C)
        child = XmlStructLoader.lazy_child_with_name(o._node, "Element_boolean", false)
        isnothing(child) && return nothing
        owner = child.owner
        return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Bool, @__MODULE__, false, nothing)
    end

    function _init_Element_dateTime(o::C)
        child = XmlStructLoader.lazy_child_with_name(o._node, "Element_dateTime", false)
        isnothing(child) && return nothing
        owner = child.owner
        return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Union{ZonedDateTime, DateTime}, @__MODULE__, false, nothing)
    end

    @doc """
    An example of a complex xsd type.
    """ C

end

export TestComplexType1Types

@lazy struct TestComplexType1 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy A::TestComplexType1Types.A = _init_A
    @lazy B::TestComplexType1Types.B = _init_B
    @lazy C::TestComplexType1Types.C = _init_C
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType1(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType1(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function TestComplexType1(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(nothing, convert(TestComplexType1Types.A, __lazy_arg_1), convert(TestComplexType1Types.B, __lazy_arg_2), convert(TestComplexType1Types.C, __lazy_arg_3), __xml_attributes, __validated)
end

function TestComplexType1(; A, B, C, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(A, B, C, __xml_attributes, __validated)
end

function _init_A(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "A", false)
    isnothing(child) && return nothing
    return TestComplexType1Types.A(child)
end

function _init_B(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "B", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestComplexType1Types.B, nothing), @__MODULE__, false)
end

function _init_C(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "C", false)
    isnothing(child) && return nothing
    return TestComplexType1Types.C(child)
end

@doc """
Example of a complex XSD type that uses types defined under it's elements.
""" TestComplexType1

export TestComplexType1

"""
An example of a simple xsd type.
"""
Base.@kwdef struct TestSimpleType2 <: AbstractXsdTypes.AbstractXSDString
    value::String
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

module TestComplexType3Types


    import AbstractXsdTypes
    using LazilyInitializedFields
    import XmlStructLoader

    using ..TestTypeInType_struct

    """
    An example of an extended simple xsd type.
    """
    Base.@kwdef struct A <: AbstractXsdTypes.AbstractXSDString
        value::TestSimpleType1
        __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
        __validated::Bool = true
    end

    """
    An example of an extended simple xsd type.
    """
    Base.@kwdef struct B <: AbstractXsdTypes.AbstractXSDString
        value::TestSimpleType2
        __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
        __validated::Bool = true
    end

end

export TestComplexType3Types

@lazy struct TestComplexType3 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy A::TestComplexType3Types.A = _init_A
    @lazy S1::TestSimpleType2 = _init_S1
    @lazy B::TestComplexType3Types.B = _init_B
    @lazy S2::TestSimpleType2 = _init_S2
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType3(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType3(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function TestComplexType3(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType3(nothing, convert(TestComplexType3Types.A, __lazy_arg_1), convert(TestSimpleType2, __lazy_arg_2), convert(TestComplexType3Types.B, __lazy_arg_3), convert(TestSimpleType2, __lazy_arg_4), __xml_attributes, __validated)
end

function TestComplexType3(; A, S1, B, S2, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType3(A, S1, B, S2, __xml_attributes, __validated)
end

function _init_A(o::TestComplexType3)
    child = XmlStructLoader.lazy_child_with_name(o._node, "A", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestComplexType3Types.A, nothing), @__MODULE__, false)
end

function _init_S1(o::TestComplexType3)
    child = XmlStructLoader.lazy_child_with_name(o._node, "S1", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType2, nothing), @__MODULE__, false)
end

function _init_B(o::TestComplexType3)
    child = XmlStructLoader.lazy_child_with_name(o._node, "B", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestComplexType3Types.B, nothing), @__MODULE__, false)
end

function _init_S2(o::TestComplexType3)
    child = XmlStructLoader.lazy_child_with_name(o._node, "S2", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType2, nothing), @__MODULE__, false)
end

@doc """
Example of a complex XSD type that uses a mix of types defined under it's elements and normal types in a particular order.
""" TestComplexType3

export TestComplexType3

module TestComplexType2Types


    import AbstractXsdTypes
    using LazilyInitializedFields
    import XmlStructLoader

    using ..TestTypeInType_struct

    """
    An example of an extended simple xsd type.
    """
    Base.@kwdef struct A <: AbstractXsdTypes.AbstractXSDString
        value::TestSimpleType1
        __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
        __validated::Bool = true
    end

    """
    An example of an extended simple xsd type.
    """
    Base.@kwdef struct B <: AbstractXsdTypes.AbstractXSDString
        value::TestSimpleType2
        __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
        __validated::Bool = true
    end

end

export TestComplexType2Types

@lazy struct TestComplexType2 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy A::TestComplexType2Types.A = _init_A
    @lazy B::TestComplexType2Types.B = _init_B
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType2(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType2(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function TestComplexType2(__lazy_arg_1, __lazy_arg_2, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType2(nothing, convert(TestComplexType2Types.A, __lazy_arg_1), convert(TestComplexType2Types.B, __lazy_arg_2), __xml_attributes, __validated)
end

function TestComplexType2(; A, B, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType2(A, B, __xml_attributes, __validated)
end

function _init_A(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "A", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestComplexType2Types.A, nothing), @__MODULE__, false)
end

function _init_B(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "B", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestComplexType2Types.B, nothing), @__MODULE__, false)
end

@doc """
Example of a complex XSD type that uses types defined under it's elements and depends on a type defined later in the xsd.
""" TestComplexType2

export TestComplexType2

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
