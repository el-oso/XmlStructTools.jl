# bounds for an xs:duration value; a bound the schema does not give is `nothing`
@inline function bound_restriction_check(::Type{T}, value)::Nothing where {T<:AbstractXSDDuration}
    # The constructor checks the value before it is converted to the field's type.
    value = convert(Dates.CompoundPeriod, value)
    max_value = get_max_value(T)
    min_value = get_min_value(T)

    if !isnothing(max_value) && compare_durations(value, max_value) >= (is_max_exclusive(T) ? 0 : 1)
        throw(
            XSDValueRestrictionViolationError(
                T,
                value,
                "Value $(xsd_duration_string(value)) exceeds the maximum value $(xsd_duration_string(max_value)) for $(T).",
            ),
        )
    elseif !isnothing(min_value) && compare_durations(value, min_value) <= (is_min_exclusive(T) ? 0 : -1)
        throw(
            XSDValueRestrictionViolationError(
                T,
                value,
                "Value $(xsd_duration_string(value)) is less than the minimum value $(xsd_duration_string(min_value)) for $(T).",
            ),
        )
    end

    return nothing
end

@inline is_max_exclusive(::Type{<:AbstractXSDDuration})::Bool = true
@inline is_min_exclusive(::Type{<:AbstractXSDDuration})::Bool = true
@inline get_max_value(::Type{<:AbstractXSDDuration}) = nothing
@inline get_min_value(::Type{<:AbstractXSDDuration}) = nothing
