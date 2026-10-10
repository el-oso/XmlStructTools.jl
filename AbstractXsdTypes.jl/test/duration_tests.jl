using Dates

struct BoundedWait <: AbstractXsdTypes.AbstractXSDDuration
    value::Dates.CompoundPeriod
    __xml_attributes::Union{Nothing, Dict{String, String}}
    __validated::Bool
    function BoundedWait(
        value::Union{Dates.Period, Dates.CompoundPeriod},
        __xml_attributes::Union{Nothing, Dict{String, String}} = nothing,
        __validated::Bool = true,
    )
        __validated && AbstractXsdTypes.check_restrictions(BoundedWait, value)
        return new(value, __xml_attributes, __validated)
    end
end
AbstractXsdTypes.get_min_value(::Type{BoundedWait}) = AbstractXsdTypes.parse_xsd_duration("PT0S")
AbstractXsdTypes.get_max_value(::Type{BoundedWait}) = AbstractXsdTypes.parse_xsd_duration("P30D")
AbstractXsdTypes.is_max_exclusive(::Type{BoundedWait}) = false
AbstractXsdTypes.get_restriction_checks(::Type{BoundedWait}) = (AbstractXsdTypes.bound_restriction_check,)

@testset "xs:duration" begin
    parse_duration = AbstractXsdTypes.parse_xsd_duration
    duration_string = AbstractXsdTypes.xsd_duration_string
    C = Dates.CompoundPeriod

    @test parse_duration("P1Y2M3DT4H5M6.5S") ==
          Year(1) + Month(2) + Day(3) + Hour(4) + Minute(5) + Second(6) + Millisecond(500)
    @test parse_duration("-PT30M") == C(Minute(-30))
    @test parse_duration("PT0.000000001S") == C(Nanosecond(1))
    for text in ("P1Y2M3DT4H5M6.5S", "-PT30M", "P1D", "PT36H", "P10M", "PT0.000000001S", "PT0S")
        @test duration_string(parse_duration(text)) == text
    end
    @test duration_string(parse_duration("P0D")) == "PT0S"
    @test duration_string(parse_duration("PT1.120S")) == "PT1.12S"
    @test duration_string(Week(2) + Hour(1)) == "P14DT1H"
    @test duration_string(C(Millisecond(1500))) == "PT1.5S"

    for text in ("P", "PT", "P1DT", "1D", "P-1D", "P1.5D", "P1S")
        @test_throws "is not an xs:duration" parse_duration(text)
    end
    @test_throws "more than nine digits" parse_duration("PT1.1234567890S")
    @test_throws "periods of both signs" duration_string(Day(1) - Hour(1))

    # Equal at all four reference dateTimes, ordered at all four, and undetermined.
    @test iszero(AbstractXsdTypes.compare_durations(C(Day(1)), C(Hour(24))))
    @test AbstractXsdTypes.compare_durations(C(Month(1)), C(Day(32))) == -1
    @test AbstractXsdTypes.compare_durations(C(Month(1)), C(Day(27))) == 1
    @test_throws "is undetermined" AbstractXsdTypes.compare_durations(C(Month(1)), C(Day(30)))
    @test_throws "is undetermined" AbstractXsdTypes.compare_durations(C(Year(1)), C(Day(365)))
end

@testset "xs:duration bounds" begin
    @test BoundedWait(Day(30)).value == Dates.CompoundPeriod(Day(30))
    @test BoundedWait(Hour(720)).value == Dates.CompoundPeriod(Day(30))
    @test_throws "exceeds the maximum value P30D" BoundedWait(Day(30) + Nanosecond(1))
    @test_throws "is less than the minimum value PT0S" BoundedWait(Second(0))
    @test_throws "is undetermined" BoundedWait(Month(1))
    @test !BoundedWait(Day(31), false).__validated
    @test string(BoundedWait(Hour(3))) == "3 hours"
end
