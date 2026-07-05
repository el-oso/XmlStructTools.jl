"""
    module TestTypeInElement

This module was generated with XsdToStruct version 0.1.0 from "type_in_element.xsd".
All generated types are exported by this module and some meta data is included in the submodule __meta.

In order to use this module the following dependencies need to be installed:
    AbstractXsdTypes
    Reexport
    PrecompileTools
    XmlStructLoader

PrecompileTools and XmlStructLoader are required at load time (not just for calling load() yourself) - this module runs a load() warm-up during precompilation.

This module can be used/import as follows:

```julia
include("path/to/type_in_element.jl")
using .TestTypeInElement
```
or:
```julia
include("path/to/type_in_element.jl")
import .TestTypeInElement
```
"""
module TestTypeInElement

using Reexport

@reexport using AbstractXsdTypes

include("type_in_element_struct.jl")
@reexport using .TestTypeInElement_struct

module __meta

    import ..TestTypeInElement_struct

    root_type = TestTypeInElement_struct.documentType
    xsd_filename = "type_in_element.xsd"
    XsdToStruct_version = "0.1.0"

end

import PrecompileTools
import XmlStructLoader

const __XSDTOSTRUCT_SAMPLE_XML__ = """<document><TestSimple2>x</TestSimple2><TestComplex1><Element_string>x</Element_string><Element_double>0</Element_double><Element_boolean>false</Element_boolean></TestComplex1><TestComplex2>x</TestComplex2><TestComplex3>0</TestComplex3></document>"""

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
