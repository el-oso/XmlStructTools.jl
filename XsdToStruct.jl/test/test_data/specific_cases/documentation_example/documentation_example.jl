"""
    module DocumentationExample

This module was generated with XsdToStruct version 0.1.0 from "documentation_example.xsd".
All generated types are exported by this module and some meta data is included in the submodule __meta.

In order to use this module the following dependencies need to be installed:
    AbstractXsdTypes
    Reexport
    PrecompileTools
    XmlStructLoader

This module can be used/import as follows:

```julia
include("path/to/documentation_example.jl")
using .DocumentationExample
```
or:
```julia
include("path/to/documentation_example.jl")
import .DocumentationExample
```
"""
module DocumentationExample

using Reexport

@reexport using AbstractXsdTypes

include("documentation_example_struct.jl")
@reexport using .DocumentationExample_struct

import PrecompileTools
import XmlStructLoader

const __XSDTOSTRUCT_SAMPLE_XML__ = """<houseDescription><address><street>x</street><city>x</city><state>x</state><postalCode>0</postalCode></address><owner><name>x</name><address><street>x</street><city>x</city><state>x</state><postalCode>0</postalCode></address></owner><houseDescription><overallProperties><totalArea>0</totalArea><livableArea>0</livableArea></overallProperties><room><name>x</name><area>0</area></room></houseDescription></houseDescription>"""

PrecompileTools.@compile_workload begin
    try
        XmlStructLoader.load(IOBuffer(__XSDTOSTRUCT_SAMPLE_XML__), @__MODULE__; validate = false)
    catch
    end
end

module __meta

    import ..DocumentationExample_struct

    root_type = DocumentationExample_struct.HouseDescriptionDocumentType
    xsd_filename = "documentation_example.xsd"
    XsdToStruct_version = "0.1.0"

end

end
