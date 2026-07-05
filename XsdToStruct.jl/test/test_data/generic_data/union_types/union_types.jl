"""
    module TestSimpleUnion

This module was generated with XsdToStruct version 0.1.0 from "union_types.xsd".
All generated types are exported by this module and some meta data is included in the submodule __meta.

In order to use this module the following dependencies need to be installed:
    AbstractXsdTypes
    Reexport
    XmlStructLoader

This module can be used/import as follows:

```julia
include("path/to/union_types.jl")
using .TestSimpleUnion
```
or:
```julia
include("path/to/union_types.jl")
import .TestSimpleUnion
```
"""
module TestSimpleUnion

using Reexport

@reexport using AbstractXsdTypes

include("union_types_struct.jl")
@reexport using .TestSimpleUnion_struct

import XmlStructLoader

const __XSDTOSTRUCT_SAMPLE_XML__ = """<document></document>"""

try
    XmlStructLoader.load(IOBuffer(__XSDTOSTRUCT_SAMPLE_XML__), @__MODULE__; validate = false)
catch
end

module __meta

    import ..TestSimpleUnion_struct

    root_type = TestSimpleUnion_struct.documentType
    xsd_filename = "union_types.xsd"
    XsdToStruct_version = "0.1.0"

end

end
