"""
    module TestList

This module was generated with XsdToStruct version 0.1.0 from "list_content.xsd".
All generated types are exported by this module and some meta data is included in the submodule __meta.

In order to use this module the following dependencies need to be installed:
    AbstractXsdTypes
    Reexport
    XmlStructLoader

This module can be used/import as follows:

```julia
include("path/to/list_content.jl")
using .TestList
```
or:
```julia
include("path/to/list_content.jl")
import .TestList
```
"""
module TestList

using Reexport

@reexport using AbstractXsdTypes

include("list_content_struct.jl")
@reexport using .TestList_struct

import XmlStructLoader

const __XSDTOSTRUCT_SAMPLE_XML__ = """<document><TestElement1><Element_list_double>0</Element_list_double></TestElement1><TestElement2><Element_list_string>x</Element_list_string></TestElement2><TestElement3><Element_type4_list><Element_string>x</Element_string></Element_type4_list></TestElement3><TestElement5><Element_string>x</Element_string></TestElement5></document>"""

try
    XmlStructLoader.load(IOBuffer(__XSDTOSTRUCT_SAMPLE_XML__), @__MODULE__; validate = false)
catch
end

module __meta

    import ..TestList_struct

    root_type = TestList_struct.documentType
    xsd_filename = "list_content.xsd"
    XsdToStruct_version = "0.1.0"

end

end
