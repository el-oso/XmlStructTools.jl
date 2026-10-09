# bounds for an xs:dateTime value; a bound the schema does not give is `nothing`
@inline function bound_restriction_check(::Type{T}, value::Dates.AbstractDateTime)::Nothing where {T<:AbstractXSDDateTime}
    # The constructor checks the value before it is converted to the field's type.
    value = DateTimeNs(value)
    max_value = get_max_value(T)
    min_value = get_min_value(T)

    if !isnothing(max_value) && (is_max_exclusive(T) ? comparable(max_value, value) <= value : comparable(max_value, value) < value)
        throw(
            XSDValueRestrictionViolationError(
                T,
                value,
                "Value ($(value)) exceeds the maximum value ($(max_value)) for $(T).",
            ),
        )
    elseif !isnothing(min_value) &&
           (is_min_exclusive(T) ? value <= comparable(min_value, value) : value < comparable(min_value, value))
        throw(
            XSDValueRestrictionViolationError(
                T,
                value,
                "Value $(value) is less than the minimum value ($(min_value)) for $(T).",
            ),
        )
    end

    return nothing
end

# XSD leaves the order of a dateTime with a zone offset and one without undetermined, so a bound
# and a value compare only when both have an offset or neither does.
function comparable(bound::DateTimeNs{S}, value::DateTimeNs{T}) where {S,T}
    S === T || throw(
        ArgumentError(
            "cannot compare $value with the bound $bound: one has a zone offset and the other does not",
        ),
    )
    return bound
end

@inline is_max_exclusive(::Type{<:AbstractXSDDateTime})::Bool = true
@inline is_min_exclusive(::Type{<:AbstractXSDDateTime})::Bool = true
@inline get_max_value(::Type{<:AbstractXSDDateTime}) = nothing
@inline get_min_value(::Type{<:AbstractXSDDateTime}) = nothing
