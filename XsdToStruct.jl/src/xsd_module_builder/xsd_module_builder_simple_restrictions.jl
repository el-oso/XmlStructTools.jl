#! format: off

const TOTAL_DIGITS_KEY = "totalDigits"
const FRACTION_DIGITS_KEY = "fractionDigits"
const MAX_INCLUSIVE_KEY = "maxInclusive"
const MAX_EXCLUSIVE_KEY = "maxExclusive"
const MIN_INCLUSIVE_KEY = "minInclusive"
const MIN_EXCLUSIVE_KEY = "minExclusive"

function write_restriction_functions(
	xsd_node::SimpleTreeNode,
	xsd_module_builder::XSDStructModuleBuilderType;
	indent_level::Int = 1,
)::Nothing
	restrictions_set = Set{String}()

	if haskey(xsd_node.restrictions, MAX_INCLUSIVE_KEY)
		write_max_inclusive(xsd_node, xsd_module_builder; indent_level = indent_level)
		push!(restrictions_set, "bound_restriction_check")
	elseif haskey(xsd_node.restrictions, MAX_EXCLUSIVE_KEY)
		write_max_exclusive(xsd_node, xsd_module_builder; indent_level = indent_level)
		push!(restrictions_set, "bound_restriction_check")
	end

	if haskey(xsd_node.restrictions, MIN_INCLUSIVE_KEY)
		write_min_inclusive(xsd_node, xsd_module_builder; indent_level = indent_level)
		push!(restrictions_set, "bound_restriction_check")
	elseif haskey(xsd_node.restrictions, MIN_EXCLUSIVE_KEY)
		write_min_exclusive(xsd_node, xsd_module_builder; indent_level = indent_level)
		push!(restrictions_set, "bound_restriction_check")
	end

	if haskey(xsd_node.restrictions, FRACTION_DIGITS_KEY)
		write_get_max_fraction_digits(xsd_node, xsd_module_builder; indent_level = indent_level)
		push!(restrictions_set, "fraction_digits_check")
	end

	if haskey(xsd_node.restrictions, TOTAL_DIGITS_KEY)
		write_get_max_total_digits(xsd_node, xsd_module_builder; indent_level = indent_level)
		push!(restrictions_set, "total_digits_check")
	end

	string_facets = filter(in(STRING_FACET_KEYS), collect(keys(xsd_node.restrictions)))
	if !isempty(string_facets)
		super_type = get_simple_node_super_type(xsd_node.field.julia_type, xsd_module_builder)
		if super_type == "$ABSTRACT_TYPE_PACKAGE.AbstractXSDString"
			union!(restrictions_set, write_string_facets(xsd_node, xsd_module_builder; indent_level = indent_level))
		else
			@warn "$(name(xsd_node)): $(join(sort(string_facets), ", ")) is checked only on types derived from " *
				"strings, so it is not checked here."
		end
	end

	if !isempty(xsd_node.enumeration)
		write_get_enumeration(xsd_node, xsd_module_builder; indent_level = indent_level)
		push!(restrictions_set, "enumeration_check")
	end

	restrictions_vector = collect(restrictions_set)
	if !isempty(restrictions_vector)
		write_get_restriction_checks(
			xsd_node,
			restrictions_vector,
			xsd_module_builder,
			indent_level = indent_level)
	end

	return nothing
end

function get_value_string(julia_type_string::AbstractString, xsd_value_string::AbstractString)::String
	if julia_type_string == built_in_data_type_dict["dateTime"]
		# A zoned bound needs TimeZones, which the generator does not load, so the generated code
		# builds the bound from its text.
		value_string = construct_time_default_value(xsd_value_string)
	elseif julia_type_string == "Dates.CompoundPeriod"
		value_string = duration_literal(xsd_value_string)
	elseif julia_type_string in values(built_in_data_type_dict)
		julia_type = julia_type_string |> Meta.parse |> eval
		value_string = string(parse(julia_type, xsd_value_string))
	else
		value_string = julia_type_string * "($xsd_value_string)"
	end
	return value_string
end

function write_max_inclusive(
	xsd_node::SimpleTreeNode,
	xsd_module_builder::XSDStructModuleBuilderType;
	indent_level::Int = 1,
)::Nothing

	struct_name = name(xsd_node)
	julia_type_string = xsd_node.field.julia_type
	value_string = get_value_string(julia_type_string, xsd_node.restrictions[MAX_INCLUSIVE_KEY])

	max_inclusive_string = """
	@inline AbstractXsdTypes.get_max_value(::Type{$struct_name})::$julia_type_string = $value_string

	@inline AbstractXsdTypes.is_max_exclusive(::Type{$struct_name})::Bool = false
	"""

	writeln(
		xsd_module_builder,
		IOStruct,
		max_inclusive_string,
		indent_level = indent_level)

	return nothing
end

function write_max_exclusive(
	xsd_node::SimpleTreeNode,
	xsd_module_builder::XSDStructModuleBuilderType;
	indent_level::Int = 1,
)::Nothing

	struct_name = name(xsd_node)
	julia_type_string = xsd_node.field.julia_type
	value_string = get_value_string(julia_type_string, xsd_node.restrictions[MAX_EXCLUSIVE_KEY])

	max_inclusive_string = """
	@inline AbstractXsdTypes.get_max_value(::Type{$struct_name})::$julia_type_string = $value_string

	@inline AbstractXsdTypes.is_max_exclusive(::Type{$struct_name})::Bool = true
	"""

	writeln(
		xsd_module_builder,
		IOStruct,
		max_inclusive_string,
		indent_level = indent_level)

	return nothing
end

function write_min_inclusive(
	xsd_node::SimpleTreeNode,
	xsd_module_builder::XSDStructModuleBuilderType;
	indent_level::Int = 1,
)::Nothing

	struct_name = name(xsd_node)
	julia_type_string = xsd_node.field.julia_type
	value_string = get_value_string(julia_type_string, xsd_node.restrictions[MIN_INCLUSIVE_KEY])

	min_inclusive_string = """
	@inline AbstractXsdTypes.get_min_value(::Type{$struct_name})::$julia_type_string = $value_string

	@inline AbstractXsdTypes.is_min_exclusive(::Type{$struct_name})::Bool = false
	"""

	writeln(
		xsd_module_builder,
		IOStruct,
		min_inclusive_string,
		indent_level = indent_level)

	return nothing
end

function write_min_exclusive(
	xsd_node::SimpleTreeNode,
	xsd_module_builder::XSDStructModuleBuilderType;
	indent_level::Int = 1,
)::Nothing

	struct_name = name(xsd_node)
	julia_type_string = xsd_node.field.julia_type
	value_string = get_value_string(julia_type_string, xsd_node.restrictions[MIN_EXCLUSIVE_KEY])

	min_inclusive_string = """
	@inline AbstractXsdTypes.get_min_value(::Type{$struct_name})::$julia_type_string = $value_string

	@inline AbstractXsdTypes.is_min_exclusive(::Type{$struct_name})::Bool = true
	"""

	writeln(
		xsd_module_builder,
		IOStruct,
		min_inclusive_string,
		indent_level = indent_level)

	return nothing
end

function write_get_max_fraction_digits(
	xsd_node::SimpleTreeNode,
	xsd_module_builder::XSDStructModuleBuilderType;
	indent_level::Int = 1,
)::Nothing

	struct_name = name(xsd_node)
	digits_string = xsd_node.restrictions[FRACTION_DIGITS_KEY]

	max_digits_string = """@inline AbstractXsdTypes.get_max_fraction_digits(::Type{$struct_name})::Int = $digits_string"""

	write(
		xsd_module_builder,
		IOStruct,
		max_digits_string,
		indent_level = indent_level)

	write(
		xsd_module_builder,
		IOStruct,
		"\n\n",
		indent_level = indent_level)

	return nothing
end

function write_get_max_total_digits(
	xsd_node::SimpleTreeNode,
	xsd_module_builder::XSDStructModuleBuilderType;
	indent_level::Int = 1,
)::Nothing

	struct_name = name(xsd_node)
	digits_string = xsd_node.restrictions[TOTAL_DIGITS_KEY]

	max_digits_string = """@inline AbstractXsdTypes.get_max_total_digits(::Type{$struct_name})::Int = $digits_string"""

	write(
		xsd_module_builder,
		IOStruct,
		max_digits_string,
		indent_level = indent_level)

	write(
		xsd_module_builder,
		IOStruct,
		"\n\n",
		indent_level = indent_level)

	return nothing
end

const LENGTH_KEY = "length"
const MIN_LENGTH_KEY = "minLength"
const MAX_LENGTH_KEY = "maxLength"
const PATTERN_KEY = "pattern"
const STRING_FACET_KEYS = (LENGTH_KEY, MIN_LENGTH_KEY, MAX_LENGTH_KEY, PATTERN_KEY)

# Writes the methods for the string facets of `xsd_node` and returns the names of their checks.
function write_string_facets(
	xsd_node::SimpleTreeNode,
	xsd_module_builder::XSDStructModuleBuilderType;
	indent_level::Int = 1,
)::Vector{String}
	struct_name = name(xsd_node)
	restrictions = xsd_node.restrictions
	checks = String[]
	lines = String[]

	min_length = get(restrictions, LENGTH_KEY, get(restrictions, MIN_LENGTH_KEY, nothing))
	max_length = get(restrictions, LENGTH_KEY, get(restrictions, MAX_LENGTH_KEY, nothing))
	isnothing(min_length) ||
		push!(lines, "@inline AbstractXsdTypes.get_min_string_length(::Type{$struct_name})::Int = $(parse(Int, min_length))")
	isnothing(max_length) ||
		push!(lines, "@inline AbstractXsdTypes.get_max_string_length(::Type{$struct_name})::Int = $(parse(Int, max_length))")
	isnothing(min_length) && isnothing(max_length) || push!(checks, "string_length_restriction_check")

	if haskey(restrictions, PATTERN_KEY)
		regex = xsd_pattern_regex(restrictions[PATTERN_KEY])
		push!(lines, "@inline AbstractXsdTypes.get_string_pattern_regex(::Type{$struct_name})::Regex = $(repr(regex))")
		push!(checks, "string_pattern_restriction_check")
	end

	writeln(xsd_module_builder, IOStruct, join(lines, "\n") * "\n", indent_level = indent_level)
	return checks
end

"""
	xsd_pattern_regex(pattern)

The `Regex` that matches the values XSD pattern `pattern` matches. An XSD pattern matches the whole
value, and `^` and `\$` are ordinary characters in it outside a character class. Character class
subtraction, such as `[a-z-[aeiou]]`, has no PCRE counterpart and is rejected, as are the escapes
PCRE does not know, such as `\\i` and `\\c`.
"""
function xsd_pattern_regex(pattern::AbstractString)::Regex
	body = IOBuffer()
	escaped = false
	in_class = false
	previous = '\0'
	for c in pattern
		if escaped
			print(body, '\\', c)
			escaped = false
			c = '\0'
		elseif c == '\\'
			escaped = true
		elseif in_class
			c == '[' && previous == '-' && throw(
				ArgumentError("the pattern $(repr(pattern)) subtracts a character class, which is not supported"))
			in_class = c != ']'
			print(body, c)
		elseif c == '['
			in_class = true
			print(body, c)
		elseif c == '^' || c == '$'
			print(body, '\\', c)
		else
			print(body, c)
		end
		previous = c
	end
	escaped && throw(ArgumentError("the pattern $(repr(pattern)) ends in an unfinished escape"))
	return Regex("\\A(?:" * String(take!(body)) * ")\\z")
end

# The built-in Julia type a simple type with value type `julia_type_string` derives from.
function built_in_julia_type(julia_type_string::AbstractString, xsd_module_builder::XSDStructModuleBuilderType)::String
	julia_type_string in values(built_in_data_type_dict) && return julia_type_string
	base_node = first(filter(x -> name(x) == julia_type_string, get_defined_simple_nodes(xsd_module_builder)))
	return built_in_julia_type(base_node.field.julia_type, xsd_module_builder)
end

# Julia source for the value with text `value` of the built-in Julia type `julia_type_string`.
function value_literal(julia_type_string::AbstractString, value::AbstractString)::String
	if julia_type_string == built_in_data_type_dict["dateTime"]
		return construct_time_default_value(value)
	elseif julia_type_string == "String"
		return repr(value)
	elseif julia_type_string in ("Date", "Time")
		return "$julia_type_string($(repr(value)))"
	elseif julia_type_string == "Dates.CompoundPeriod"
		return duration_literal(value)
	end
	julia_type = julia_type_string |> Meta.parse |> eval
	return "$julia_type_string($(parse(julia_type, value)))"
end

function write_get_enumeration(
	xsd_node::SimpleTreeNode,
	xsd_module_builder::XSDStructModuleBuilderType;
	indent_level::Int = 1,
)::Nothing
	base_type = built_in_julia_type(xsd_node.field.julia_type, xsd_module_builder)
	values = join((value_literal(base_type, value) for value in xsd_node.enumeration), ", ")
	writeln(
		xsd_module_builder,
		IOStruct,
		"@inline AbstractXsdTypes.get_enumeration(::Type{$(name(xsd_node))}) = ($values,)\n",
		indent_level = indent_level)
	return nothing
end

function write_get_restriction_checks(
	xsd_node::SimpleTreeNode,
	restrictions::AbstractVector{<:AbstractString},
	xsd_module_builder::XSDStructModuleBuilderType;
	indent_level::Int = 1,
)::Nothing
	struct_name = name(xsd_node)

	signature_string = "@inline AbstractXsdTypes.get_restriction_checks(::Type{$struct_name}) = ("
	restrictions_string = join(["AbstractXsdTypes.$restriction," for restriction in restrictions], " ")*")"

	writeln(xsd_module_builder, IOStruct, signature_string, indent_level = indent_level)
	writeln(xsd_module_builder, IOStruct, restrictions_string, indent_level = indent_level+1)
	write(xsd_module_builder,IOStruct,"\n")

	return nothing
end
