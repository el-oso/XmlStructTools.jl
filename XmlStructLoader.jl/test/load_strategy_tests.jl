@testsetup module LazyLoadTestHelpers
    using AbstractXsdTypes
    export extract_generated_module_name, fully_materialized_tree_string

    function extract_generated_module_name(source::String)::Union{Symbol,Nothing}
        for line in split(source, '\n')
            m = match(r"^module\s+(\w+)", line)
            isnothing(m) || return Symbol(m[1])
        end
        return nothing
    end

    function fully_materialized_tree_string(obj)::String
        io = IOBuffer()
        Base.invokelatest(AbstractXsdTypes.print_tree, io, obj; print_all = true)
        return String(take!(io))
    end
end

@testitem "ReadOnAccess: load() returns a struct whose fields are readable and correct" setup=[LazyLoadTestHelpers] begin
    using XsdToStruct
    xsd_path = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xsd")
    outdir = mktempdir()
    generated_path = XsdToStruct.xsd_to_struct_module(xsd_path, outdir)
    Base.include(Main, generated_path)
    module_name = extract_generated_module_name(read(generated_path, String))
    module_ref = Base.invokelatest(getproperty, Main, module_name)

    xml_path = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xml")
    loaded = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref; load_strategy = XmlStructLoader.ReadOnAccess(), validate = false)

    te1 = Base.invokelatest(getproperty, loaded, :TestElement1)
    @test Base.invokelatest(getproperty, te1, :Element_string) == "aaaa"
    @test Base.invokelatest(getproperty, te1, :Element_double) == 100.22
end

@testitem "ReadOnAccess: a field whose type is a named simple type resolves correctly (regression)" setup=[LazyLoadTestHelpers] begin
    using XsdToStruct
    # Regression test for a bug found during Task 5 (self-review) and fixed directly: a lazy
    # field's eager-construction fallback (for any field whose own type isn't itself lazy-capable -
    # a named simple type, a choice-bearing complex type, or a zero-field complex type) built a
    # standalone XmlStructLoaderNode with parent=nothing, and the eager path's get_default
    # unconditionally dereferenced node.parent.type, throwing FieldError on first access. Fixed via
    # XmlStructLoader.field_parent_node, which supplies a real parent type without going through
    # the document-tree-walk entry point constructor. basic_types.xsd's TestElement2 (a named
    # simple type, TestSimpleType1) exercises exactly this path.
    xsd_path = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xsd")
    outdir = mktempdir()
    generated_path = XsdToStruct.xsd_to_struct_module(xsd_path, outdir)
    Base.include(Main, generated_path)
    module_name = extract_generated_module_name(read(generated_path, String))
    module_ref = Base.invokelatest(getproperty, Main, module_name)

    xml_path = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xml")
    eager = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref)
    lazy = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref; load_strategy = XmlStructLoader.ReadOnAccess(), validate = false)

    eager_value = Base.invokelatest(getproperty, eager, :TestElement2)
    lazy_value = Base.invokelatest(getproperty, lazy, :TestElement2)
    @test lazy_value == eager_value
end

@testitem "ReadOnAccess with validate=true raises ArgumentError before parsing" setup=[LazyLoadTestHelpers] begin
    using XsdToStruct
    xsd_path = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xsd")
    outdir = mktempdir()
    generated_path = XsdToStruct.xsd_to_struct_module(xsd_path, outdir)
    Base.include(Main, generated_path)
    module_name = extract_generated_module_name(read(generated_path, String))
    module_ref = Base.invokelatest(getproperty, Main, module_name)

    xml_path = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xml")
    @test_throws ArgumentError Base.invokelatest(
        XmlStructLoader.load, xml_path, module_ref;
        load_strategy = XmlStructLoader.ReadOnAccess(), validate = true,
    )
end

@testitem "ReadAllData remains the default and is unaffected" setup=[LazyLoadTestHelpers] begin
    using XsdToStruct
    xsd_path = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xsd")
    outdir = mktempdir()
    generated_path = XsdToStruct.xsd_to_struct_module(xsd_path, outdir)
    Base.include(Main, generated_path)
    module_name = extract_generated_module_name(read(generated_path, String))
    module_ref = Base.invokelatest(getproperty, Main, module_name)

    xml_path = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xml")
    loaded_default = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref)
    loaded_explicit = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref; load_strategy = XmlStructLoader.ReadAllData())
    te1_default = Base.invokelatest(getproperty, loaded_default, :TestElement1)
    te1_explicit = Base.invokelatest(getproperty, loaded_explicit, :TestElement1)
    @test Base.invokelatest(getproperty, te1_default, :Element_string) ==
          Base.invokelatest(getproperty, te1_explicit, :Element_string)
end
