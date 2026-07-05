"""
    module TestGroup

This module was generated with XsdToStruct version 0.1.0 from "group_element.xsd".
All generated types are exported by this module and some meta data is included in the submodule __meta.

In order to use this module the following dependencies need to be installed:
    AbstractXsdTypes
    Reexport
    PrecompileTools
    XmlStructLoader

PrecompileTools and XmlStructLoader are required at load time (not just for calling load() yourself) - this module runs a load() warm-up during precompilation.

This module can be used/import as follows:

```julia
include("path/to/group_element.jl")
using .TestGroup
```
or:
```julia
include("path/to/group_element.jl")
import .TestGroup
```
"""
module TestGroup

using Reexport

@reexport using AbstractXsdTypes

include("group_element_struct.jl")
@reexport using .TestGroup_struct

module __meta

    import ..TestGroup_struct

    root_type = TestGroup_struct.documentType
    xsd_filename = "group_element.xsd"
    XsdToStruct_version = "0.1.0"

end

import PrecompileTools
import XmlStructLoader

const __XSDTOSTRUCT_SAMPLE_XML__ = """<document><TestElement1><Element_string>x</Element_string><Element_double>0</Element_double><Element_boolean>false</Element_boolean></TestElement1><TestElement2><Element_string>x</Element_string><Element_double>0</Element_double><Element_boolean>false</Element_boolean><Element_boolean_second>false</Element_boolean_second><Element_string_2>x</Element_string_2><Element_double_2>0</Element_double_2><Element_boolean_2>false</Element_boolean_2></TestElement2><TestElement3><Element_string>x</Element_string><Element_double>0</Element_double><Element_boolean>false</Element_boolean><Element_boolean2>false</Element_boolean2></TestElement3></document>"""

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
