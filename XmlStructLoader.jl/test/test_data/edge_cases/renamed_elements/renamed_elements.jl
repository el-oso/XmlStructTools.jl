"""
    module TestRenamedElements

This module was generated with XsdToStruct version 0.1.0 from "renamed_elements.xsd".
All generated types are exported by this module and some meta data is included in the submodule __meta.

In order to use this module the following dependencies need to be installed:
    AbstractXsdTypes
    Reexport

This module can be used/import as follows:

```julia
include("path/to/renamed_elements.jl")
using .TestRenamedElements
```
or:
```julia
include("path/to/renamed_elements.jl")
import .TestRenamedElements
```
"""
module TestRenamedElements

using Reexport

@reexport using AbstractXsdTypes

include("renamed_elements_struct.jl")
@reexport using .TestRenamedElements_struct

module __meta

    import ..TestRenamedElements_struct

    root_name = "document"
    root_type = TestRenamedElements_struct.documentType
    xsd_filename = "renamed_elements.xsd"
    XsdToStruct_version = "0.1.0"
    XSDMapping = Dict{String, String}("Element-double" => "element_double", "Element-string" => "element_string", "record-type" => "RecordType", "repeated-record" => "repeated_record", "single-record" => "single_record")

end

end
