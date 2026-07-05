@testitem "basic_types (choice-free) generates a lazy struct with _node and @lazy fields" begin
    xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "basic_types.xsd")
    outdir = mktempdir()
    generated_path = xsd_to_struct_module(xsd_path, outdir)
    struct_path = joinpath(dirname(generated_path), "basic_types_struct.jl")
    source = read(struct_path, String)

    @test occursin("using LazilyInitializedFields", source)
    @test occursin("_node::Union{Nothing, XmlStructLoader.LazyNode}", source)
    @test occursin("@lazy Element_string::String = _init_Element_string", source)
    @test occursin("function TestComplexType1(node::XmlStructLoader.LazyNode)", source)
end

@testitem "choice_element (choice-bearing) keeps generating a plain, non-lazy struct" begin
    # documentType in this schema has no choice fields of its own (only its child types
    # TestComplexType1/2/5 do), so - per the per-node (not per-schema) dispatch this task adds to -
    # documentType itself becomes lazy while the choice-bearing types are untouched. So the
    # assertion is scoped to the choice-bearing struct itself, not the whole file.
    xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "choice_element.xsd")
    outdir = mktempdir()
    generated_path = xsd_to_struct_module(xsd_path, outdir)
    struct_path = joinpath(dirname(generated_path), "choice_element_struct.jl")
    source = read(struct_path, String)

    @test occursin("struct TestComplexType1 <: AbstractXsdTypes.AbstractXSDComplex", source)
    @test !occursin("@lazy struct TestComplexType1", source)
    @test occursin("function Base.getproperty(x::TestComplexType1, s::Symbol)", source)
end

@testitem "lazy struct can still be constructed eagerly via the outer keyword constructor" begin
    xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "basic_types.xsd")
    outdir = mktempdir()
    generated_path = xsd_to_struct_module(xsd_path, outdir)

    module_name = nothing
    for line in split(read(generated_path, String), '\n')
        m = match(r"^module\s+(\w+)", line)
        isnothing(m) || (module_name = Symbol(m[1]); break)
    end

    Base.include(Main, generated_path)
    generated_module = Base.invokelatest(getproperty, Main, module_name)
    struct_module = Base.invokelatest(getproperty, generated_module, Symbol(String(module_name) * "_struct"))

    # Same construction shape the eager path already relies on: T(; field=value, ..., __xml_attributes=, __validated=)
    te1_type = Base.invokelatest(getproperty, struct_module, :TestComplexType1)
    obj = Base.invokelatest(
        te1_type;
        Element_string = "aaaa",
        Element_double = 1.0,
        Element_boolean = true,
        Element_decimal = 1.0,
        Element_dateTime = Base.invokelatest(getproperty, generated_module, :DateTime)("2020-01-01T00:00:00"),
        Element_integer = 1,
        Element_nonNegativeInteger = 1,
        Element_positiveInteger = 1,
        __xml_attributes = nothing,
        __validated = true,
    )
    @test Base.invokelatest(getproperty, obj, :Element_string) == "aaaa"
end
