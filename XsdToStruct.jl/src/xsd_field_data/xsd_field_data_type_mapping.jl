
optional_type_string(type_string::AbstractString)::String = "Union{$type_string, Nothing}"

named_tuple_field_names(field_data_vector::Vector{AbstractFieldData})::String =
    join([":" * field_data.name for field_data in field_data_vector], ", ")

named_tuple_field_types(field_data_vector::Vector{AbstractFieldData})::String =
    join(optional_type_string.(qualified_type.(field_data_vector)), ", ")

function choice_julia_type(field_data_vector::Vector{AbstractFieldData})::String
    field_names = named_tuple_field_names(field_data_vector)
    field_types = named_tuple_field_types(field_data_vector)
    return "NamedTuple{($field_names), Tuple{$field_types}}"
end

# TODO: Better match for decimal?
const built_in_data_type_dict = Dict([
    ("string", "String"),
    ("double", "Float64"),
    ("boolean", "Bool"),
    ("dateTime", "Union{DateTimeNs{ZonedDateTime}, DateTimeNs{DateTime}}"),
    ("date", "Date"),
    ("time", "Time"),
    ("duration", "Dates.CompoundPeriod"),
    ("base64Binary", "Vector{UInt8}"),
    ("integer", "Int64"),
    ("int", "Int64"),
    ("nonNegativeInteger", "UInt64"),
    ("positiveInteger", "UInt64"),
    ("decimal", "Float64"),
    ("float", "Float32"),
    ("long", "Int64"),
    ("short", "Int16"),
    ("byte", "Int8"),
    ("negativeInteger", "Int64"),
    ("nonPositiveInteger", "Int64"),
    ("unsignedLong", "UInt64"),
    ("unsignedInt", "UInt32"),
    ("unsignedShort", "UInt16"),
    ("unsignedByte", "UInt8"),
    ("normalizedString", "String"),
    ("token", "String"),
    ("language", "String"),
    ("Name", "String"),
    ("NCName", "String"),
    ("NMTOKEN", "String"),
    ("ID", "String"),
    ("IDREF", "String"),
    ("ENTITY", "String"),
    ("anyURI", "String"),
    ("QName", "String"),
])
strip_xsd_namespace(type_string::AbstractString)::AbstractString = split(type_string, ":")[end]

const XML_SCHEMA_NAMESPACE = "http://www.w3.org/2001/XMLSchema"

# The reader writes every reference to a built-in type with this prefix, whatever prefix the schema
# binds to the XML Schema namespace, so only these references map to Julia types. A schema type
# named like a built-in one, such as `Name` or `date`, stays a schema type.
const BUILT_IN_PREFIX = "xs"

function parse_xsd_type_to_julia_type(type_string::AbstractString)::String
    prefix, type_name = ':' in type_string ? split(type_string, ':'; limit = 2) : ("", type_string)
    prefix == BUILT_IN_PREFIX || return type_name
    return get(built_in_data_type_dict, type_name, type_name)
end

"""
    xsd_type_reference(type_string)

The reference `type_string`, read from a `type` or `base` attribute, with a reference into the
XML Schema namespace written as `xs:name`. Prefixes resolve against the namespaces declared on the
schema element, which `create_xsd_tree` holds in task-local storage while it reads.
"""
function xsd_type_reference(type_string::AbstractString)::String
    namespaces = task_local_storage(:xsd_namespaces)::Dict{String, String}
    prefix, type_name = ':' in type_string ? split(type_string, ':'; limit = 2) : ("", type_string)
    namespace = get(namespaces, prefix, nothing)
    namespace == XML_SCHEMA_NAMESPACE && return "$BUILT_IN_PREFIX:$type_name"
    prefix == BUILT_IN_PREFIX && throw(ArgumentError(
        "the schema binds the prefix `$BUILT_IN_PREFIX` to $(repr(namespace)), not to the XML Schema " *
        "namespace; the generator reserves `$BUILT_IN_PREFIX` for built-in types"))
    return type_string
end

# The `xmlns` declarations of the schema element, keyed by prefix; the default namespace has key "".
function schema_namespaces(attributes::Dict{String, String})::Dict{String, String}
    namespaces = Dict{String, String}()
    for (key, value) in attributes
        key == "xmlns" && (namespaces[""] = value)
        startswith(key, "xmlns:") && (namespaces[key[7:end]] = value)
    end
    return namespaces
end

# determine type properties from the given xsd attribute dictionary
function is_vector(xsd_attributes::OptionalDictStringString)::Bool
    if !isnothing(xsd_attributes) && haskey(xsd_attributes, "maxOccurs")
        max_occurs = xsd_attributes["maxOccurs"]
        is_vector = (max_occurs == "unbounded" || parse(Int, max_occurs) > 1)
    else
        is_vector = false
    end

    return is_vector
end

(
    get_default_value(xsd_attributes::OptionalDictStringString)::Union{Nothing,Any} =
        return !isnothing(xsd_attributes) && haskey(xsd_attributes, "default") ? xsd_attributes["default"] : nothing
)

function can_be_missing(xsd_attributes::OptionalDictStringString)::Bool
    return (!isnothing(xsd_attributes) && haskey(xsd_attributes, "minOccurs") && xsd_attributes["minOccurs"] == "0")
end
