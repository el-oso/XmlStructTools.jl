function _extract_module_name(source::String)
    # Extract the module name from "module ModuleName"
    # Search through lines to find the module declaration (it comes after the docstring)
    for line in split(source, '\n')
        m = match(r"^module\s+(\w+)", line)
        if !isnothing(m)
            return Symbol(m[1])
        end
    end
    return nothing
end

@testset "generated module eager load() warm-up" begin
    @testset "basic_types — generated file contains the warm-up, and a real load() still works after it" begin
        xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "basic_types.xsd")
        outdir = mktempdir()
        generated_path = xsd_to_struct_module(xsd_path, outdir)

        generated_source = read(generated_path, String)
        @test occursin("import XmlStructLoader", generated_source)
        @test occursin("XmlStructLoader.load(", generated_source)
        @test occursin("validate = false", generated_source)
        @test occursin("try", generated_source)
        @test occursin("catch", generated_source)

        # the generated file must still be valid, loadable Julia, and a REAL load() against real
        # data (not the synthesized dummy) must still return correct values — this is the
        # no-contamination check: running the eager warm-up call at include-time must not leave
        # any state that corrupts a subsequent real load() in the same process.
        Base.include(Main, generated_path)
        module_name = _extract_module_name(generated_source)
        @test !isnothing(module_name)
        generated_module = Base.invokelatest(getproperty, Main, module_name)

        real_xml = joinpath(
            @__DIR__, "..", "..", "XmlStructLoader.jl", "test", "test_data", "generic_cases", "basic_types.xml",
        )
        loaded = Base.invokelatest(XmlStructLoader.load, real_xml, generated_module)

        test_element_1 = Base.invokelatest(getproperty, loaded, :TestElement1)
        @test Base.invokelatest(getproperty, test_element_1, :Element_string) == "aaaa"
        @test Base.invokelatest(getproperty, test_element_1, :Element_double) == 100.22
        @test Base.invokelatest(getproperty, test_element_1, :Element_boolean) == true
    end

    @testset "choice_element — generated file still generates cleanly for a choice-bearing schema" begin
        xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "choice_element.xsd")
        outdir = mktempdir()
        generated_path = xsd_to_struct_module(xsd_path, outdir)
        @test occursin("XmlStructLoader.load(", read(generated_path, String))
    end
end
