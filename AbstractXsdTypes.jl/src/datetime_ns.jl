"""
    DateTimeNs{T<:Dates.AbstractDateTime} <: Dates.AbstractDateTime

An `xs:dateTime` value to the nanosecond: `datetime`, a `DateTime` or a `ZonedDateTime`, holds it to
the millisecond, and `nanoseconds` holds the remaining `0:999_999` nanoseconds below that.

It is a `Dates.AbstractDateTime`, so the `Dates` accessors, period arithmetic, comparison, rounding
and `Dates.format` apply to it. A `DateTime` or `ZonedDateTime` converts to it, so a field of a
generated type accepts either. `DateTime(x)` gives the value without the nanoseconds.

`string(x)` gives the canonical XSD form: a zero offset is written `Z`, and the fraction of a second
carries no trailing zeros.

```jldoctest
julia> using AbstractXsdTypes, Dates

julia> x = AbstractXsdTypes.DateTimeNs(DateTime(2022, 5, 10, 10, 22, 49, 152), 557_500);

julia> string(x)
"2022-05-10T10:22:49.1525575"

julia> (millisecond(x), microsecond(x), nanosecond(x))
(152, 557, 500)

julia> string(x + Nanosecond(500))
"2022-05-10T10:22:49.152558"
```
"""
struct DateTimeNs{T<:Dates.AbstractDateTime} <: Dates.AbstractDateTime
    datetime::T
    nanoseconds::Int32

    function DateTimeNs{T}(datetime, nanoseconds::Integer = 0) where {T<:Dates.AbstractDateTime}
        0 <= nanoseconds < 1_000_000 ||
            throw(ArgumentError("nanoseconds below a millisecond must be in 0:999_999, got $nanoseconds"))
        return new{T}(datetime, nanoseconds)
    end
end
DateTimeNs(datetime::T, nanoseconds::Integer = 0) where {T<:Dates.AbstractDateTime} =
    DateTimeNs{T}(datetime, nanoseconds)

# A field typed as a union of `DateTimeNs` variants, optionally with `Nothing`, accepts the value
# the variant wraps.
Base.convert(::Type{U}, x::T) where {T<:Dates.AbstractDateTime,DateTimeNs{T}<:U<:Union{Nothing,DateTimeNs}} =
    DateTimeNs(x)

Dates.days(x::DateTimeNs) = Dates.days(x.datetime)
Dates.hour(x::DateTimeNs) = Dates.hour(x.datetime)
Dates.minute(x::DateTimeNs) = Dates.minute(x.datetime)
Dates.second(x::DateTimeNs) = Dates.second(x.datetime)
Dates.millisecond(x::DateTimeNs) = Dates.millisecond(x.datetime)
Dates.microsecond(x::DateTimeNs) = Int(div(x.nanoseconds, 1000))
Dates.nanosecond(x::DateTimeNs) = Int(rem(x.nanoseconds, 1000))

Dates.Date(x::DateTimeNs) = Dates.Date(x.datetime)
Dates.DateTime(x::DateTimeNs) = Dates.DateTime(x.datetime)
Dates.Time(x::DateTimeNs) = Dates.Time(x.datetime) + Dates.Nanosecond(x.nanoseconds)
Dates.datetime2unix(x::DateTimeNs{Dates.DateTime}) = Dates.datetime2unix(x.datetime) + x.nanoseconds / 1e9

Base.:(==)(x::DateTimeNs, y::DateTimeNs) = x.datetime == y.datetime && x.nanoseconds == y.nanoseconds
Base.isless(x::DateTimeNs, y::DateTimeNs) =
    isless(x.datetime, y.datetime) || (x.datetime == y.datetime && x.nanoseconds < y.nanoseconds)
# Equal to the value it wraps when the nanoseconds are zero, so the hash must agree with it then.
Base.hash(x::DateTimeNs, h::UInt) =
    iszero(x.nanoseconds) ? hash(x.datetime, h) : hash(x.nanoseconds, hash(x.datetime, h))

# Compared with the type it wraps directly: promoting would clash with TimeZones' own
# `promote_rule` for `ZonedDateTime`.
Base.:(==)(x::DateTimeNs{T}, y::T) where {T<:Dates.AbstractDateTime} = x == DateTimeNs(y)
Base.:(==)(x::T, y::DateTimeNs{T}) where {T<:Dates.AbstractDateTime} = DateTimeNs(x) == y
Base.isless(x::DateTimeNs{T}, y::T) where {T<:Dates.AbstractDateTime} = isless(x, DateTimeNs(y))
Base.isless(x::T, y::DateTimeNs{T}) where {T<:Dates.AbstractDateTime} = isless(DateTimeNs(x), y)

# The first estimate of a range's length; `Dates` corrects it.
Dates.guess(a::DateTimeNs, b::DateTimeNs, c) = Dates.guess(a.datetime, b.datetime, c)
Dates.guess(a::DateTimeNs, b::DateTimeNs, c::Dates.FixedPeriod) = fld(Dates.value(b - a), Dates.tons(c))

const NANOSECONDS_PER_MILLISECOND = 1_000_000

function Base.:+(x::DateTimeNs, p::Union{Dates.Microsecond,Dates.Nanosecond})
    total = x.nanoseconds + Dates.value(Dates.Nanosecond(p))
    return DateTimeNs(
        x.datetime + Dates.Millisecond(fld(total, NANOSECONDS_PER_MILLISECOND)),
        mod(total, NANOSECONDS_PER_MILLISECOND),
    )
end
Base.:+(x::DateTimeNs, p::Dates.Period) = DateTimeNs(x.datetime + p, x.nanoseconds)
Base.:+(p::Dates.Period, x::DateTimeNs) = x + p
Base.:-(x::DateTimeNs, p::Dates.Period) = x + (-p)
Base.:-(x::DateTimeNs, y::DateTimeNs) = Dates.Nanosecond(
    Dates.value(Dates.Millisecond(x.datetime - y.datetime)) * NANOSECONDS_PER_MILLISECOND + x.nanoseconds -
    y.nanoseconds,
)

# Rounding to a millisecond or coarser; `ceil` and `round` follow from `floor`.
Base.floor(x::DateTimeNs, p::Union{Dates.DatePeriod,Dates.Hour,Dates.Minute,Dates.Second,Dates.Millisecond}) =
    DateTimeNs(floor(x.datetime, p))
Base.trunc(x::DateTimeNs, P::Type{<:Union{Dates.DatePeriod,Dates.Hour,Dates.Minute,Dates.Second,Dates.Millisecond}}) =
    DateTimeNs(trunc(x.datetime, P))
for f in (
    :firstdayofweek, :lastdayofweek, :firstdayofmonth, :lastdayofmonth,
    :firstdayofquarter, :lastdayofquarter, :firstdayofyear, :lastdayofyear,
)
    @eval Dates.$f(x::DateTimeNs) = DateTimeNs(Dates.$f(x.datetime))
end

function Base.print(io::IO, x::DateTimeNs)
    # `string` of a `DateTime` or `ZonedDateTime` is "<date>T<hh:mm:ss>[.fff][offset]".
    m = match(r"^(.*T\d\d:\d\d:\d\d)(?:\.\d+)?(.*)$", string(x.datetime))
    fraction = rstrip(lpad(Dates.millisecond(x.datetime), 3, '0') * lpad(x.nanoseconds, 6, '0'), '0')
    offset = m.captures[2] == "+00:00" ? "Z" : m.captures[2]
    print(io, m.captures[1], isempty(fraction) ? "" : ".", fraction, offset)
end
Base.show(io::IO, x::DateTimeNs) = print(io, "DateTimeNs(", repr(x.datetime), ", ", x.nanoseconds, ")")
