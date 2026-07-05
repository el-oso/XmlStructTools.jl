"""
    module TestSimpleTyping

This module was generated with XsdToStruct version 0.1.0 from "simple_types.xsd".
All generated types are exported by this module and some meta data is included in the submodule __meta.

In order to use this module the following dependencies need to be installed:
    AbstractXsdTypes
    Reexport
    PrecompileTools
    XmlStructLoader

This module can be used/import as follows:

```julia
include("path/to/simple_types.jl")
using .TestSimpleTyping
```
or:
```julia
include("path/to/simple_types.jl")
import .TestSimpleTyping
```
"""
module TestSimpleTyping

using Reexport

@reexport using AbstractXsdTypes

include("simple_types_struct.jl")
@reexport using .TestSimpleTyping_struct

import PrecompileTools
import XmlStructLoader

const __XSDTOSTRUCT_SAMPLE_XML__ = """<document><TestElement1><TestElement1>x</TestElement1><TestElement2>0</TestElement2><TestElement3>false</TestElement3><TestElement4>0</TestElement4><TestElement5>0</TestElement5></TestElement1><TestElement2><TestElement11>x</TestElement11><TestElement12>x</TestElement12><TestElement21>0</TestElement21><TestElement22>0</TestElement22></TestElement2></document>"""

PrecompileTools.@compile_workload begin
    try
        XmlStructLoader.load(IOBuffer(__XSDTOSTRUCT_SAMPLE_XML__), @__MODULE__; validate = false)
    catch
    end
end

module __meta

    import ..TestSimpleTyping_struct

    root_type = TestSimpleTyping_struct.documentType
    xsd_filename = "simple_types.xsd"
    XsdToStruct_version = "0.1.0"

end

end
