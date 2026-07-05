"""
    module TestTypeInElement

This module was generated with XsdToStruct version 0.1.0 from "type_in_element.xsd".
All generated types are exported by this module and some meta data is included in the submodule __meta.

In order to use this module the following dependencies need to be installed:
    AbstractXsdTypes
    Reexport
    XmlStructLoader

This module can be used/import as follows:

```julia
include("path/to/type_in_element.jl")
using .TestTypeInElement
```
or:
```julia
include("path/to/type_in_element.jl")
import .TestTypeInElement
```
"""
module TestTypeInElement

using Reexport

@reexport using AbstractXsdTypes

include("type_in_element_struct.jl")
@reexport using .TestTypeInElement_struct

import XmlStructLoader

const __XSDTOSTRUCT_SAMPLE_XML__ = """<document><TestSimple2>x</TestSimple2><TestComplex1><Element_string>x</Element_string><Element_double>0</Element_double><Element_boolean>false</Element_boolean></TestComplex1><TestComplex2>x</TestComplex2><TestComplex3>0</TestComplex3></document>"""

try
    XmlStructLoader.load(IOBuffer(__XSDTOSTRUCT_SAMPLE_XML__), @__MODULE__; validate = false)
catch
end

module __meta

    import ..TestTypeInElement_struct

    root_type = TestTypeInElement_struct.documentType
    xsd_filename = "type_in_element.xsd"
    XsdToStruct_version = "0.1.0"

end

end
