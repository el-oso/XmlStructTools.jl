#! format: off

include("xsd_module_builder_simple_restrictions.jl")

function write_node_specific(
	xsd_node::SimpleTreeNode,
	xsd_module_builder::XSDStructModuleBuilderType,
	indent_level::Int = 1,
)::Bool

	@debug "Writing as $(SimpleTreeNode)"

	write_docstring(xsd_node, xsd_module_builder, indent_level)

	super_type = get_simple_node_super_type(xsd_node.field.julia_type, xsd_module_builder)

	writeln(
		xsd_module_builder,
		IOStruct,
		struct_line_string(name(xsd_node), super_type),
		indent_level = indent_level)

	if xsd_node.field.julia_type == "String"
		writeln(
			xsd_module_builder, IOStruct, "value::$(xsd_node.field.julia_type)", indent_level = indent_level + 1)
	else
		writeln(
			xsd_module_builder, IOStruct, "value::$(xsd_node.field.julia_type)", indent_level = indent_level + 1)
	end

	writeln(xsd_module_builder, IOStruct,
		"__xml_attributes::Union{Nothing, Dict{String, String}} = nothing"; indent_level = indent_level + 1)
	writeln(xsd_module_builder, IOStruct,
		"__validated::Bool = true"; indent_level = indent_level + 1)

    has_restrictions = !isnothing(xsd_node.restrictions) && !isempty(xsd_node.restrictions) || !isempty(xsd_node.enumeration)

	if has_restrictions
		write_inner_constructor(xsd_node, xsd_module_builder; indent_level = indent_level + 1)
	end

	write(xsd_module_builder, IOStruct, "end\n\n", indent_level = indent_level)

	if has_restrictions
		write_restriction_functions(xsd_node, xsd_module_builder; indent_level = indent_level)
	end

	if super_type == AbstractString
		print_string_methods(xsd_module_builder, name(xsd_node), indent_level = indent_level)
	end

	push!(xsd_module_builder.defined_nodes, xsd_node)

	return true
end

const xsd_abstract_type_map = Dict((
	AbstractFloat => "$ABSTRACT_TYPE_PACKAGE.AbstractXSDFloat",
	Signed => "$ABSTRACT_TYPE_PACKAGE.AbstractXSDSigned",
	Unsigned => "$ABSTRACT_TYPE_PACKAGE.AbstractXSDUnsigned",
	AbstractString => "$ABSTRACT_TYPE_PACKAGE.AbstractXSDString",
	Dates.AbstractDateTime => "$ABSTRACT_TYPE_PACKAGE.AbstractXSDDateTime",
	Dates.TimeType => "$ABSTRACT_TYPE_PACKAGE.AbstractXSDDate"))

# `Date` and `Time` share `Dates.TimeType` as their supertype, so which abstract XSD type a
# simple type belongs to cannot be read off the supertype alone.
const xsd_abstract_type_by_julia_type = Dict((
	"Date" => "$ABSTRACT_TYPE_PACKAGE.AbstractXSDDate",
	"Time" => "$ABSTRACT_TYPE_PACKAGE.AbstractXSDTime",
	"Vector{UInt8}" => "$ABSTRACT_TYPE_PACKAGE.AbstractXSDBinary",
	"Dates.CompoundPeriod" => "$ABSTRACT_TYPE_PACKAGE.AbstractXSDDuration"))

function get_supertype(type_string::AbstractString)
	if type_string == "Union{DateTimeNs{ZonedDateTime}, DateTimeNs{DateTime}}"
		supertype_value = Dates.AbstractDateTime
	elseif type_string == "Vector{UInt8}"
		supertype_value = DenseVector{UInt8}
	elseif type_string == "Dates.CompoundPeriod"
		supertype_value = Dates.AbstractTime
	else
		supertype_value = supertype(eval(Symbol(type_string)))
	end
	return supertype_value
end

const built_in_super_types = Dict(val => get_supertype(val) for val in values(built_in_data_type_dict))

function get_simple_node_super_type(type_name::AbstractString, xsd_module_builder::XSDStructModuleBuilderType)::String
	built_in_type = built_in_julia_type(type_name, xsd_module_builder)
	haskey(xsd_abstract_type_by_julia_type, built_in_type) && return xsd_abstract_type_by_julia_type[built_in_type]
	return xsd_abstract_type_map[built_in_super_types[built_in_type]]
end

# The built-in Julia type a simple type with value type `julia_type_string` derives from.
function built_in_julia_type(julia_type_string::AbstractString, xsd_module_builder::XSDStructModuleBuilderType)::String
	julia_type_string in values(built_in_data_type_dict) && return julia_type_string
	simple_nodes = get_defined_simple_nodes(xsd_module_builder)
	index = findfirst(x -> name(x) == julia_type_string, simple_nodes)
	isnothing(index) && throw(
		ArgumentError("$julia_type_string is neither a built-in type nor a simple type defined in this schema"))
	return built_in_julia_type(simple_nodes[index].field.julia_type, xsd_module_builder)
end

function print_string_methods(
	xsd_module_builder::XSDStructModuleBuilderType, type_name::AbstractString; indent_level::Int)

	writeln(
		xsd_module_builder,
		IOStruct,
		"Base.ncodeunits(s::$(type_name)) = ncodeunits(s.value)",
		indent_level = indent_level)
	writeln(
		xsd_module_builder,
		IOStruct,
		"Base.iterate(s::$(type_name), i::Integer) = iterate(s.value, i)",
		indent_level = indent_level)
	writeln(
		xsd_module_builder,
		IOStruct,
		"Base.iterate(s::$(type_name)) = iterate(s.value)",
		indent_level = indent_level)

	write(xsd_module_builder, IOStruct, "\n", indent_level = indent_level)

end

# Qualified, so that a schema type with the same name, such as `Number`, does not shadow them.
const JULIA_SUPER_TYPES = Dict(
    "String" => "Base.AbstractString",
    "Float64" => "Base.Number",
    "Bool" => "Base.Bool",
    "Union{DateTimeNs{ZonedDateTime}, DateTimeNs{DateTime}}" => "Dates.AbstractDateTime",
    "Int64" => "Base.Number",
    "UInt64" => "Base.Number",
    "Float32" => "Base.Number",
    "Int32" => "Base.Number",
    "Int16" => "Base.Number",
    "Int8" => "Base.Number",
    "UInt32" => "Base.Number",
    "UInt16" => "Base.Number",
    "UInt8" => "Base.Number",
    "AbstractXsdTypes.AbstractXSDString" => "Base.AbstractString",
    "AbstractXsdTypes.AbstractXSDFloat" => "Base.Number",
    "AbstractXsdTypes.AbstractXSDSigned" => "Base.Number",
    "AbstractXsdTypes.AbstractXSDUnsigned" => "Base.Number",
    "Date" => "Dates.TimeType",
    "Time" => "Dates.TimeType",
    "AbstractXsdTypes.AbstractXSDDate" => "Dates.TimeType",
    "AbstractXsdTypes.AbstractXSDDateTime" => "Dates.AbstractDateTime",
    "AbstractXsdTypes.AbstractXSDTime" => "Dates.TimeType",
    "Vector{UInt8}" => "Base.AbstractVector{UInt8}",
    "AbstractXsdTypes.AbstractXSDBinary" => "Base.AbstractVector{UInt8}",
    # A single period such as `Day(1)` converts to the field's `Dates.CompoundPeriod`.
    "Dates.CompoundPeriod" => "Union{Dates.Period, Dates.CompoundPeriod}",
    # A type restricting another restricted duration type is given a value of that type.
    "AbstractXsdTypes.AbstractXSDDuration" => "Union{Dates.Period, Dates.CompoundPeriod, AbstractXsdTypes.AbstractXSDDuration}",
)
function write_inner_constructor(
	xsd_node::SimpleTreeNode,
	xsd_module_builder::XSDStructModuleBuilderType;
	indent_level::Int = 1,
)::Nothing

	struct_name = name(xsd_node)
    julia_type_string = xsd_node.field.julia_type
    if haskey(JULIA_SUPER_TYPES, julia_type_string)
        super_type = JULIA_SUPER_TYPES[julia_type_string]
    else
        xsd_super_type = get_simple_node_super_type(julia_type_string, xsd_module_builder)
        super_type = JULIA_SUPER_TYPES[xsd_super_type]
    end

	inner_constructor_string = """
function $struct_name(
    value::$super_type,
    __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
    __validated::Bool=true)
    if __validated
        AbstractXsdTypes.check_restrictions($struct_name, value)
    end
    return new(value, __xml_attributes, __validated)
end
"""

	write(
		xsd_module_builder,
		IOStruct,
		inner_constructor_string,
		indent_level = indent_level)

	return nothing
end
