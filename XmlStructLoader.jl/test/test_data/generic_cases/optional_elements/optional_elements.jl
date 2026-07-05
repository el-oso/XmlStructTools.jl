"""
    module OptionalElements

This module was generated with XsdToStruct version 0.1.0 from "optional_elements.xsd".
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
include("path/to/optional_elements.jl")
using .OptionalElements
```
or:
```julia
include("path/to/optional_elements.jl")
import .OptionalElements
```
"""
module OptionalElements

using Reexport

@reexport using AbstractXsdTypes

include("optional_elements_struct.jl")
@reexport using .OptionalElements_struct

import PrecompileTools
import XmlStructLoader

const __XSDTOSTRUCT_SAMPLE_XML__ = """<document><TestElement1><Element_double>0</Element_double></TestElement1><TestElement2><Element_string>x</Element_string><Element_double>0</Element_double></TestElement2><TestElement3></TestElement3><TestElement4></TestElement4><TestElement5></TestElement5><TestElement6><Element_simple3>2000-01-01T00:00:00</Element_simple3></TestElement6></document>"""

PrecompileTools.@compile_workload begin
    try
        XmlStructLoader.load(IOBuffer(__XSDTOSTRUCT_SAMPLE_XML__), @__MODULE__; validate = false)
    catch
    end
end

module __meta

    import ..OptionalElements_struct

    root_type = OptionalElements_struct.documentType
    xsd_filename = "optional_elements.xsd"
    XsdToStruct_version = "0.1.0"

end

end
