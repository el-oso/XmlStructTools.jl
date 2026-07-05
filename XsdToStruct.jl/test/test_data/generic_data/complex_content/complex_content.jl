"""
    module TestComplexContent

This module was generated with XsdToStruct version 0.1.0 from "complex_content.xsd".
All generated types are exported by this module and some meta data is included in the submodule __meta.

In order to use this module the following dependencies need to be installed:
    AbstractXsdTypes
    Reexport
    XmlStructLoader
    Dates
    TimeZones

This module can be used/import as follows:

```julia
include("path/to/complex_content.jl")
using .TestComplexContent
```
or:
```julia
include("path/to/complex_content.jl")
import .TestComplexContent
```
"""
module TestComplexContent

using Reexport

@reexport using AbstractXsdTypes

include("complex_content_struct.jl")
@reexport using .TestComplexContent_struct

import XmlStructLoader

const __XSDTOSTRUCT_SAMPLE_XML__ = """<document><TestElement2><Element_string>x</Element_string><Element_double>0</Element_double><Element_boolean>false</Element_boolean><Element_decimal>0</Element_decimal><Element_dateTime>2000-01-01T00:00:00</Element_dateTime><Element_integer>0</Element_integer><Element_nonNegativeInteger>0</Element_nonNegativeInteger><Element_positiveInteger>0</Element_positiveInteger><Element_integer_ext>0</Element_integer_ext><Element_boolean_ext>false</Element_boolean_ext></TestElement2><TestElement3><Element_string>x</Element_string><Element_double>0</Element_double><Element_boolean>false</Element_boolean><Element_decimal>0</Element_decimal><Element_dateTime>2000-01-01T00:00:00</Element_dateTime><Element_integer>0</Element_integer><Element_nonNegativeInteger>0</Element_nonNegativeInteger><Element_positiveInteger>0</Element_positiveInteger></TestElement3><TestElement5><simple1>0</simple1></TestElement5></document>"""

try
    XmlStructLoader.load(IOBuffer(__XSDTOSTRUCT_SAMPLE_XML__), @__MODULE__; validate = false)
catch
end

module __meta

    import ..TestComplexContent_struct

    root_type = TestComplexContent_struct.documentType
    xsd_filename = "complex_content.xsd"
    XsdToStruct_version = "0.1.0"

end

end
