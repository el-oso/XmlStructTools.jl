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

    # AbstractXsdTypes.print_tree(...; print_all=true), as of the Task 2 fix, deliberately never
    # materializes an uninit lazy field itself (it prints "uninit" and moves on) - print_all only
    # controls whether an *already-materialized* nested complex value is recursed into. So getting
    # a "fully materialized" string requires touching every field ourselves first (forcing exactly
    # the same accessor path a real caller would hit), then handing the now-fully-populated object
    # to print_tree purely for formatting.
    function force_materialize!(obj)::Nothing
        obj isa AbstractXsdTypes.AbstractXSDComplex || return nothing
        for name in Base.invokelatest(propertynames, obj)
            value = Base.invokelatest(getproperty, obj, name)
            if value isa AbstractXsdTypes.AbstractXSDComplex
                force_materialize!(value)
            elseif value isa AbstractVector
                foreach(force_materialize!, value)
            end
        end
        return nothing
    end

    function fully_materialized_tree_string(obj)::String
        Base.invokelatest(force_materialize!, obj)
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

@testitem "ReadOnAccess on a choice-bearing root type raises a clear ArgumentError, not a MethodError" setup=[LazyLoadTestHelpers] begin
    using XsdToStruct
    # Minimal schema whose root type is itself choice-bearing (unlike choice_element.xsd's
    # documentType, which only has choice-bearing *child* types - see the per-node dispatch
    # comment in XsdToStruct.jl/test/lazy_struct_codegen_tests.jl - so its root gets a lazy
    # constructor and doesn't exercise this path). is_lazy_capable (xsd_module_builder_common.jl)
    # excludes any type with a direct xs:choice field, so XsdToStruct never emits a
    # documentType(::LazyNode) constructor here.
    xsd_content = """
    <?xml version="1.0"?>
    <schema xmlns="http://www.w3.org/2001/XMLSchema" xmlns:tns="ChoiceRoot" targetNamespace="ChoiceRoot">
        <element name="document" type="tns:documentType"/>
        <complexType name="documentType">
            <choice>
                <element name="choice1" type="string"/>
                <element name="choice2" type="decimal"/>
            </choice>
        </complexType>
    </schema>
    """
    outdir = mktempdir()
    xsd_path = joinpath(outdir, "choice_root.xsd")
    write(xsd_path, xsd_content)
    generated_path = XsdToStruct.xsd_to_struct_module(xsd_path, outdir)
    Base.include(Main, generated_path)
    module_name = extract_generated_module_name(read(generated_path, String))
    module_ref = Base.invokelatest(getproperty, Main, module_name)

    xml_path = joinpath(outdir, "choice_root.xml")
    write(xml_path, """<tns:document xmlns:tns="ChoiceRoot"><choice1>a</choice1></tns:document>""")

    @test_throws ArgumentError Base.invokelatest(
        XmlStructLoader.load, xml_path, module_ref;
        load_strategy = XmlStructLoader.ReadOnAccess(), validate = false,
    )
end

@testitem "close_lazy_document! releases the pugixml document and is idempotent; no-op for ReadAllData" setup=[LazyLoadTestHelpers] begin
    using XsdToStruct
    xsd_path = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xsd")
    outdir = mktempdir()
    generated_path = XsdToStruct.xsd_to_struct_module(xsd_path, outdir)
    Base.include(Main, generated_path)
    module_name = extract_generated_module_name(read(generated_path, String))
    module_ref = Base.invokelatest(getproperty, Main, module_name)

    xml_path = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xml")
    lazy = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref; load_strategy = XmlStructLoader.ReadOnAccess(), validate = false)

    handle = getfield(lazy, :_node).owner
    @test handle.ptr != C_NULL
    XmlStructLoader.close_lazy_document!(lazy)
    @test handle.ptr == C_NULL
    # idempotent - closing an already-closed handle doesn't error
    XmlStructLoader.close_lazy_document!(lazy)
    @test handle.ptr == C_NULL

    eager = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref)
    @test XmlStructLoader.close_lazy_document!(eager) === nothing
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

@testitem "ReadAllData: attributes and validate survive on an empty-content complex element (regression)" setup=[LazyLoadTestHelpers] begin
    using XsdToStruct
    # Regression coverage for the xml_parser_in_module.jl fix (Task 6): an empty-content complex
    # element used to be constructed via bare T() - silently dropping any real XML attributes and
    # ignoring the caller's validate flag (always __validated=true). Zero-field complex type here
    # mirrors complex_content.xsd's Element_empty pattern.
    xsd_content = """
    <?xml version="1.0"?>
    <schema xmlns="http://www.w3.org/2001/XMLSchema" xmlns:tns="EmptyAttr" targetNamespace="EmptyAttr">
        <element name="document" type="tns:documentType"/>
        <complexType name="documentType">
            <sequence>
                <element name="TestElement3">
                    <complexType/>
                </element>
            </sequence>
        </complexType>
    </schema>
    """
    outdir = mktempdir()
    xsd_path = joinpath(outdir, "empty_attr.xsd")
    write(xsd_path, xsd_content)
    generated_path = XsdToStruct.xsd_to_struct_module(xsd_path, outdir)
    Base.include(Main, generated_path)
    module_name = extract_generated_module_name(read(generated_path, String))
    module_ref = Base.invokelatest(getproperty, Main, module_name)

    xml_path = joinpath(outdir, "empty_attr.xml")
    write(xml_path, """<tns:document xmlns:tns="EmptyAttr"><TestElement3 id="x"></TestElement3></tns:document>""")

    loaded = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref; validate = false)
    te3 = Base.invokelatest(getproperty, loaded, :TestElement3)
    @test getfield(te3, :__xml_attributes)["id"] == "x"
    @test getfield(te3, :__validated) == false
end
