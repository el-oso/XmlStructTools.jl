module TestSimpleContent_struct

import AbstractXsdTypes

"""
An example of a simple xsd type.
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
@inline AbstractXsdTypes.get_string_pattern_regex(::Type{TestSimpleType1})::Regex = r"\A(?:([0-9A-Z]{4})?)\z"

@inline AbstractXsdTypes.get_restriction_checks(::Type{TestSimpleType1}) = (
    AbstractXsdTypes.string_pattern_restriction_check, AbstractXsdTypes.string_length_restriction_check,)

export TestSimpleType1

"""
Example of a complex XSD type that uses an extended simple type.
"""
Base.@kwdef struct TestComplexType1 <: AbstractXsdTypes.AbstractXSDString
    value::TestSimpleType1
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
end

export TestComplexType1

Base.@kwdef struct documentType <: AbstractXsdTypes.AbstractXSDComplex
    TestElement1::TestComplexType1
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
end

export documentType

end
