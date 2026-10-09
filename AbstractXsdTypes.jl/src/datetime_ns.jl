"""
    DateTimeNs{T<:Dates.AbstractDateTime} <: Dates.AbstractDateTime

An `xs:dateTime` value to the nanosecond: `datetime`, a `DateTime` or a `ZonedDateTime`, holds it to
the millisecond, and `nanoseconds` holds the remaining `0:999_999` nanoseconds below that.

It has the methods of the type it wraps: the `Dates` accessors and period constructors, period
arithmetic, comparison, rounding, ranges, `Dates.format`, `parse`, and, once TimeZones is loaded,
`timezone`, `astimezone` and the other methods of `ZonedDateTime`. Where the wrapped type works to
the millisecond, such as `Dates.format` or `DateTime(x)`, the nanoseconds are left out. The
difference of two values is a `Nanosecond`, which spans about 292 years; a longer one throws an
`OverflowError`.

It is built like the type it wraps, from a value and the nanoseconds, from parts that go on to
microseconds and nanoseconds as those of `Time` do, from periods, from a `Date` and a `Time`, or
from text with up to nine digits after the seconds. A `DateTime` or `ZonedDateTime` converts to it,
so a field of a generated type accepts either.

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
# A value that is already a `DateTimeNs` passes through rather than being wrapped again.
DateTimeNs(x::DateTimeNs) = x
DateTimeNs{T}(x::DateTimeNs{T}) where {T<:Dates.AbstractDateTime} = x

# The constructors of `DateTime`, extended below the millisecond as those of `Time` are.
function DateTimeNs{Dates.DateTime}(
    y::Integer, m::Integer = 1, d::Integer = 1, h::Integer = 0, mi::Integer = 0, s::Integer = 0,
    ms::Integer = 0, us::Integer = 0, ns::Integer = 0,
)
    0 <= us < 1000 || throw(ArgumentError("microsecond must be in 0:999, got $us"))
    0 <= ns < 1000 || throw(ArgumentError("nanosecond must be in 0:999, got $ns"))
    return DateTimeNs{Dates.DateTime}(Dates.DateTime(y, m, d, h, mi, s, ms), 1000 * us + ns)
end
DateTimeNs(y::Integer, parts::Integer...) = DateTimeNs{Dates.DateTime}(y, parts...)
function DateTimeNs{Dates.DateTime}(period::Dates.Period, periods::Dates.Period...)
    all_periods = (period, periods...)
    is_fine(p) = p isa Union{Dates.Microsecond,Dates.Nanosecond}
    coarse = Dates.DateTime(filter(!is_fine, all_periods)...)
    return DateTimeNs(coarse) + sum(Dates.Nanosecond, filter(is_fine, all_periods); init = Dates.Nanosecond(0))
end
function DateTimeNs{Dates.DateTime}(date::Dates.Date, time::Dates.Time)
    milliseconds = Dates.Time(Dates.hour(time), Dates.minute(time), Dates.second(time), Dates.millisecond(time))
    return DateTimeNs{Dates.DateTime}(
        Dates.DateTime(date, milliseconds), 1000 * Dates.microsecond(time) + Dates.nanosecond(time),
    )
end
DateTimeNs(date::Dates.Date, time::Dates.Time) = DateTimeNs{Dates.DateTime}(date, time)
DateTimeNs{T}(adjust::Function, args...; kwargs...) where {T<:Dates.AbstractDateTime} =
    DateTimeNs{T}(T(adjust, args...; kwargs...))
# Resolves `(adjust, year)` against the inner `(datetime, nanoseconds)` constructor.
DateTimeNs{T}(adjust::Function, y::Integer; kwargs...) where {T<:Dates.AbstractDateTime} =
    DateTimeNs{T}(T(adjust, y; kwargs...))

# Text with up to nine digits after the seconds, in the forms the wrapped type parses; the digits
# past the third are the nanoseconds.
function DateTimeNs{T}(text::AbstractString) where {T<:Dates.AbstractDateTime}
    m = match(r"^(.*T\d\d:\d\d:\d\d\.\d{3})(\d+)(.*)$", text)
    isnothing(m) && return DateTimeNs{T}(T(text))
    fraction = m.captures[2]
    length(fraction) <= 6 ||
        throw(ArgumentError("\"$text\" has more than nine digits after the seconds, which DateTimeNs cannot hold"))
    return DateTimeNs{T}(T(m.captures[1] * m.captures[3]), parse(Int, rpad(fraction, 6, '0')))
end
# A `DateFormat` resolves to the millisecond, so these give no nanoseconds.
DateTimeNs{T}(text::AbstractString, format::Union{AbstractString,Dates.DateFormat}; kwargs...) where {T<:Dates.AbstractDateTime} =
    DateTimeNs{T}(T(text, format; kwargs...))
Base.parse(::Type{DateTimeNs{T}}, text::AbstractString) where {T<:Dates.AbstractDateTime} = DateTimeNs{T}(text)
Base.parse(::Type{DateTimeNs{T}}, text::AbstractString, format::Dates.DateFormat) where {T<:Dates.AbstractDateTime} =
    DateTimeNs{T}(parse(T, text, format))
function Base.tryparse(::Type{DateTimeNs{T}}, text::AbstractString, format::Dates.DateFormat) where {T<:Dates.AbstractDateTime}
    parsed = tryparse(T, text, format)
    return isnothing(parsed) ? nothing : DateTimeNs{T}(parsed)
end
Dates.default_format(::Type{DateTimeNs{T}}) where {T<:Dates.AbstractDateTime} = Dates.default_format(T)

Base.eps(::Type{<:DateTimeNs}) = Dates.Nanosecond(1)
Base.zero(::Type{<:DateTimeNs}) = Dates.Nanosecond(0)
Base.typemin(::Type{DateTimeNs{T}}) where {T<:Dates.AbstractDateTime} = DateTimeNs{T}(typemin(T), 0)
Base.typemax(::Type{DateTimeNs{T}}) where {T<:Dates.AbstractDateTime} = DateTimeNs{T}(typemax(T), 999_999)
Base.typeinfo_implicit(::Type{<:DateTimeNs}) = true

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
Dates.datetime2julian(x::DateTimeNs{Dates.DateTime}) =
    Dates.datetime2julian(x.datetime) + x.nanoseconds / (86_400 * 1e9)
Dates.isoyear(x::DateTimeNs) = Dates.isoyear(x.datetime)
Dates.isoweekdate(x::DateTimeNs) = Dates.isoweekdate(x.datetime)

for P in (:Year, :Quarter, :Month, :Week, :Day, :Hour, :Minute, :Second, :Millisecond)
    @eval Dates.$P(x::DateTimeNs) = Dates.$P(x.datetime)
end
Dates.Microsecond(x::DateTimeNs) = Dates.Microsecond(Dates.microsecond(x))
Dates.Nanosecond(x::DateTimeNs) = Dates.Nanosecond(Dates.nanosecond(x))

Base.convert(::Type{Dates.Date}, x::DateTimeNs) = Dates.Date(x)
Base.convert(::Type{Dates.Time}, x::DateTimeNs) = Dates.Time(x)
Base.convert(::Type{Dates.Millisecond}, x::DateTimeNs{Dates.DateTime}) = convert(Dates.Millisecond, x.datetime)
Base.convert(::Type{DateTimeNs{Dates.DateTime}}, x::Union{Dates.Date,Dates.Millisecond}) =
    DateTimeNs(convert(Dates.DateTime, x))
Base.promote_rule(::Type{Dates.Date}, ::Type{DateTimeNs{Dates.DateTime}}) = DateTimeNs{Dates.DateTime}

# `Dates.format` resolves to the millisecond.
Dates.format(io::IO, x::DateTimeNs, format::Dates.DateFormat) = Dates.format(io, x.datetime, format)
Dates.format(x::DateTimeNs, format::Dates.DateFormat) = Dates.format(x.datetime, format)
Dates.format(x::DateTimeNs, format::AbstractString; kwargs...) = Dates.format(x.datetime, format; kwargs...)

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
# An `Int64` of nanoseconds spans about 292 years; a longer difference throws `OverflowError`.
Base.:-(x::DateTimeNs, y::DateTimeNs) = Dates.Nanosecond(
    Base.checked_add(
        Base.checked_mul(Dates.value(Dates.Millisecond(x.datetime - y.datetime)), NANOSECONDS_PER_MILLISECOND),
        Int64(x.nanoseconds) - y.nanoseconds,
    ),
)
Base.:-(x::DateTimeNs{T}, y::T) where {T<:Dates.AbstractDateTime} = x - DateTimeNs(y)
Base.:-(x::T, y::DateTimeNs{T}) where {T<:Dates.AbstractDateTime} = DateTimeNs(x) - y

# `ceil` and `round` follow from `floor`.
Base.floor(x::DateTimeNs, p::Union{Dates.DatePeriod,Dates.Hour,Dates.Minute,Dates.Second,Dates.Millisecond}) =
    DateTimeNs(floor(x.datetime, p))
# Below a millisecond, a step that divides the millisecond floors within it, where counting from
# the epoch in nanoseconds would overflow.
function Base.floor(x::DateTimeNs, p::Union{Dates.Microsecond,Dates.Nanosecond})
    step = Dates.tons(p)
    step > 0 && iszero(rem(NANOSECONDS_PER_MILLISECOND, step)) ||
        throw(ArgumentError("rounding below a millisecond needs a positive step that divides it, got $p"))
    return DateTimeNs(x.datetime, x.nanoseconds - rem(x.nanoseconds, step))
end
Base.trunc(x::DateTimeNs, P::Type{<:Union{Dates.DatePeriod,Dates.Hour,Dates.Minute,Dates.Second,Dates.Millisecond}}) =
    DateTimeNs(trunc(x.datetime, P))
for f in (
    :firstdayofweek, :lastdayofweek, :firstdayofmonth, :lastdayofmonth,
    :firstdayofquarter, :lastdayofquarter, :firstdayofyear, :lastdayofyear,
)
    @eval Dates.$f(x::DateTimeNs) = DateTimeNs(Dates.$f(x.datetime))
end

function print_padded(io::IO, n::Integer, width::Integer)
    for _ in (ndigits(n) + 1):width
        print(io, '0')
    end
    print(io, n)
end

function Base.print(io::IO, x::DateTimeNs)
    local_time = Dates.DateTime(x.datetime)
    y = Dates.year(local_time)
    y < 0 && print(io, '-')
    print_padded(io, abs(y), 4)
    for (separator, part) in (
        ('-', Dates.month(local_time)), ('-', Dates.day(local_time)), ('T', Dates.hour(local_time)),
        (':', Dates.minute(local_time)), (':', Dates.second(local_time)),
    )
        print(io, separator)
        print_padded(io, part, 2)
    end
    fraction = Dates.millisecond(local_time) * NANOSECONDS_PER_MILLISECOND + x.nanoseconds
    if fraction > 0
        digits = 9
        while iszero(rem(fraction, 10))
            fraction = div(fraction, 10)
            digits -= 1
        end
        print(io, '.')
        print_padded(io, fraction, digits)
    end
    print_offset(io, x.datetime)
end

# The zone offset written after the time: none for a `DateTime`. The TimeZones extension writes
# that of a `ZonedDateTime`.
print_offset(::IO, ::Dates.DateTime) = nothing
Base.show(io::IO, x::DateTimeNs) = print(io, "DateTimeNs(", repr(x.datetime), ", ", x.nanoseconds, ")")
