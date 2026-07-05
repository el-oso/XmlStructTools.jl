"""
    module TestDateFormats

This module was generated with XsdToStruct version 0.1.0 from "date_formats.xsd".
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
include("path/to/date_formats.jl")
using .TestDateFormats
```
or:
```julia
include("path/to/date_formats.jl")
import .TestDateFormats
```
"""
module TestDateFormats

using Reexport

@reexport using AbstractXsdTypes

include("date_formats_struct.jl")
@reexport using .TestDateFormats_struct

import PrecompileTools
import XmlStructLoader

const __XSDTOSTRUCT_SAMPLE_XML__ = """<document><TestElement1><Element_dateTime>2000-01-01T00:00:00</Element_dateTime></TestElement1></document>"""

PrecompileTools.@compile_workload begin
    try
        XmlStructLoader.load(IOBuffer(__XSDTOSTRUCT_SAMPLE_XML__), @__MODULE__; validate = false)
    catch
    end
end

module __meta

    import ..TestDateFormats_struct

    root_type = TestDateFormats_struct.documentType
    xsd_filename = "date_formats.xsd"
    XsdToStruct_version = "0.1.0"

end

end
