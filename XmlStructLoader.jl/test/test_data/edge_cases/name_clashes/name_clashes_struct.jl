module TestNameClashes_struct

import AbstractXsdTypes

"""
An example of a complex xsd type with clashing name.
"""
Base.@kwdef struct Number_mapped <: AbstractXsdTypes.AbstractXSDComplex
    Element_string::String
    Element_double::Float64
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
end

export Number_mapped

"""
An example of a simple xsd type with clashing name.
"""
Base.@kwdef struct Float64_mapped <: AbstractXsdTypes.AbstractXSDString
    value::String
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
    function Float64_mapped(
        value::AbstractString,
        __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,
        __validated::Bool=true)
        if __validated
            AbstractXsdTypes.check_restrictions(Float64_mapped, value)
        end
        return new(value, __xml_attributes, __validated)
    end
end

@inline AbstractXsdTypes.get_max_string_length(::Type{Float64_mapped})::Int = 4
@inline AbstractXsdTypes.get_string_pattern_regex(::Type{Float64_mapped})::Regex = r"\A(?:([0-9A-Z]{4})?)\z"

@inline AbstractXsdTypes.get_restriction_checks(::Type{Float64_mapped}) = (
    AbstractXsdTypes.string_pattern_restriction_check, AbstractXsdTypes.string_length_restriction_check,)

export Float64_mapped

"""
An example of a complex xsd type that has clashing name elements.
"""
Base.@kwdef struct TestComplex1 <: AbstractXsdTypes.AbstractXSDComplex
    Element_test::Float64_mapped
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
end

export TestComplex1

Base.@kwdef struct documentType <: AbstractXsdTypes.AbstractXSDComplex
    TestElement1::TestComplex1
    TestElement2::Number_mapped
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
end

export documentType

end
