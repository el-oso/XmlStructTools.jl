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
