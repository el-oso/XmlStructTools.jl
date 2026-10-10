module TestOutOfOrder_struct

import AbstractXsdTypes

"""
An example of an xsd type which used by another type that is defined before this one is defined.
"""
Base.@kwdef struct TestSimpleType1 <: AbstractXsdTypes.AbstractXSDString
    value::String
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
    function TestSimpleType1(
        value::AbstractString,
        __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
        __validated::Bool=true)
        if __validated
            AbstractXsdTypes.check_restrictions(TestSimpleType1, value)
        end
        return new(value, __xml_attributes, __validated)
    end
end

@inline AbstractXsdTypes.get_max_string_length(::Type{TestSimpleType1})::Int = 4
@inline AbstractXsdTypes.get_string_pattern_regex(::Type{TestSimpleType1})::Regex = r"\A(?:([0-9A-Z]{2,4})?)\z"

@inline AbstractXsdTypes.get_restriction_checks(::Type{TestSimpleType1}) = (
    AbstractXsdTypes.string_pattern_restriction_check, AbstractXsdTypes.string_length_restriction_check,)

export TestSimpleType1

"""
An example of an xsd type which uses another type that is defined after this one.
"""
Base.@kwdef struct TestComplexType1 <: AbstractXsdTypes.AbstractXSDComplex
    Element_order::TestSimpleType1
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
end

export TestComplexType1

"""
An example of an xsd type which uses another type that is defined after this one.
"""
Base.@kwdef struct TestSimpleType2 <: AbstractXsdTypes.AbstractXSDString
    value::TestSimpleType1
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
    function TestSimpleType2(
        value::AbstractString,
        __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
        __validated::Bool=true)
        if __validated
            AbstractXsdTypes.check_restrictions(TestSimpleType2, value)
        end
        return new(value, __xml_attributes, __validated)
    end
end

@inline AbstractXsdTypes.get_max_string_length(::Type{TestSimpleType2})::Int = 2

@inline AbstractXsdTypes.get_restriction_checks(::Type{TestSimpleType2}) = (
    AbstractXsdTypes.string_length_restriction_check,)

export TestSimpleType2

Base.@kwdef struct documentType <: AbstractXsdTypes.AbstractXSDComplex
    TestElement1::TestComplexType1
    TestElement2::TestSimpleType2
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
end

export documentType

end
