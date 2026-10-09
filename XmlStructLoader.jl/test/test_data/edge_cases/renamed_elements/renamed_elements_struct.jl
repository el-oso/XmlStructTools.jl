module TestRenamedElements_struct

import AbstractXsdTypes

"""
A complex type whose name and element names are not Julia identifiers.
"""
Base.@kwdef struct RecordType <: AbstractXsdTypes.AbstractXSDComplex
    element_string::String
    element_double::Float64
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
end

export RecordType

Base.@kwdef struct documentType <: AbstractXsdTypes.AbstractXSDComplex
    single_record::RecordType
    repeated_record::Vector{RecordType}
    plain::String
    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing
    __validated::Bool = true
end

export documentType

end
