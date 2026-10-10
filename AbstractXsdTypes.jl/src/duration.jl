# https://www.w3.org/TR/xmlschema-2/#duration
const XSD_DURATION_REGEX =
    r"^(-)?P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)(?:\.(\d+))?S)?)?$"

"""
    parse_xsd_duration(text)::Dates.CompoundPeriod

The `xs:duration` written as `text`, such as `"P1Y2M3DT4H5M6.5S"` or `"-PT30M"`. A sign applies to
every component. Fractional seconds are kept to the nanosecond; more digits throw.
"""
function parse_xsd_duration(text::AbstractString)::Dates.CompoundPeriod
    m = match(XSD_DURATION_REGEX, text)
    # The regex also matches `P` alone and a `T` with no time after it, which XML Schema forbids.
    if isnothing(m) || all(isnothing, m.captures[2:end]) || endswith(text, 'T')
        throw(ArgumentError("$(repr(text)) is not an xs:duration"))
    end
    sign_char, years, months, days, hours, minutes, seconds, fraction = m.captures
    if !isnothing(fraction) && length(fraction) > 9
        throw(ArgumentError("$(repr(text)) has more than nine digits after the seconds"))
    end
    to_int(s) = isnothing(s) ? 0 : parse(Int64, s)
    nanoseconds = isnothing(fraction) ? 0 : parse(Int64, rpad(fraction, 9, '0'))
    periods = Dates.Period[
        Year(to_int(years)), Month(to_int(months)), Day(to_int(days)),
        Hour(to_int(hours)), Minute(to_int(minutes)), Second(to_int(seconds)), Nanosecond(nanoseconds),
    ]
    duration = Dates.CompoundPeriod(periods)
    return isnothing(sign_char) ? duration : -duration
end

"""
    xsd_duration_string(duration::Dates.CompoundPeriod)::String

`duration` written as an `xs:duration`. Weeks are written as days and every period below a second
as fractional seconds. XML Schema has one sign for the whole value, so a duration whose periods have
different signs throws.
"""
function xsd_duration_string(duration::Dates.CompoundPeriod)::String
    years = months = days = hours = minutes = nanoseconds = Int64(0)
    for period in duration.periods
        if period isa Year
            years += Dates.value(period)
        elseif period isa Month || period isa Quarter
            months += Dates.value(Month(period))
        elseif period isa Week || period isa Day
            days += Dates.value(Day(period))
        elseif period isa Hour
            hours += Dates.value(period)
        elseif period isa Minute
            minutes += Dates.value(period)
        else
            nanoseconds += Dates.value(Nanosecond(period))
        end
    end
    totals = (years, months, days, hours, minutes, nanoseconds)
    negative = any(<(0), totals)
    if negative && any(>(0), totals)
        throw(ArgumentError("$duration has periods of both signs, which an xs:duration cannot represent"))
    end
    years, months, days, hours, minutes, nanoseconds = abs.(totals)

    io = IOBuffer()
    print(io, negative ? "-P" : "P")
    iszero(years) || print(io, years, 'Y')
    iszero(months) || print(io, months, 'M')
    iszero(days) || print(io, days, 'D')
    if !iszero(hours) || !iszero(minutes) || !iszero(nanoseconds) || all(iszero, totals)
        print(io, 'T')
        iszero(hours) || print(io, hours, 'H')
        iszero(minutes) || print(io, minutes, 'M')
        # A zero duration still needs one component, so it is written `PT0S`.
        if !iszero(nanoseconds) || all(iszero, totals)
            seconds, fraction = divrem(nanoseconds, 1_000_000_000)
            print(io, seconds)
            iszero(fraction) || print(io, '.', rstrip(lpad(fraction, 9, '0'), '0'))
            print(io, 'S')
        end
    end
    return String(take!(io))
end

# https://www.w3.org/TR/xmlschema-2/#duration-order
# Each starts on the first of a month, so adding months never has to clamp the day.
const DURATION_REFERENCE_TIMES =
    DateTimeNs.(DateTime.((1696, 1697, 1903, 1903), (9, 2, 3, 7), 1))

"""
    compare_durations(a, b)::Int

-1, 0 or 1 as the duration `a` is shorter than, equal to or longer than `b`, by the order XML
Schema defines: `a` and `b` are added to four reference dateTimes and must compare the same way at
each. Where they do not, as for `P1M` and `P30D`, XML Schema leaves the order undetermined and this
throws an `ArgumentError`.
"""
function compare_durations(a::Dates.CompoundPeriod, b::Dates.CompoundPeriod)::Int
    orders = map(t -> cmp(t + a, t + b), DURATION_REFERENCE_TIMES)
    allequal(orders) || throw(ArgumentError("the order of the durations $a and $b is undetermined"))
    return first(orders)
end
