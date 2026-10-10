function parse_xml_node_not_module(
    @nospecialize(xml_node::UnifiedXMLElement),
    ::Type{T},
    module_ref::Module,
    validate::Bool,
    default_value::Union{Nothing,S},
)::Union{Nothing,T} where {T<:Number,S<:Number}
    content_string = content(xml_node)

    if content_string == ""
        return default_value
    else
        return Parsers.parse(T, content_string)
    end
end

function parse_xml_node_not_module(
    xml_node::UnifiedXMLElement,
    ::Type{T},
    module_ref::Module,
    validate::Bool,
    default_value,
)::T where {T<:AbstractString}
    content_string = content(xml_node) # for strings we need the raw content
    if !isnothing(default_value) && isempty(content_string)
        return T(default_value)
    else
        return T(content_string)
    end
end

# `xs:base64Binary` carries its bytes as base64 text, and the value a caller wants is the bytes.
function parse_xml_node_not_module(
    xml_node::UnifiedXMLElement,
    ::Type{T},
    module_ref::Module,
    validate::Bool,
    default_value,
)::Union{Nothing,T} where {T<:AbstractVector{UInt8}}
    content_string = content(xml_node)
    isempty(content_string) && return isnothing(default_value) ? nothing : T(default_value)
    return T(Base64.base64decode(content_string))
end

# `xs:date` and `xs:time` parse to `Date` and `Time`. An element whose text carries a zone offset
# is rejected rather than read as a local value: neither type has anywhere to keep the offset, and
# `xs:dateTime` is the declaration that does.
function parse_xml_node_not_module(
    xml_node::UnifiedXMLElement,
    ::Type{T},
    module_ref::Module,
    validate::Bool,
    default_value::Union{Nothing,T},
)::Union{Nothing,T} where {T<:Union{Date,Time}}
    content_string = content(xml_node)
    isempty(content_string) && return default_value

    if occursin(r"(Z|[+-]\d{2}:\d{2})$", content_string)
        throw(
            ArgumentError(
                "\"$content_string\" carries a time zone offset, which $T cannot represent; " *
                "declare the element as xs:dateTime to keep the offset",
            ),
        )
    end
    return parse(T, content_string)
end

function parse_xml_node_not_module(
    xml_node::UnifiedXMLElement,
    ::Type{Dates.CompoundPeriod},
    module_ref::Module,
    validate::Bool,
    default_value::Union{Nothing,Dates.CompoundPeriod},
)::Union{Nothing,Dates.CompoundPeriod}
    content_string = content(xml_node)
    isempty(content_string) && return default_value
    return AbstractXsdTypes.parse_xsd_duration(content_string)
end

function parse_xml_node_not_module(
    xml_node::UnifiedXMLElement,
    ::Type{<:AbstractXsdTypes.DateTimeNs},
    module_ref::Module,
    validate::Bool,
    default_value::Union{Nothing,AbstractXsdTypes.DateTimeNs},
)::Union{Nothing,AbstractXsdTypes.DateTimeNs}
    content_string = content(xml_node)

    if isempty(content_string)
        return default_value
    else
        return parse_xml_date(content_string)
    end
end

# Regex inspired by section 3.2.7.3 Timezones of
# https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/datatypes.html#dateTime
const timezone_regex = r"((\+|-)\d\d:\d\d)|Z"
# Built once: a format given as a string is parsed into a `DateFormat` on every call.
const zoned_date_formats = Tuple(DateFormat("yyyy-mm-ddTHH:MM:SS$(s)zzzzzz") for s in ("", ".s", ".ss", ".sss"))
function parse_xml_date(date_string::AbstractString)::AbstractXsdTypes.DateTimeNs
    timezone_match = match(timezone_regex, date_string)
    is_not_timezone_string = isnothing(timezone_match)

    preparsed_string, n_after_period, nanoseconds = split_seconds(date_string)

    if is_not_timezone_string
        parsed_date = DateTime(preparsed_string, ISODateTimeFormat)
    else
        parsed_date = ZonedDateTime(preparsed_string, zoned_date_formats[n_after_period + 1])
    end

    return AbstractXsdTypes.DateTimeNs(parsed_date, nanoseconds)
end

# Regex inspired by section 3.2.7.1 Lexical representation of
# https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/datatypes.html#dateTime
const seconds_after_period_regex = r"^(-?\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.?)(\d*)(.*)$"
# The digits after the seconds of "...THH:MM:SS[.fff]", counted without the allocations of a regex
# match. A string of another shape is left to the date parser to reject.
function fraction_digit_count(date_string::AbstractString)::Int
    bytes = codeunits(date_string)
    t = findfirst(==(UInt8('T')), bytes)
    isnothing(t) && return 0
    i = t + ncodeunits("THH:MM:SS")
    i <= lastindex(bytes) && bytes[i] == UInt8('.') && (i += 1)
    start = i
    while i <= lastindex(bytes) && UInt8('0') <= bytes[i] <= UInt8('9')
        i += 1
    end
    return i - start
end

# Splits the digits after the seconds into the milliseconds, left in the string for the date parser,
# and the nanoseconds below them. Digits below a nanosecond are cut off with a warning.
@inline function split_seconds(date_string::AbstractString)::Tuple{String,Int,Int}
    n_after_period = fraction_digit_count(date_string)
    n_after_period <= 3 && return date_string, n_after_period, 0

    seconds_after_period_match = match(seconds_after_period_regex, date_string)
    fraction = seconds_after_period_match.captures[2]
    if n_after_period > 9
        @warn "dateTime element with $n_after_period digits after the seconds, anything below nanoseconds is cut off." maxlog = 1
    end
    nanoseconds = parse(Int, rpad(fraction[4:min(end, 9)], 6, '0'))
    millisecond_string =
        seconds_after_period_match.captures[1] * fraction[1:3] * seconds_after_period_match.captures[3]
    return millisecond_string, 3, nanoseconds
end
