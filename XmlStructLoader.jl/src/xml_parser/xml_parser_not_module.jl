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
function parse_xml_date(date_string::AbstractString)::AbstractXsdTypes.DateTimeNs
    isnothing(match(timezone_regex, date_string)) && return AbstractXsdTypes.DateTimeNs{DateTime}(date_string)
    return AbstractXsdTypes.DateTimeNs{ZonedDateTime}(date_string)
end
