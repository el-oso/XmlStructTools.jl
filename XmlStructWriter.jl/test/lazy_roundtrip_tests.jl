@testitem "writing a partially-touched lazy struct matches a fully-eager round-trip" begin
    using XsdToStruct, XmlStructLoader
    xsd_path = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xsd")
    xml_path = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xml")
    outdir = mktempdir()
    generated_path = XsdToStruct.xsd_to_struct_module(xsd_path, outdir)
    Base.include(Main, generated_path)
    module_name = nothing
    for line in split(read(generated_path, String), '\n')
        m = match(r"^module\s+(\w+)", line)
        isnothing(m) || (module_name = Symbol(m[1]); break)
    end
    module_ref = Base.invokelatest(getproperty, Main, module_name)

    eager = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref; validate = false)
    lazy = Base.invokelatest(
        XmlStructLoader.load, xml_path, module_ref;
        load_strategy = XmlStructLoader.ReadOnAccess(), validate = false,
    )

    # Deliberately touch only one field before writing - the writer's own recursive property walk
    # must still materialize everything it needs to serialize correctly.
    Base.invokelatest(getproperty, Base.invokelatest(getproperty, lazy, :TestElement1), :Element_string)

    eager_out = tempname()
    lazy_out = tempname()
    Base.invokelatest(XmlStructWriter.write_xml, eager, eager_out)
    Base.invokelatest(XmlStructWriter.write_xml, lazy, lazy_out)

    @test read(eager_out, String) == read(lazy_out, String)

    rm(eager_out; force = true)
    rm(lazy_out; force = true)
end
