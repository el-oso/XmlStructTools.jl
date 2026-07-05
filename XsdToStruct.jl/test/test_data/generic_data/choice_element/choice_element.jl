"""
    module TestChoice

This module was generated with XsdToStruct version 0.1.0 from "choice_element.xsd".
All generated types are exported by this module and some meta data is included in the submodule __meta.

In order to use this module the following dependencies need to be installed:
    AbstractXsdTypes
    Reexport
    PrecompileTools
    XmlStructLoader

PrecompileTools and XmlStructLoader are required at load time (not just for calling load() yourself) - this module runs a load() warm-up during precompilation.

This module can be used/import as follows:

```julia
include("path/to/choice_element.jl")
using .TestChoice
```
or:
```julia
include("path/to/choice_element.jl")
import .TestChoice
```
"""
module TestChoice

using Reexport

@reexport using AbstractXsdTypes

include("choice_element_struct.jl")
@reexport using .TestChoice_struct

module __meta

    import ..TestChoice_struct

    root_type = TestChoice_struct.documentType
    xsd_filename = "choice_element.xsd"
    XsdToStruct_version = "0.1.0"

end

import PrecompileTools
import XmlStructLoader

const __XSDTOSTRUCT_SAMPLE_XML__ = """<document><TestElement1><element1>x</element1><choice1>x</choice1><element2>x</element2></TestElement1><TestElement2><choice1>x</choice1></TestElement2><TestElement5><choice1>x</choice1><choice3>x</choice3></TestElement5></document>"""

PrecompileTools.@compile_workload begin
    try
    __xsdtostruct_sample_path__ = tempname()
    write(__xsdtostruct_sample_path__, __XSDTOSTRUCT_SAMPLE_XML__)
    XmlStructLoader.load(__xsdtostruct_sample_path__, @__MODULE__; validate = false)
    __xsdtostruct_lazy_sample__ = XmlStructLoader.load(__xsdtostruct_sample_path__, @__MODULE__; validate = false, load_strategy = XmlStructLoader.ReadOnAccess())
    AbstractXsdTypes.print_tree(IOBuffer(), __xsdtostruct_lazy_sample__; print_all = true)
    rm(__xsdtostruct_sample_path__; force = true)
    catch
    end
end

end
