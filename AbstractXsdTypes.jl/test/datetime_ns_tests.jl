using Dates
using TimeZones

Base.@kwdef struct DateTimeField
    required::Union{AbstractXsdTypes.DateTimeNs{DateTime}}
    optional::Union{Nothing, AbstractXsdTypes.DateTimeNs{DateTime}} = nothing
end

@testset "DateTimeNs" begin
    DateTimeNs = AbstractXsdTypes.DateTimeNs
    base = DateTime(2022, 5, 10, 10, 22, 49, 152)
    x = DateTimeNs(base, 557_500)

    @test_throws "must be in 0:999_999" DateTimeNs(base, 1_000_000)
    @test_throws "must be in 0:999_999" DateTimeNs(base, -1)

    @test (year(x), month(x), day(x), hour(x), minute(x), second(x)) == (2022, 5, 10, 10, 22, 49)
    @test (millisecond(x), microsecond(x), nanosecond(x)) == (152, 557, 500)
    @test (Date(x), DateTime(x)) == (Date(2022, 5, 10), base)
    @test Time(x) == Time(10, 22, 49, 152, 557, 500)

    @test string(x) == "2022-05-10T10:22:49.1525575"
    @test string(DateTimeNs(DateTime(2022, 5, 10, 10, 22, 49, 100))) == "2022-05-10T10:22:49.1"
    @test string(DateTimeNs(DateTime(2022, 5, 10, 10, 22, 49))) == "2022-05-10T10:22:49"
    @test string(DateTimeNs(DateTime(2022, 5, 10, 10, 22, 49), 1)) == "2022-05-10T10:22:49.000000001"

    # sub-millisecond periods carry into and borrow from the milliseconds
    @test x + Nanosecond(442_500) == DateTimeNs(base + Millisecond(1))
    @test x - Microsecond(600) == DateTimeNs(base - Millisecond(1), 957_500)
    @test x + Day(1) == DateTimeNs(base + Day(1), 557_500)
    @test (x + Nanosecond(5)) - x == Nanosecond(5)
    @test x - (x + Day(1)) == Nanosecond(-86_400_000_000_000)

    @test x < x + Nanosecond(1)
    @test base < x && x > base
    @test DateTimeNs(base) == base && base == DateTimeNs(base)
    @test DateTimeNs(base) != DateTimeNs(base, 1)
    @test hash(DateTimeNs(base)) == hash(base)
    @test Dict(base => 1)[DateTimeNs(base)] == 1

    @test floor(x, Hour) == DateTimeNs(DateTime(2022, 5, 10, 10))
    @test ceil(x, Second) == DateTimeNs(DateTime(2022, 5, 10, 10, 22, 50))
    @test trunc(x, Day) == DateTimeNs(DateTime(2022, 5, 10))
    @test firstdayofmonth(x) == DateTimeNs(DateTime(2022, 5, 1))
    @test length(x:Hour(1):(x + Day(1))) == 25
    @test length(x:Nanosecond(250_000):(x + Millisecond(1))) == 5
    @test Dates.format(x, "yyyy-mm-dd HH:MM") == "2022-05-10 10:22"
    @test datetime2unix(x) ≈ datetime2unix(base) + 557_500e-9

    # a field typed like a generated `xs:dateTime` field takes the plain value
    field = DateTimeField(required = base, optional = base)
    @test field.required isa DateTimeNs{DateTime}
    @test field.optional == DateTimeNs(base)
end

@testset "DateTimeNs - the methods of DateTime" begin
    DateTimeNs = AbstractXsdTypes.DateTimeNs
    base = DateTime(2022, 5, 10, 10, 22, 49, 152)
    x = DateTimeNs(base, 557_500)

    @test DateTimeNs{DateTime}(2022, 5, 10, 10, 22, 49, 152, 557, 500) === x
    @test DateTimeNs(2022, 5) === DateTimeNs(DateTime(2022, 5))
    @test_throws "microsecond must be in 0:999" DateTimeNs{DateTime}(2022, 5, 10, 10, 22, 49, 152, 1000)
    @test DateTimeNs{DateTime}(
        Year(2022), Month(5), Day(10), Hour(10), Minute(22), Second(49), Millisecond(152), Microsecond(557),
        Nanosecond(500),
    ) === x
    @test DateTimeNs(Date(2022, 5, 10), Time(10, 22, 49, 152, 557, 500)) === x
    @test DateTimeNs{DateTime}(d -> dayofweek(d) == 1, 2022, 5) === DateTimeNs(DateTime(2022, 5, 2))
    @test DateTimeNs{DateTime}(d -> month(d) == 3, 2022) === DateTimeNs(DateTime(2022, 3))

    @test DateTimeNs{DateTime}("2022-05-10T10:22:49.1525575") === x
    @test DateTimeNs{DateTime}("2022-05-10T10:22:49.152") === DateTimeNs(base)
    @test_throws "more than nine digits" DateTimeNs{DateTime}("2022-05-10T10:22:49.1525575001")
    @test DateTimeNs{DateTime}("2022/05/10 10:22", "yyyy/mm/dd HH:MM") === DateTimeNs(DateTime(2022, 5, 10, 10, 22))
    @test parse(DateTimeNs{DateTime}, "2022-05-10T10:22:49.1525575") === x
    @test parse(DateTimeNs{DateTime}, "2022/05/10", dateformat"yyyy/mm/dd") === DateTimeNs(DateTime(2022, 5, 10))
    @test isnothing(tryparse(DateTimeNs{DateTime}, "not a date", dateformat"yyyy/mm/dd"))
    @test Dates.default_format(DateTimeNs{DateTime}) == Dates.default_format(DateTime)

    @test (Year(x), Quarter(x), Month(x), Week(x), Day(x)) == (Year(2022), Quarter(2), Month(5), Week(19), Day(10))
    @test (Hour(x), Minute(x), Second(x), Millisecond(x)) == (Hour(10), Minute(22), Second(49), Millisecond(152))
    @test (Microsecond(x), Nanosecond(x)) == (Microsecond(557), Nanosecond(500))
    @test (isoyear(x), isoweekdate(x)) == (isoyear(base), isoweekdate(base))
    @test datetime2julian(x) ≈ datetime2julian(base) + 557_500e-9 / 86_400

    @test convert(Date, x) == Date(2022, 5, 10)
    @test convert(Time, x) == Time(10, 22, 49, 152, 557, 500)
    @test convert(Millisecond, x) == convert(Millisecond, base)
    @test convert(DateTimeNs{DateTime}, Date(2022, 5, 10)) === DateTimeNs(DateTime(2022, 5, 10))
    @test convert(DateTimeNs{DateTime}, convert(Millisecond, base)) === DateTimeNs(base)
    @test Date(2022, 5, 10) < x < Date(2022, 5, 11)

    @test eps(x) == eps(DateTimeNs{DateTime}) == Nanosecond(1)
    @test zero(DateTimeNs{DateTime}) == Nanosecond(0)
    @test typemax(DateTimeNs{DateTime}) === DateTimeNs(typemax(DateTime), 999_999)
    @test typemin(DateTimeNs{DateTime}) === DateTimeNs(typemin(DateTime))
    @test Dates.format(x, dateformat"yyyy-mm-dd HH:MM:SS.sss") == "2022-05-10 10:22:49.152"
end

@testset "DateTimeNs - the methods of ZonedDateTime" begin
    DateTimeNs = AbstractXsdTypes.DateTimeNs
    base = DateTime(2022, 5, 10, 10, 22, 49, 152)
    x = DateTimeNs(base, 557_500)
    zoned = ZonedDateTime(base, tz"Europe/Brussels")
    zx = DateTimeNs(zoned, 557_500)

    @test string(DateTimeNs{ZonedDateTime}("2022-05-10T10:22:49.1525575+01:00")) == "2022-05-10T10:22:49.1525575+01:00"
    @test string(DateTimeNs{ZonedDateTime}("2022-05-10T10:22:49.1525575Z")) == "2022-05-10T10:22:49.1525575Z"
    @test DateTimeNs{ZonedDateTime}(x, tz"Europe/Brussels") == zx
    @test DateTimeNs{ZonedDateTime}(2022, 5, 10, 10, 22, 49, 152, 557, 500, tz"Europe/Brussels") == zx
    @test_throws "must be a time zone" DateTimeNs{ZonedDateTime}(2022, 5)
    @test_throws "must be a time zone" DateTimeNs{ZonedDateTime}(2022, 5, 10)

    @test timezone(zx) == TimeZone(zx) == tz"Europe/Brussels"
    @test FixedTimeZone(zx) == FixedTimeZone(zoned)
    @test string(astimezone(zx, tz"UTC")) == "2022-05-10T08:22:49.1525575Z"
    @test next_transition_instant(zx) == next_transition_instant(zoned)
    @test sprint(show_next_transition, zx) == sprint(show_next_transition, zoned)
    @test Date(zx, UTC) == Date(zoned, UTC)
    @test DateTime(zx, UTC) == DateTime(zoned, UTC)
    @test Time(zx, UTC) == Time(zoned, UTC) + Nanosecond(557_500)
    @test DateTime(zx, Local) == base
    @test ZonedDateTime(zx) === zoned
    @test ZonedDateTime(x, tz"Europe/Brussels") == zoned

    @test x + TimeZones.UTCOffset(3600) === DateTimeNs(base + Hour(1), 557_500)
    @test x - TimeZones.UTCOffset(3600) === DateTimeNs(base - Hour(1), 557_500)
    @test typemin(DateTimeNs{ZonedDateTime}) == DateTimeNs(typemin(ZonedDateTime))
    @test Dates.format(zx, "yyyy-mm-dd HH:MM zzz") == "2022-05-10 10:22 +02:00"
    @test zx > zoned && zoned < zx
end

@testset "DateTimeNs - mixed and edge cases" begin
    DateTimeNs = AbstractXsdTypes.DateTimeNs
    base = DateTime(2022, 5, 10, 10, 22, 49, 152)
    x = DateTimeNs(base, 557_500)
    zoned = ZonedDateTime(base, tz"Europe/Brussels")
    zx = DateTimeNs(zoned, 557_500)

    # subtraction with the wrapped type, both ways
    @test x - DateTime(2022, 5, 10) == Nanosecond(37_369_152_557_500)
    @test DateTime(2022, 5, 11) - x == Nanosecond(49_030_847_442_500)
    @test zx - ZonedDateTime(2022, 5, 10, tz"UTC") == Nanosecond(30_169_152_557_500)
    # a difference beyond what an Int64 of nanoseconds holds throws rather than wraps
    @test_throws OverflowError DateTimeNs(DateTime(2000)) - DateTimeNs(DateTime(1700))

    # an existing value is not wrapped again
    @test DateTimeNs(x) === x
    @test DateTimeNs{DateTime}(x) === x
    @test convert(DateTimeNs, x) === x
    @test convert(Union{Nothing,DateTimeNs}, x) === x

    @test floor(x, Microsecond(1)) === DateTimeNs(base, 557_000)
    @test ceil(x, Nanosecond(250)) === x
    @test round(x, Microsecond(1)) === DateTimeNs(base, 558_000)
    @test_throws "divides it" floor(x, Nanosecond(7))

    @test DateTimeNs(DateTime(2022, 5, 10)) == Date(2022, 5, 10)
    @test x != Date(2022, 5, 10)

    # the nanoseconds may be any number in range; `new` converts them
    @test DateTimeNs{DateTime}(base, 0x05) === DateTimeNs(base, 5)
    @test DateTimeNs{DateTime}(base, 5.0) === DateTimeNs(base, 5)
    @test_throws InexactError DateTimeNs{DateTime}(base, 5.5)
    @test_throws "no single integer value" Dates.value(x)
    @test DateTimeNs{ZonedDateTime}("2000-01-01T00:00:00.1+01:00") == DateTimeNs(ZonedDateTime(2000, 1, 1, 0, 0, 0, 100, tz"UTC+1"))

    @test string(DateTimeNs(DateTime(-1, 1, 2, 3, 4, 5, 6), 1)) == "-0001-01-02T03:04:05.006000001"
    @test string(DateTimeNs(DateTime(12, 1, 1))) == "0012-01-01T00:00:00"
    @test string(DateTimeNs(ZonedDateTime(DateTime(2022, 1, 1), FixedTimeZone("-05:30")))) == "2022-01-01T00:00:00-05:30"
    @test string(DateTimeNs(ZonedDateTime(DateTime(2022, 1, 1), FixedTimeZone("-00:00")))) == "2022-01-01T00:00:00Z"
    @test string(DateTimeNs(ZonedDateTime(DateTime(2022, 1, 1), FixedTimeZone("LMT", 1050)))) == "2022-01-01T00:00:00+00:17:30"
    @test string(zx) == "2022-05-10T10:22:49.1525575+02:00"
end
