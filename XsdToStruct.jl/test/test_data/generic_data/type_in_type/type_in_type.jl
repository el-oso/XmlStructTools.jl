"""
    module TestTypeInType

This module was generated with XsdToStruct version 0.1.0 from "type_in_type.xsd".
All generated types are exported by this module and some meta data is included in the submodule __meta.

In order to use this module the following dependencies need to be installed:
    AbstractXsdTypes
    Reexport
    PrecompileTools
    XmlStructLoader
    Dates
    TimeZones

PrecompileTools and XmlStructLoader are required at load time (not just for calling load() yourself) - this module runs a load() warm-up during precompilation.

This module can be used/import as follows:

```julia
include("path/to/type_in_type.jl")
using .TestTypeInType
```
or:
```julia
include("path/to/type_in_type.jl")
import .TestTypeInType
```
"""
module TestTypeInType

using Reexport

@reexport using AbstractXsdTypes

include("type_in_type_struct.jl")
@reexport using .TestTypeInType_struct

module __meta

    import ..TestTypeInType_struct

    root_type = TestTypeInType_struct.documentType
    xsd_filename = "type_in_type.xsd"
    XsdToStruct_version = "0.1.0"

end

import PrecompileTools
import XmlStructLoader

const __XSDTOSTRUCT_SAMPLE_XML__ = """<document><TestElement1><A><Element_string>x</Element_string><Element_double>0</Element_double><Element_boolean>false</Element_boolean><Element_dateTime>2000-01-01T00:00:00+00:00</Element_dateTime></A><B>x</B><C><Element_string>x</Element_string><Element_double>0</Element_double><Element_boolean>false</Element_boolean><Element_dateTime>2000-01-01T00:00:00+00:00</Element_dateTime></C></TestElement1><TestElement2><A>x</A><B>x</B></TestElement2><TestElement3><A>x</A><S1>x</S1><B>x</B><S2>x</S2></TestElement3></document>"""

PrecompileTools.@compile_workload begin
    try
    __xsdtostruct_sample_path__ = tempname()
    write(__xsdtostruct_sample_path__, __XSDTOSTRUCT_SAMPLE_XML__)
    XmlStructLoader.load(__xsdtostruct_sample_path__, @__MODULE__; validate = false)
    rm(__xsdtostruct_sample_path__; force = true)
    catch
    end
end

end
