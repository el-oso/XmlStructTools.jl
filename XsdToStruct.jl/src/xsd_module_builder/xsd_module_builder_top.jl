function write_top_module_to_io(xsd_module_builder::XSDStructModuleBuilderType)::Nothing
    write_docstring_part(xsd_module_builder)

    writeln(xsd_module_builder, IOTop, "module $(xsd_module_builder.module_name)")

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "using Reexport")

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "@reexport using $ABSTRACT_TYPE_PACKAGE")

    write(xsd_module_builder, IOTop, "\n")

    write_struct_module_part(xsd_module_builder)

    write(xsd_module_builder, IOTop, "\n")

    write_precompile_workload_part(xsd_module_builder)

    write(xsd_module_builder, IOTop, "\n")

    write_meta_module_part(xsd_module_builder)

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "end")

    return nothing
end

function write_docstring_part(xsd_module_builder::XSDStructModuleBuilderType)::Nothing
    writeln(xsd_module_builder, IOTop, "\"\"\"")
    writeln(xsd_module_builder, IOTop, "module $(xsd_module_builder.module_name)", indent_level = 1)
    writeln(xsd_module_builder, IOTop)

    writeln(
        xsd_module_builder,
        IOTop,
        (
            "This module was generated with XsdToStruct version $(XsdToStruct.XsdToStruct_VERSION)" *
            " from \"$(xsd_module_builder.xsd_filename)\"."
        ),
    )
    writeln(
        xsd_module_builder,
        IOTop,
        "All generated types are exported by this module and some meta data is included in the submodule __meta.",
    )
    writeln(xsd_module_builder, IOTop)

    writeln(xsd_module_builder, IOTop, "In order to use this module the following dependencies need to be installed:")
    writeln(xsd_module_builder, IOTop, "AbstractXsdTypes", indent_level = 1)
    writeln(xsd_module_builder, IOTop, "Reexport", indent_level = 1)
    writeln(xsd_module_builder, IOTop, "PrecompileTools", indent_level = 1)
    writeln(xsd_module_builder, IOTop, "XmlStructLoader", indent_level = 1)
    if xsd_module_builder.xsd_tree.requires_TimeZones
        writeln(xsd_module_builder, IOTop, "Dates", indent_level = 1)
        writeln(xsd_module_builder, IOTop, "TimeZones", indent_level = 1)
    end
    writeln(xsd_module_builder, IOTop)

    writeln(xsd_module_builder, IOTop, "This module can be used/import as follows:")
    writeln(xsd_module_builder, IOTop)

    writeln(xsd_module_builder, IOTop, "```julia")
    writeln(xsd_module_builder, IOTop, "include(\"path/to/$(io_file_name(xsd_module_builder, IOTop))\")")
    writeln(xsd_module_builder, IOTop, "using .$(xsd_module_builder.module_name)")
    writeln(xsd_module_builder, IOTop, "```")
    writeln(xsd_module_builder, IOTop, "or:")
    writeln(xsd_module_builder, IOTop, "```julia")
    writeln(xsd_module_builder, IOTop, "include(\"path/to/$(io_file_name(xsd_module_builder, IOTop))\")")
    writeln(xsd_module_builder, IOTop, "import .$(xsd_module_builder.module_name)")
    writeln(xsd_module_builder, IOTop, "```")

    return writeln(xsd_module_builder, IOTop, "\"\"\"")
end

function write_abstract_module_part(xsd_module_builder::XSDStructModuleBuilderType)::Nothing
    open(joinpath(@__DIR__, "xsd_module_builder_top_abstract.jl"), "r") do abstract_module_source
        for line in eachline(abstract_module_source)
            writeln(xsd_module_builder, IOTop, line)
        end
    end

    return nothing
end

function write_struct_module_part(xsd_module_builder::XSDStructModuleBuilderType)::Nothing
    writeln(xsd_module_builder, IOTop, "include(\"$(io_file_name(xsd_module_builder, IOStruct))\")")
    writeln(xsd_module_builder, IOTop, "@reexport using .$(xsd_module_builder.module_name_struct)")

    return nothing
end

function write_precompile_workload_part(xsd_module_builder::XSDStructModuleBuilderType)::Nothing
    sample_xml = synthesize_sample_xml(xsd_module_builder)
    isnothing(sample_xml) && return nothing

    writeln(xsd_module_builder, IOTop, "import PrecompileTools")
    writeln(xsd_module_builder, IOTop, "import XmlStructLoader")

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "const __XSDTOSTRUCT_SAMPLE_XML__ = \"\"\"$sample_xml\"\"\"")

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "PrecompileTools.@compile_workload begin")
    writeln(xsd_module_builder, IOTop, "try", indent_level = 1)
    writeln(
        xsd_module_builder,
        IOTop,
        "XmlStructLoader.load(IOBuffer(__XSDTOSTRUCT_SAMPLE_XML__), @__MODULE__; validate = false)",
        indent_level = 2,
    )
    writeln(xsd_module_builder, IOTop, "catch", indent_level = 1)
    writeln(xsd_module_builder, IOTop, "end", indent_level = 1)
    writeln(xsd_module_builder, IOTop, "end")

    return nothing
end

function write_meta_module_part(xsd_module_builder::XSDStructModuleBuilderType)::Nothing
    writeln(xsd_module_builder, IOTop, "module __meta")

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "import ..$(xsd_module_builder.module_name_struct)", indent_level = 1)

    write(xsd_module_builder, IOTop, "\n")

    writeln(
        xsd_module_builder,
        IOTop,
        "root_type = $(xsd_module_builder.module_name_struct).$(xsd_module_builder.xsd_tree.root_field.julia_type)",
        indent_level = 1,
    )
    writeln(xsd_module_builder, IOTop, "xsd_filename = \"$(xsd_module_builder.xsd_filename)\"", indent_level = 1)
    writeln(xsd_module_builder, IOTop, "XsdToStruct_version = \"$(XsdToStruct.XsdToStruct_VERSION)\"", indent_level = 1)

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "end")

    return nothing
end
