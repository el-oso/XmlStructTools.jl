"""
    module TestComplexAndSimple

This module was generated with XsdToStruct version 0.1.0 from "basic_types.xsd".
All generated types are exported by this module and some meta data is included in the submodule __meta.

In order to use this module the following dependencies need to be installed:
    AbstractXsdTypes
    Reexport
    XmlStructLoader
    Dates
    TimeZones

This module can be used/import as follows:

```julia
include("path/to/basic_types.jl")
using .TestComplexAndSimple
```
or:
```julia
include("path/to/basic_types.jl")
import .TestComplexAndSimple
```
"""
module TestComplexAndSimple

using Reexport

@reexport using AbstractXsdTypes

include("basic_types_struct.jl")
@reexport using .TestComplexAndSimple_struct

import XmlStructLoader

const __XSDTOSTRUCT_SAMPLE_XML__ = """<document><TestElement1><Element_string>x</Element_string><Element_double>0</Element_double><Element_boolean>false</Element_boolean><Element_decimal>0</Element_decimal><Element_dateTime>2000-01-01T00:00:00</Element_dateTime><Element_integer>0</Element_integer><Element_nonNegativeInteger>0</Element_nonNegativeInteger><Element_positiveInteger>0</Element_positiveInteger></TestElement1><TestElement2>x</TestElement2><TestElement3><Element_string>x</Element_string><Element_double>0</Element_double><Element_dateTime>2000-01-01T00:00:00</Element_dateTime></TestElement3></document>"""

try
    XmlStructLoader.load(IOBuffer(__XSDTOSTRUCT_SAMPLE_XML__), @__MODULE__; validate = false)
catch
end

module __meta

    import ..TestComplexAndSimple_struct

    root_type = TestComplexAndSimple_struct.documentType
    xsd_filename = "basic_types.xsd"
    XsdToStruct_version = "0.1.0"

end

end
