module OptionalElements_struct

using Reexport
@reexport using Dates
@reexport using TimeZones
import AbstractXsdTypes
using LazilyInitializedFields
import XmlStructLoader

"""
An example of a simple xsd type.
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

@inline AbstractXsdTypes.get_max_value(::Type{TestSimpleType1})::Float64 = 100.0

@inline AbstractXsdTypes.is_max_exclusive(::Type{TestSimpleType1})::Bool = false

@inline AbstractXsdTypes.get_restriction_checks(::Type{TestSimpleType1}) = (
    AbstractXsdTypes.bound_restriction_check,)

export TestSimpleType1

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

module TestComplexType5Types


    import AbstractXsdTypes
    using LazilyInitializedFields
    import XmlStructLoader

    using ..OptionalElements_struct

    """
    An example of a simple xsd type.
    """
    Base.@kwdef struct Element_simple1 <: AbstractXsdTypes.AbstractXSDString
        value::String
        __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
        __validated::Bool = true
        function Element_simple1(
            value::AbstractString,
            __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
            __validated::Bool=true)
            if __validated
                AbstractXsdTypes.check_restrictions(Element_simple1, value)
            end
            return new(value, __xml_attributes, __validated)
        end
    end

    """
    An example of a simple xsd type.
    """
    Base.@kwdef struct Element_simple2 <: AbstractXsdTypes.AbstractXSDString
        value::String
        __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
        __validated::Bool = true
        function Element_simple2(
            value::AbstractString,
            __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
            __validated::Bool=true)
            if __validated
                AbstractXsdTypes.check_restrictions(Element_simple2, value)
            end
            return new(value, __xml_attributes, __validated)
        end
    end

end

export TestComplexType5Types

@lazy struct TestComplexType5 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_simple1::Union{Nothing, TestComplexType5Types.Element_simple1} = _init_Element_simple1
    @lazy Element_simple2::Union{Nothing, TestComplexType5Types.Element_simple2} = _init_Element_simple2
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

AbstractXsdTypes.defaults(::Type{TestComplexType5}) = (Element_simple2 = TestComplexType5Types.Element_simple2("file.ext"), )

function TestComplexType5(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType5(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, attribs, false)
end

function TestComplexType5(__lazy_arg_1, __lazy_arg_2, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType5(nothing, convert(Union{Nothing, TestComplexType5Types.Element_simple1}, __lazy_arg_1), convert(Union{Nothing, TestComplexType5Types.Element_simple2}, __lazy_arg_2), __xml_attributes, __validated)
end

function TestComplexType5(; Element_simple1 = nothing, Element_simple2 = nothing, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType5(Element_simple1, Element_simple2, __xml_attributes, __validated)
end

function _init_Element_simple1(o::TestComplexType5)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_simple1", true)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestComplexType5Types.Element_simple1, parent_node), @__MODULE__, false)
end

function _init_Element_simple2(o::TestComplexType5)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_simple2", true)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestComplexType5Types.Element_simple2, parent_node), @__MODULE__, false)
end

@doc """
An example of a complex xsd type with an optional element with a type defined inside.
""" TestComplexType5

export TestComplexType5

@lazy struct TestComplexType6 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_simple1::Union{Nothing, Union{ZonedDateTime, DateTime}} = _init_Element_simple1
    @lazy Element_simple2::Union{Nothing, Union{ZonedDateTime, DateTime}} = _init_Element_simple2
    @lazy Element_simple3::Union{ZonedDateTime, DateTime} = _init_Element_simple3
    @lazy Element_simple4::Union{Nothing, Union{ZonedDateTime, DateTime}} = _init_Element_simple4
    @lazy Element_simple5::Union{Nothing, Union{ZonedDateTime, DateTime}} = _init_Element_simple5
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

AbstractXsdTypes.defaults(::Type{TestComplexType6}) = (Element_simple1 = ZonedDateTime("0001-01-01T00:00:00+00:00", "yyyy-mm-ddTHH:MM:SSzzzzzz"), Element_simple3 = DateTime("0001-02-03T04:05:06.666"), Element_simple4 = ZonedDateTime("0999-08-07T06:55:44-03:22", "yyyy-mm-ddTHH:MM:SSzzzzzz"), Element_simple5 = ZonedDateTime("0004-05-06T07:08:09Z", "yyyy-mm-ddTHH:MM:SSzzzzzz"), )

function TestComplexType6(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType6(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, attribs, false)
end

function TestComplexType6(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __lazy_arg_5, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType6(nothing, convert(Union{Nothing, Union{ZonedDateTime, DateTime}}, __lazy_arg_1), convert(Union{Nothing, Union{ZonedDateTime, DateTime}}, __lazy_arg_2), convert(Union{ZonedDateTime, DateTime}, __lazy_arg_3), convert(Union{Nothing, Union{ZonedDateTime, DateTime}}, __lazy_arg_4), convert(Union{Nothing, Union{ZonedDateTime, DateTime}}, __lazy_arg_5), __xml_attributes, __validated)
end

function TestComplexType6(; Element_simple1 = nothing, Element_simple2 = nothing, Element_simple3, Element_simple4 = nothing, Element_simple5 = nothing, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType6(Element_simple1, Element_simple2, Element_simple3, Element_simple4, Element_simple5, __xml_attributes, __validated)
end

function _init_Element_simple1(o::TestComplexType6)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_simple1", true)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Union{ZonedDateTime, DateTime}, @__MODULE__, false, ZonedDateTime("0001-01-01T00:00:00+00:00", "yyyy-mm-ddTHH:MM:SSzzzzzz"))
end

function _init_Element_simple2(o::TestComplexType6)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_simple2", true)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Union{ZonedDateTime, DateTime}, @__MODULE__, false, nothing)
end

function _init_Element_simple3(o::TestComplexType6)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_simple3", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Union{ZonedDateTime, DateTime}, @__MODULE__, false, DateTime("0001-02-03T04:05:06.666"))
end

function _init_Element_simple4(o::TestComplexType6)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_simple4", true)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Union{ZonedDateTime, DateTime}, @__MODULE__, false, ZonedDateTime("0999-08-07T06:55:44-03:22", "yyyy-mm-ddTHH:MM:SSzzzzzz"))
end

function _init_Element_simple5(o::TestComplexType6)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_simple5", true)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Union{ZonedDateTime, DateTime}, @__MODULE__, false, ZonedDateTime("0004-05-06T07:08:09Z", "yyyy-mm-ddTHH:MM:SSzzzzzz"))
end

@doc """
An example of a complex xsd type with optional dateTime elements.
""" TestComplexType6

export TestComplexType6

@lazy struct TestComplexType1 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_string::Union{Nothing, String} = _init_Element_string
    @lazy Element_double::Float64 = _init_Element_double
    @lazy Element_simple1::Union{Nothing, TestSimpleType1} = _init_Element_simple1
    @lazy Element_simple2::Union{Nothing, TestSimpleType2} = _init_Element_simple2
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType1(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType1(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, attribs, false)
end

function TestComplexType1(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(nothing, convert(Union{Nothing, String}, __lazy_arg_1), convert(Float64, __lazy_arg_2), convert(Union{Nothing, TestSimpleType1}, __lazy_arg_3), convert(Union{Nothing, TestSimpleType2}, __lazy_arg_4), __xml_attributes, __validated)
end

function TestComplexType1(; Element_string = nothing, Element_double, Element_simple1 = nothing, Element_simple2 = nothing, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType1(Element_string, Element_double, Element_simple1, Element_simple2, __xml_attributes, __validated)
end

function _init_Element_string(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_string", true)
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

function _init_Element_simple1(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_simple1", true)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType1, parent_node), @__MODULE__, false)
end

function _init_Element_simple2(o::TestComplexType1)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_simple2", true)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType2, parent_node), @__MODULE__, false)
end

@doc """
An example of a complex xsd type with an optional element without default value.
""" TestComplexType1

export TestComplexType1

@lazy struct TestComplexType2 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_string::String = _init_Element_string
    @lazy Element_double::Float64 = _init_Element_double
    @lazy Element_simple1::Union{Nothing, TestSimpleType1} = _init_Element_simple1
    @lazy Element_simple2::Union{Nothing, TestSimpleType2} = _init_Element_simple2
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

AbstractXsdTypes.defaults(::Type{TestComplexType2}) = (Element_string = String("aaa"), Element_double = Float64(55.2), Element_simple1 = TestSimpleType1(0), Element_simple2 = TestSimpleType2("AAAA"), )

function TestComplexType2(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType2(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, attribs, false)
end

function TestComplexType2(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType2(nothing, convert(String, __lazy_arg_1), convert(Float64, __lazy_arg_2), convert(Union{Nothing, TestSimpleType1}, __lazy_arg_3), convert(Union{Nothing, TestSimpleType2}, __lazy_arg_4), __xml_attributes, __validated)
end

function TestComplexType2(; Element_string, Element_double, Element_simple1 = nothing, Element_simple2 = nothing, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType2(Element_string, Element_double, Element_simple1, Element_simple2, __xml_attributes, __validated)
end

function _init_Element_string(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_string", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, "aaa")
end

function _init_Element_double(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_double", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Float64, @__MODULE__, false, 55.2)
end

function _init_Element_simple1(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_simple1", true)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType1, parent_node), @__MODULE__, false)
end

function _init_Element_simple2(o::TestComplexType2)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_simple2", true)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType2, parent_node), @__MODULE__, false)
end

@doc """
An example of a complex xsd type with an optional elements with default values.
""" TestComplexType2

export TestComplexType2

@lazy struct TestComplexType3 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_simple1::Union{Nothing, Vector{TestSimpleType1}} = _init_Element_simple1
    @lazy Element_simple2::Union{Nothing, Vector{TestSimpleType2}} = _init_Element_simple2
    @lazy Element_simple2_or_nothing::Union{Nothing, Vector{TestSimpleType2}} = _init_Element_simple2_or_nothing
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

AbstractXsdTypes.defaults(::Type{TestComplexType3}) = (Element_simple1 = TestSimpleType1(0), Element_simple2 = TestSimpleType2("AAAA"), )

function TestComplexType3(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType3(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, attribs, false)
end

function TestComplexType3(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType3(nothing, convert(Union{Nothing, Vector{TestSimpleType1}}, __lazy_arg_1), convert(Union{Nothing, Vector{TestSimpleType2}}, __lazy_arg_2), convert(Union{Nothing, Vector{TestSimpleType2}}, __lazy_arg_3), __xml_attributes, __validated)
end

function TestComplexType3(; Element_simple1 = nothing, Element_simple2 = nothing, Element_simple2_or_nothing = nothing, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType3(Element_simple1, Element_simple2, Element_simple2_or_nothing, __xml_attributes, __validated)
end

function _init_Element_simple1(o::TestComplexType3)
    matched = TestSimpleType1[(let owner = child.owner, parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o)); GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType1, parent_node), @__MODULE__, false); end) for child in XmlStructLoader.lazy_children_with_name(o._node, "Element_simple1")]
    return isempty(matched) ? nothing : matched
end

function _init_Element_simple2(o::TestComplexType3)
    matched = TestSimpleType2[(let owner = child.owner, parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o)); GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType2, parent_node), @__MODULE__, false); end) for child in XmlStructLoader.lazy_children_with_name(o._node, "Element_simple2")]
    return isempty(matched) ? nothing : matched
end

function _init_Element_simple2_or_nothing(o::TestComplexType3)
    matched = TestSimpleType2[(let owner = child.owner, parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o)); GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType2, parent_node), @__MODULE__, false); end) for child in XmlStructLoader.lazy_children_with_name(o._node, "Element_simple2_or_nothing")]
    return isempty(matched) ? nothing : matched
end

@doc """
An example of a complex xsd type with vector optional elements and default values.
""" TestComplexType3

export TestComplexType3

@lazy struct TestComplexType4_element <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_simple1_1::Union{Nothing, TestSimpleType1} = _init_Element_simple1_1
    @lazy Element_simple1_2::Union{Nothing, TestSimpleType1} = _init_Element_simple1_2
    @lazy Element_simple2_1::Union{Nothing, TestSimpleType2} = _init_Element_simple2_1
    @lazy Element_simple2_2::Union{Nothing, TestSimpleType2} = _init_Element_simple2_2
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

AbstractXsdTypes.defaults(::Type{TestComplexType4_element}) = (Element_simple1_2 = TestSimpleType1(50), Element_simple2_2 = TestSimpleType2("A4A4"), )

function TestComplexType4_element(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType4_element(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, attribs, false)
end

function TestComplexType4_element(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType4_element(nothing, convert(Union{Nothing, TestSimpleType1}, __lazy_arg_1), convert(Union{Nothing, TestSimpleType1}, __lazy_arg_2), convert(Union{Nothing, TestSimpleType2}, __lazy_arg_3), convert(Union{Nothing, TestSimpleType2}, __lazy_arg_4), __xml_attributes, __validated)
end

function TestComplexType4_element(; Element_simple1_1 = nothing, Element_simple1_2 = nothing, Element_simple2_1 = nothing, Element_simple2_2 = nothing, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType4_element(Element_simple1_1, Element_simple1_2, Element_simple2_1, Element_simple2_2, __xml_attributes, __validated)
end

function _init_Element_simple1_1(o::TestComplexType4_element)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_simple1_1", true)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType1, parent_node), @__MODULE__, false)
end

function _init_Element_simple1_2(o::TestComplexType4_element)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_simple1_2", true)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType1, parent_node), @__MODULE__, false)
end

function _init_Element_simple2_1(o::TestComplexType4_element)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_simple2_1", true)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType2, parent_node), @__MODULE__, false)
end

function _init_Element_simple2_2(o::TestComplexType4_element)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Element_simple2_2", true)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, TestSimpleType2, parent_node), @__MODULE__, false)
end

@doc """
An example of a complex xsd type with optional simple elements.
""" TestComplexType4_element

export TestComplexType4_element

@lazy struct TestComplexType4 <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Element_complex4::Union{Nothing, Vector{TestComplexType4_element}} = _init_Element_complex4
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function TestComplexType4(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return TestComplexType4(node, LazilyInitializedFields.uninit, attribs, false)
end

function TestComplexType4(__lazy_arg_1, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType4(nothing, convert(Union{Nothing, Vector{TestComplexType4_element}}, __lazy_arg_1), __xml_attributes, __validated)
end

function TestComplexType4(; Element_complex4 = nothing, __xml_attributes = nothing, __validated::Bool = true)
    return TestComplexType4(Element_complex4, __xml_attributes, __validated)
end

function _init_Element_complex4(o::TestComplexType4)
    matched = TestComplexType4_element[TestComplexType4_element(child) for child in XmlStructLoader.lazy_children_with_name(o._node, "Element_complex4")]
    return isempty(matched) ? nothing : matched
end

@doc """
An example of a complex xsd type with complex optional values.
""" TestComplexType4

export TestComplexType4

@lazy struct documentType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy TestElement1::TestComplexType1 = _init_TestElement1
    @lazy TestElement2::TestComplexType2 = _init_TestElement2
    @lazy TestElement3::TestComplexType3 = _init_TestElement3
    @lazy TestElement4::TestComplexType4 = _init_TestElement4
    @lazy TestElement5::TestComplexType5 = _init_TestElement5
    @lazy TestElement6::TestComplexType6 = _init_TestElement6
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function documentType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return documentType(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, attribs, false)
end

function documentType(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __lazy_arg_5, __lazy_arg_6, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(nothing, convert(TestComplexType1, __lazy_arg_1), convert(TestComplexType2, __lazy_arg_2), convert(TestComplexType3, __lazy_arg_3), convert(TestComplexType4, __lazy_arg_4), convert(TestComplexType5, __lazy_arg_5), convert(TestComplexType6, __lazy_arg_6), __xml_attributes, __validated)
end

function documentType(; TestElement1, TestElement2, TestElement3, TestElement4, TestElement5, TestElement6, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(TestElement1, TestElement2, TestElement3, TestElement4, TestElement5, TestElement6, __xml_attributes, __validated)
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

function _init_TestElement4(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement4", false)
    isnothing(child) && return nothing
    return TestComplexType4(child)
end

function _init_TestElement5(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement5", false)
    isnothing(child) && return nothing
    return TestComplexType5(child)
end

function _init_TestElement6(o::documentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "TestElement6", false)
    isnothing(child) && return nothing
    return TestComplexType6(child)
end

export documentType

end
