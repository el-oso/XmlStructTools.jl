"""
    module TestStackedSimple

This module was generated with XsdToStruct version 0.1.0 from "stacked_simple_types.xsd".
All generated types are exported by this module and some meta data is included in the submodule __meta.

In order to use this module the following dependencies need to be installed:
    AbstractXsdTypes
    Reexport
    PrecompileTools
    XmlStructLoader

PrecompileTools and XmlStructLoader are required at load time (not just for calling load() yourself) - this module runs a load() warm-up during precompilation.

This module can be used/import as follows:

```julia
include("path/to/stacked_simple_types.jl")
using .TestStackedSimple
```
or:
```julia
include("path/to/stacked_simple_types.jl")
import .TestStackedSimple
```
"""
module TestStackedSimple

using Reexport

@reexport using AbstractXsdTypes

include("stacked_simple_types_struct.jl")
@reexport using .TestStackedSimple_struct

module __meta

    import ..TestStackedSimple_struct

    root_type = TestStackedSimple_struct.documentType
    xsd_filename = "stacked_simple_types.xsd"
    XsdToStruct_version = "0.1.0"

end

import PrecompileTools
import XmlStructLoader

const __XSDTOSTRUCT_SAMPLE_XML__ = """<document><TestElement1>x</TestElement1><TestElement2>0</TestElement2></document>"""

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
