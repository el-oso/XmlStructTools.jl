module AbstractXsdTypesTimeZonesExt

# The methods of `ZonedDateTime` for `DateTimeNs`, loaded with TimeZones.

using AbstractXsdTypes
using AbstractXsdTypes: DateTimeNs
using Dates
using TimeZones

const ZonedNs = DateTimeNs{ZonedDateTime}

# XSD writes a zero offset as `Z`, and an offset as ±hh:mm; the seconds of an offset with them,
# such as a local mean time, follow as `:ss`.
function AbstractXsdTypes.print_offset(io::IO, zoned::ZonedDateTime)
    offset = FixedTimeZone(zoned).offset
    seconds = Dates.value(offset.std + offset.dst)
    iszero(seconds) && return print(io, 'Z')
    print(io, seconds < 0 ? '-' : '+')
    hours, rest = divrem(abs(seconds), 3600)
    minutes, seconds = divrem(rest, 60)
    AbstractXsdTypes.print_padded(io, hours, 2)
    print(io, ':')
    AbstractXsdTypes.print_padded(io, minutes, 2)
    if !iszero(seconds)
        print(io, ':')
        AbstractXsdTypes.print_padded(io, seconds, 2)
    end
end

TimeZones.timezone(x::ZonedNs) = timezone(x.datetime)
TimeZones.TimeZone(x::ZonedNs) = TimeZone(x.datetime)
TimeZones.FixedTimeZone(x::ZonedNs) = FixedTimeZone(x.datetime)
TimeZones.astimezone(x::ZonedNs, tz::TimeZone) = DateTimeNs(astimezone(x.datetime, tz), x.nanoseconds)
TimeZones.next_transition_instant(x::ZonedNs, args...) = next_transition_instant(x.datetime, args...)
TimeZones.show_next_transition(io::IO, x::ZonedNs, args...) = show_next_transition(io, x.datetime, args...)

for K in (TimeZones.UTC, TimeZones.Local)
    @eval Dates.Date(x::ZonedNs, ::Type{$K}) = Date(x.datetime, $K)
    @eval Dates.DateTime(x::ZonedNs, ::Type{$K}) = DateTime(x.datetime, $K)
    @eval Dates.Time(x::ZonedNs, ::Type{$K}) = Time(x.datetime, $K) + Nanosecond(x.nanoseconds)
end

# Like `DateTime(x)`, these give the value without the nanoseconds.
TimeZones.ZonedDateTime(x::ZonedNs) = x.datetime
TimeZones.ZonedDateTime(x::DateTimeNs{DateTime}, args...; kwargs...) = ZonedDateTime(x.datetime, args...; kwargs...)

# The constructors of `ZonedDateTime`, keeping the nanoseconds.
DateTimeNs{ZonedDateTime}(x::DateTimeNs{DateTime}, tz::TimeZone, args...; kwargs...) =
    DateTimeNs(ZonedDateTime(x.datetime, tz, args...; kwargs...), x.nanoseconds)
function DateTimeNs{ZonedDateTime}(y::Integer, rest::Union{Integer,TimeZone}...; kwargs...)
    tz = last(rest)
    tz isa TimeZone || throw(ArgumentError("the last argument must be a time zone, got $(repr(tz))"))
    parts = (y, Base.front(rest)...)
    all(p -> p isa Integer, parts) || throw(ArgumentError("only the last argument may be a time zone"))
    return DateTimeNs{ZonedDateTime}(DateTimeNs{DateTime}(parts...), tz; kwargs...)
end
# Resolves two integers against the inner `(datetime, nanoseconds)` constructor: without a zone
# they are not a zoned value.
DateTimeNs{ZonedDateTime}(::Integer, last::Integer; kwargs...) =
    throw(ArgumentError("the last argument must be a time zone, got $(repr(last))"))

Base.:+(x::DateTimeNs{DateTime}, offset::TimeZones.UTCOffset) = DateTimeNs(x.datetime + offset, x.nanoseconds)
Base.:-(x::DateTimeNs{DateTime}, offset::TimeZones.UTCOffset) = DateTimeNs(x.datetime - offset, x.nanoseconds)

end
