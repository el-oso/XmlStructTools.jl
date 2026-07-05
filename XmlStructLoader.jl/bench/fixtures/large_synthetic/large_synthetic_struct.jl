module LargeSynthetic_struct

using Reexport
@reexport using Dates
@reexport using TimeZones
import AbstractXsdTypes
using LazilyInitializedFields
import XmlStructLoader

Base.@kwdef struct CurrencyCode <: AbstractXsdTypes.AbstractXSDString
    value::String
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
    function CurrencyCode(
        value::AbstractString,
        __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
        __validated::Bool=true)
        if __validated
            AbstractXsdTypes.check_restrictions(CurrencyCode, value)
        end
        return new(value, __xml_attributes, __validated)
    end
end

export CurrencyCode

@lazy struct EntryType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy EntryId::String = _init_EntryId
    @lazy Amount::Float64 = _init_Amount
    @lazy Currency::CurrencyCode = _init_Currency
    @lazy BookingDate::Union{ZonedDateTime, DateTime} = _init_BookingDate
    @lazy CreditDebitIndicator::Bool = _init_CreditDebitIndicator
    @lazy Reference::String = _init_Reference
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function EntryType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return EntryType(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, attribs, false)
end

function EntryType(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __lazy_arg_5, __lazy_arg_6, __xml_attributes = nothing, __validated::Bool = true)
    return EntryType(nothing, convert(String, __lazy_arg_1), convert(Float64, __lazy_arg_2), convert(CurrencyCode, __lazy_arg_3), convert(Union{ZonedDateTime, DateTime}, __lazy_arg_4), convert(Bool, __lazy_arg_5), convert(String, __lazy_arg_6), __xml_attributes, __validated)
end

function EntryType(; EntryId, Amount, Currency, BookingDate, CreditDebitIndicator, Reference, __xml_attributes = nothing, __validated::Bool = true)
    return EntryType(EntryId, Amount, Currency, BookingDate, CreditDebitIndicator, Reference, __xml_attributes, __validated)
end

function _init_EntryId(o::EntryType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "EntryId", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, nothing)
end

function _init_Amount(o::EntryType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Amount", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Float64, @__MODULE__, false, nothing)
end

function _init_Currency(o::EntryType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Currency", false)
    isnothing(child) && return nothing
    owner = child.owner
    parent_node = XmlStructLoader.field_parent_node(o._node.ptr, typeof(o))
    return GC.@preserve owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, CurrencyCode, parent_node), @__MODULE__, false)
end

function _init_BookingDate(o::EntryType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "BookingDate", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Union{ZonedDateTime, DateTime}, @__MODULE__, false, nothing)
end

function _init_CreditDebitIndicator(o::EntryType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "CreditDebitIndicator", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Bool, @__MODULE__, false, nothing)
end

function _init_Reference(o::EntryType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "Reference", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, nothing)
end

@doc """
A single repeated record - the element this fixture stresses at scale.
""" EntryType

export EntryType

@lazy struct documentType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy Entry::Vector{EntryType} = _init_Entry
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function documentType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return documentType(node, LazilyInitializedFields.uninit, attribs, false)
end

function documentType(__lazy_arg_1, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(nothing, convert(Vector{EntryType}, __lazy_arg_1), __xml_attributes, __validated)
end

function documentType(; Entry, __xml_attributes = nothing, __validated::Bool = true)
    return documentType(Entry, __xml_attributes, __validated)
end

function _init_Entry(o::documentType)
    return EntryType[EntryType(child) for child in XmlStructLoader.lazy_children_with_name(o._node, "Entry")]
end

export documentType

end
