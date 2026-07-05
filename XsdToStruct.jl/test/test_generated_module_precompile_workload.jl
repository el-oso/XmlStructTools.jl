function _extract_module_name(source::String)
    for line in split(source, '\n')
        m = match(r"^module\s+(\w+)", line)
        isnothing(m) || return Symbol(m[1])
    end
    return nothing
end

@testset "generated module @compile_workload" begin
    @testset "basic_types — generated file contains the workload, and a real load() still works after it" begin
        xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "basic_types.xsd")
        outdir = mktempdir()
        generated_path = xsd_to_struct_module(xsd_path, outdir)

        generated_source = read(generated_path, String)
        @test occursin("import PrecompileTools", generated_source)
        @test occursin("import XmlStructLoader", generated_source)
        @test occursin("PrecompileTools.@compile_workload", generated_source)
        @test occursin("validate = false", generated_source)
        # the workload's own try/catch specifically (indented one level under the workload block),
        # not just any occurrence of the words "try"/"catch" anywhere in the generated file
        @test occursin("    try\n", generated_source)
        @test occursin("    catch\n", generated_source)

        # @compile_workload's body only runs during real package precompilation, never under a
        # plain include() — so this include() only exercises the surrounding code (struct
        # definitions, the sample string, the file being syntactically valid), not the workload
        # body itself. A real load() call afterward must still return correct values.
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
        @test occursin("PrecompileTools.@compile_workload", read(generated_path, String))
    end

    @testset "basic_types — workload also warms the ReadOnAccess (lazy) path" begin
        xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "basic_types.xsd")
        outdir = mktempdir()
        generated_path = xsd_to_struct_module(xsd_path, outdir)
        source = read(generated_path, String)

        @test occursin("ReadOnAccess", source)
    end
end
