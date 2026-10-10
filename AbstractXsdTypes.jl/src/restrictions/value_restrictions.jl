
@inline function get_restriction_checks(::Type{T})::Tuple{} where {T<:AbstractXSDSimpleTypes}
    return ()
end

@inline function check_restrictions(::Type{T}, value)::Nothing where {T<:AbstractXSDSimpleTypes}
    for restriction_check in get_restriction_checks(T)
        restriction_check(T, value)
    end

    return nothing
end

"""
XSDRestrictionViolationError <: Exception

Custom exception type to indicate that something was passed to an XSD type constructor which violates a restriction for
that type.
"""
abstract type XSDRestrictionViolationError <: Exception end

"""
    XSDValueRestrictionViolationError <: XSDRestrictionViolationError

Custom exception type to indicate that a value was passed to an XSD type constructor which violates a value based
restriction for that type.
"""
struct XSDValueRestrictionViolationError <: XSDRestrictionViolationError
    type::Any
    value::Any
    message::String
end

"""
    XSDStringRestrictionViolationError <: XSDRestrictionViolationError

Custom exception type to indicate that a string was passed to an XSD type constructor which violates a string based
restriction for that type.
"""
struct XSDStringRestrictionViolationError <: XSDRestrictionViolationError
    type::Any
    string::String
    message::String
end

"""
    get_enumeration(T)

The values a value of the simple type `T` must be one of, from the schema's `enumeration` facets.
"""
function get_enumeration end

# `isequal` rather than `==`, so that an enumerated `NaN` admits `NaN`.
@inline function enumeration_check(::Type{T}, value)::Nothing where {T<:AbstractXSDSimpleTypes}
    allowed = get_enumeration(T)
    any(isequal(value), allowed) && return nothing
    throw(
        XSDValueRestrictionViolationError(
            T,
            value,
            "Value $(repr(value)) is not one of the values $(join(repr.(allowed), ", ")) allowed for $(T).",
        ),
    )
end

include("numeric_restrictions.jl")
include("string_restrictions.jl")
include("datetime_restrictions.jl")
include("duration_restrictions.jl")
