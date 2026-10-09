"""
    module TestNameClashes

This module was generated with XsdToStruct version 0.1.0 from "name_clashes.xsd".
All generated types are exported by this module and some meta data is included in the submodule __meta.

In order to use this module the following dependencies need to be installed:
    AbstractXsdTypes
    Reexport

This module can be used/import as follows:

```julia
include("path/to/name_clashes.jl")
using .TestNameClashes
```
or:
```julia
include("path/to/name_clashes.jl")
import .TestNameClashes
```
"""
module TestNameClashes

using Reexport

@reexport using AbstractXsdTypes

include("name_clashes_struct.jl")
@reexport using .TestNameClashes_struct

module __meta

    import ..TestNameClashes_struct

    root_name = "document"
    root_type = TestNameClashes_struct.documentType
    xsd_filename = "name_clashes.xsd"
    XsdToStruct_version = "0.1.0"
    XSDMapping = Dict{String, String}("Float64" => "Float64_mapped", "Number" => "Number_mapped")

end

end
