using Dates

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
