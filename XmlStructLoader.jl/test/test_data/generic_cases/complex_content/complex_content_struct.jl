module TestComplexContent_struct

using Reexport
@reexport using Dates
@reexport using TimeZones
import AbstractXsdTypes
using LazilyInitializedFields
import XmlStructLoader

Base.@kwdef struct SimpleType1 <: AbstractXsdTypes.AbstractXSDFloat
    value::Float64
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
end

export SimpleType1

module TestComplexType1Types


    import AbstractXsdTypes
    using LazilyInitializedFields
    import XmlStructLoader

    using ..TestComplexContent_struct

    Base.@kwdef struct Element_empty <: AbstractXsdTypes.AbstractXSDComplex
        __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
        __validated::Bool = true
    end

end

export TestComplexType1Types

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
    @lazy Element_empty::Union{Nothing, TestComplexType1Types.Element_empty} = _init_Element_empty
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType1(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType1(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function TestComplexType1(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __lazy_arg_5, __lazy_arg_6, __lazy_arg_7, __lazy_arg_8, __lazy_arg_9, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(nothing, convert(String, __lazy_arg_1), convert(Float64, __lazy_arg_2), convert(Bool, __lazy_arg_3), convert(Float64, __lazy_arg_4), convert(Union{ZonedDateTime, DateTime}, __lazy_arg_5), convert(Int64, __lazy_arg_6), convert(UInt64, __lazy_arg_7), convert(UInt64, __lazy_arg_8), convert(Union{Nothing, TestComplexType1Types.Element_empty}, __lazy_arg_9), __xml_attributes, __validated)
end

function TestComplexType1(; Element_string, Element_double, Element_boolean, Element_decimal, Element_dateTime, Element_integer, Element_nonNegativeInteger, Element_positiveInteger, Element_empty = nothing, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(Element_string, Element_double, Element_boolean, Element_decimal, Element_dateTime, Element_integer, Element_nonNegativeInteger, Element_positiveInteger, Element_empty, __xml_attributes, __validated)
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

function _init_Element_empty(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_empty", true)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestComplexType1Types.Element_empty, parent_node), @__MODULE__, false)
end

@doc """
An example of a complex xsd type.
""" TestComplexType1

export TestComplexType1

@lazy struct TestComplexType2 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_string::String = _init_Element_string
    @lazy Element_double::Float64 = _init_Element_double
    @lazy Element_boolean::Bool = _init_Element_boolean
    @lazy Element_decimal::Float64 = _init_Element_decimal
    @lazy Element_dateTime::Union{ZonedDateTime, DateTime} = _init_Element_dateTime
    @lazy Element_integer::Int64 = _init_Element_integer
    @lazy Element_nonNegativeInteger::UInt64 = _init_Element_nonNegativeInteger
    @lazy Element_positiveInteger::UInt64 = _init_Element_positiveInteger
    @lazy Element_empty::Union{Nothing, TestComplexType1Types.Element_empty} = _init_Element_empty
    @lazy Element_integer_ext::Int64 = _init_Element_integer_ext
    @lazy Element_boolean_ext::Bool = _init_Element_boolean_ext
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType2(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType2(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function TestComplexType2(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __lazy_arg_5, __lazy_arg_6, __lazy_arg_7, __lazy_arg_8, __lazy_arg_9, __lazy_arg_10, __lazy_arg_11, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType2(nothing, convert(String, __lazy_arg_1), convert(Float64, __lazy_arg_2), convert(Bool, __lazy_arg_3), convert(Float64, __lazy_arg_4), convert(Union{ZonedDateTime, DateTime}, __lazy_arg_5), convert(Int64, __lazy_arg_6), convert(UInt64, __lazy_arg_7), convert(UInt64, __lazy_arg_8), convert(Union{Nothing, TestComplexType1Types.Element_empty}, __lazy_arg_9), convert(Int64, __lazy_arg_10), convert(Bool, __lazy_arg_11), __xml_attributes, __validated)
end

function TestComplexType2(; Element_string, Element_double, Element_boolean, Element_decimal, Element_dateTime, Element_integer, Element_nonNegativeInteger, Element_positiveInteger, Element_empty = nothing, Element_integer_ext, Element_boolean_ext, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType2(Element_string, Element_double, Element_boolean, Element_decimal, Element_dateTime, Element_integer, Element_nonNegativeInteger, Element_positiveInteger, Element_empty, Element_integer_ext, Element_boolean_ext, __xml_attributes, __validated)
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

function _init_Element_decimal(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_decimal", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Float64, @__MODULE__, false, nothing)
end

function _init_Element_dateTime(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_dateTime", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Union{ZonedDateTime, DateTime}, @__MODULE__, false, nothing)
end

function _init_Element_integer(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_integer", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Int64, @__MODULE__, false, nothing)
end

function _init_Element_nonNegativeInteger(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_nonNegativeInteger", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, UInt64, @__MODULE__, false, nothing)
end

function _init_Element_positiveInteger(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_positiveInteger", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, UInt64, @__MODULE__, false, nothing)
end

function _init_Element_empty(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_empty", true)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestComplexType1Types.Element_empty, parent_node), @__MODULE__, false)
end

function _init_Element_integer_ext(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_integer_ext", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Int64, @__MODULE__, false, nothing)
end

function _init_Element_boolean_ext(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_boolean_ext", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Bool, @__MODULE__, false, nothing)
end

@doc """
An example of a complex xsd type with complex content.
""" TestComplexType2

export TestComplexType2

@lazy struct TestComplexType3 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_string::String = _init_Element_string
    @lazy Element_double::Float64 = _init_Element_double
    @lazy Element_boolean::Bool = _init_Element_boolean
    @lazy Element_decimal::Float64 = _init_Element_decimal
    @lazy Element_dateTime::Union{ZonedDateTime, DateTime} = _init_Element_dateTime
    @lazy Element_integer::Int64 = _init_Element_integer
    @lazy Element_nonNegativeInteger::UInt64 = _init_Element_nonNegativeInteger
    @lazy Element_positiveInteger::UInt64 = _init_Element_positiveInteger
    @lazy Element_empty::Union{Nothing, TestComplexType1Types.Element_empty} = _init_Element_empty
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType3(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType3(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function TestComplexType3(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __lazy_arg_5, __lazy_arg_6, __lazy_arg_7, __lazy_arg_8, __lazy_arg_9, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType3(nothing, convert(String, __lazy_arg_1), convert(Float64, __lazy_arg_2), convert(Bool, __lazy_arg_3), convert(Float64, __lazy_arg_4), convert(Union{ZonedDateTime, DateTime}, __lazy_arg_5), convert(Int64, __lazy_arg_6), convert(UInt64, __lazy_arg_7), convert(UInt64, __lazy_arg_8), convert(Union{Nothing, TestComplexType1Types.Element_empty}, __lazy_arg_9), __xml_attributes, __validated)
end

function TestComplexType3(; Element_string, Element_double, Element_boolean, Element_decimal, Element_dateTime, Element_integer, Element_nonNegativeInteger, Element_positiveInteger, Element_empty = nothing, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType3(Element_string, Element_double, Element_boolean, Element_decimal, Element_dateTime, Element_integer, Element_nonNegativeInteger, Element_positiveInteger, Element_empty, __xml_attributes, __validated)
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

function _init_Element_decimal(o::TestComplexType3)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_decimal", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Float64, @__MODULE__, false, nothing)
end

function _init_Element_dateTime(o::TestComplexType3)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_dateTime", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Union{ZonedDateTime, DateTime}, @__MODULE__, false, nothing)
end

function _init_Element_integer(o::TestComplexType3)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_integer", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Int64, @__MODULE__, false, nothing)
end

function _init_Element_nonNegativeInteger(o::TestComplexType3)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_nonNegativeInteger", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, UInt64, @__MODULE__, false, nothing)
end

function _init_Element_positiveInteger(o::TestComplexType3)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_positiveInteger", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, UInt64, @__MODULE__, false, nothing)
end

function _init_Element_empty(o::TestComplexType3)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_empty", true)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestComplexType1Types.Element_empty, parent_node), @__MODULE__, false)
end

@doc """
An example of a complex xsd type with complex content.
""" TestComplexType3

export TestComplexType3

module TestComplexType4Types


    import AbstractXsdTypes
    using LazilyInitializedFields
    import XmlStructLoader

    using ..TestComplexContent_struct

    Base.@kwdef struct simple1 <: AbstractXsdTypes.AbstractXSDFloat
        value::SimpleType1
        __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
        __validated::Bool = true
    end

end

export TestComplexType4Types

@lazy struct TestComplexType4 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy simple1::TestComplexType4Types.simple1 = _init_simple1
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

AbstractXsdTypes.defaults(::Type{TestComplexType4}) = (simple1 = TestComplexType4Types.simple1(0.0), )

function TestComplexType4(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType4(node, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function TestComplexType4(__lazy_arg_1, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType4(nothing, convert(TestComplexType4Types.simple1, __lazy_arg_1), __xml_attributes, __validated)
end

function TestComplexType4(; simple1, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType4(simple1, __xml_attributes, __validated)
end

function _init_simple1(o::TestComplexType4)
    child = XmlStructLoader.lazy_child_with_name(o._node, "simple1", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestComplexType4Types.simple1, parent_node), @__MODULE__, false)
end

export TestComplexType4

@lazy struct TestComplexType5 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy simple1::TestComplexType4Types.simple1 = _init_simple1
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

AbstractXsdTypes.defaults(::Type{TestComplexType5}) = (simple1 = TestComplexType4Types.simple1(0.0), )

function TestComplexType5(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType5(node, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function TestComplexType5(__lazy_arg_1, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType5(nothing, convert(TestComplexType4Types.simple1, __lazy_arg_1), __xml_attributes, __validated)
end

function TestComplexType5(; simple1, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType5(simple1, __xml_attributes, __validated)
end

function _init_simple1(o::TestComplexType5)
    child = XmlStructLoader.lazy_child_with_name(o._node, "simple1", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestComplexType4Types.simple1, parent_node), @__MODULE__, false)
end

export TestComplexType5

@lazy struct documentType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy TestElement2::TestComplexType2 = _init_TestElement2
    @lazy TestElement3::TestComplexType3 = _init_TestElement3
    @lazy TestElement5::TestComplexType5 = _init_TestElement5
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function documentType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return documentType(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function documentType(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(nothing, convert(TestComplexType2, __lazy_arg_1), convert(TestComplexType3, __lazy_arg_2), convert(TestComplexType5, __lazy_arg_3), __xml_attributes, __validated)
end

function documentType(; TestElement2, TestElement3, TestElement5, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(TestElement2, TestElement3, TestElement5, __xml_attributes, __validated)
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
