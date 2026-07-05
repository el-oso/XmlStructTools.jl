module DocumentationExample_struct

import AbstractXsdTypes
using LazilyInitializedFields
import XmlStructLoader

@lazy struct AddressType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy street::String = _init_street
    @lazy city::String = _init_city
    @lazy state::String = _init_state
    @lazy postalCode::Float64 = _init_postalCode
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function AddressType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return AddressType(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function AddressType(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __lazy_arg_4, __xml_attributes = nothing, __validated::Bool = true)
    return AddressType(nothing, convert(String, __lazy_arg_1), convert(String, __lazy_arg_2), convert(String, __lazy_arg_3), convert(Float64, __lazy_arg_4), __xml_attributes, __validated)
end

function AddressType(; street, city, state, postalCode, __xml_attributes = nothing, __validated::Bool = true)
    return AddressType(street, city, state, postalCode, __xml_attributes, __validated)
end

function _init_street(o::AddressType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "street", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, nothing)
end

function _init_city(o::AddressType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "city", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, nothing)
end

function _init_state(o::AddressType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "state", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, nothing)
end

function _init_postalCode(o::AddressType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "postalCode", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Float64, @__MODULE__, false, nothing)
end

export AddressType

@lazy struct OwnerType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy name::String = _init_name
    @lazy address::AddressType = _init_address
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function OwnerType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return OwnerType(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function OwnerType(__lazy_arg_1, __lazy_arg_2, __xml_attributes = nothing, __validated::Bool = true)
    return OwnerType(nothing, convert(String, __lazy_arg_1), convert(AddressType, __lazy_arg_2), __xml_attributes, __validated)
end

function OwnerType(; name, address, __xml_attributes = nothing, __validated::Bool = true)
    return OwnerType(name, address, __xml_attributes, __validated)
end

function _init_name(o::OwnerType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "name", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, nothing)
end

function _init_address(o::OwnerType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "address", false)
    isnothing(child) && return nothing
    return AddressType(child)
end

export OwnerType

@lazy struct overallPropertiesType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy totalArea::Float64 = _init_totalArea
    @lazy livableArea::Float64 = _init_livableArea
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function overallPropertiesType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return overallPropertiesType(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function overallPropertiesType(__lazy_arg_1, __lazy_arg_2, __xml_attributes = nothing, __validated::Bool = true)
    return overallPropertiesType(nothing, convert(Float64, __lazy_arg_1), convert(Float64, __lazy_arg_2), __xml_attributes, __validated)
end

function overallPropertiesType(; totalArea, livableArea, __xml_attributes = nothing, __validated::Bool = true)
    return overallPropertiesType(totalArea, livableArea, __xml_attributes, __validated)
end

function _init_totalArea(o::overallPropertiesType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "totalArea", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Float64, @__MODULE__, false, nothing)
end

function _init_livableArea(o::overallPropertiesType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "livableArea", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Float64, @__MODULE__, false, nothing)
end

export overallPropertiesType

@lazy struct roomType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy name::String = _init_name
    @lazy area::Float64 = _init_area
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function roomType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return roomType(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function roomType(__lazy_arg_1, __lazy_arg_2, __xml_attributes = nothing, __validated::Bool = true)
    return roomType(nothing, convert(String, __lazy_arg_1), convert(Float64, __lazy_arg_2), __xml_attributes, __validated)
end

function roomType(; name, area, __xml_attributes = nothing, __validated::Bool = true)
    return roomType(name, area, __xml_attributes, __validated)
end

function _init_name(o::roomType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "name", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, String, @__MODULE__, false, nothing)
end

function _init_area(o::roomType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "area", false)
    isnothing(child) && return nothing
    owner = child.owner
    return GC.@preserve owner XmlStructLoader.parse_xml_node_not_module(child.ptr, Float64, @__MODULE__, false, nothing)
end

export roomType

@lazy struct HouseDescriptionType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy overallProperties::overallPropertiesType = _init_overallProperties
    @lazy room::Vector{roomType} = _init_room
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function HouseDescriptionType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return HouseDescriptionType(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function HouseDescriptionType(__lazy_arg_1, __lazy_arg_2, __xml_attributes = nothing, __validated::Bool = true)
    return HouseDescriptionType(nothing, convert(overallPropertiesType, __lazy_arg_1), convert(Vector{roomType}, __lazy_arg_2), __xml_attributes, __validated)
end

function HouseDescriptionType(; overallProperties, room, __xml_attributes = nothing, __validated::Bool = true)
    return HouseDescriptionType(overallProperties, room, __xml_attributes, __validated)
end

function _init_overallProperties(o::HouseDescriptionType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "overallProperties", false)
    isnothing(child) && return nothing
    return overallPropertiesType(child)
end

function _init_room(o::HouseDescriptionType)
    return [roomType(child) for child in XmlStructLoader.lazy_children_with_name(o._node, "room")]
end

export HouseDescriptionType

@lazy struct HouseDescriptionDocumentType <: AbstractXsdTypes.AbstractXSDComplex
    _node::Union{Nothing, XmlStructLoader.LazyNode}
    @lazy address::AddressType = _init_address
    @lazy owner::OwnerType = _init_owner
    @lazy houseDescription::HouseDescriptionType = _init_houseDescription
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
end

function HouseDescriptionDocumentType(node::XmlStructLoader.LazyNode)
    attribs = XmlStructLoader.lazy_attributes_dict(node)
    return HouseDescriptionDocumentType(node, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, LazilyInitializedFields.uninit, isempty(attribs) ? nothing : attribs, false)
end

function HouseDescriptionDocumentType(__lazy_arg_1, __lazy_arg_2, __lazy_arg_3, __xml_attributes = nothing, __validated::Bool = true)
    return HouseDescriptionDocumentType(nothing, convert(AddressType, __lazy_arg_1), convert(OwnerType, __lazy_arg_2), convert(HouseDescriptionType, __lazy_arg_3), __xml_attributes, __validated)
end

function HouseDescriptionDocumentType(; address, owner, houseDescription, __xml_attributes = nothing, __validated::Bool = true)
    return HouseDescriptionDocumentType(address, owner, houseDescription, __xml_attributes, __validated)
end

function _init_address(o::HouseDescriptionDocumentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "address", false)
    isnothing(child) && return nothing
    return AddressType(child)
end

function _init_owner(o::HouseDescriptionDocumentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "owner", false)
    isnothing(child) && return nothing
    return OwnerType(child)
end

function _init_houseDescription(o::HouseDescriptionDocumentType)
    child = XmlStructLoader.lazy_child_with_name(o._node, "houseDescription", false)
    isnothing(child) && return nothing
    return HouseDescriptionType(child)
end

export HouseDescriptionDocumentType

end
