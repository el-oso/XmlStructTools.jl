"""
    module TestList

This module was generated with XsdToStruct version 0.1.0 from "list_content.xsd".
All generated types are exported by this module and some meta data is included in the submodule __meta.

In order to use this module the following dependencies need to be installed:
    AbstractXsdTypes
    Reexport
    PrecompileTools
    XmlStructLoader

PrecompileTools and XmlStructLoader are required at load time (not just for calling load() yourself) - this module runs a load() warm-up during precompilation.

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

module __meta

    import ..TestList_struct

    root_type = TestList_struct.documentType
    xsd_filename = "list_content.xsd"
    XsdToStruct_version = "0.1.0"

end

import PrecompileTools
import XmlStructLoader

const __XSDTOSTRUCT_SAMPLE_XML__ = """<document><TestElement1><Element_list_double>0</Element_list_double></TestElement1><TestElement2><Element_list_string>x</Element_list_string></TestElement2><TestElement3><Element_type4_list><Element_string>x</Element_string></Element_type4_list></TestElement3><TestElement5><Element_string>x</Element_string></TestElement5></document>"""

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
