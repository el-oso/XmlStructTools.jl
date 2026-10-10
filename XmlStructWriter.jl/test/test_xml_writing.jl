
# input data directory
if VERSION < v"1.7"
    generic_data_dir = joinpath(pkgdir(XmlStructWriter), "test", "test_data", "generic_cases")
    output_dir = joinpath(pkgdir(XmlStructWriter), "test", "test_output")
else
    generic_data_dir = pkgdir(XmlStructWriter, "test", "test_data", "generic_cases")
    output_dir = pkgdir(XmlStructWriter, "test", "test_output")
end
if isdir(output_dir)
    # cleanup
    rm(output_dir, recursive = true)
end

# generate modules for loading
generate_modules(generic_data_dir)

# get files for testing
generic_test_files = get_test_files(generic_data_dir)

# generic test cases
@testset "writing - generic cases - $(basename(module_dir))" for (module_dir, xml_files) in generic_test_files
    if isempty(xml_files)
        module_ref = nothing
    else
        module_ref = XmlStructLoader.import_module_from_xml(xml_files |> first |> first, module_dir)
    end

    @testset "writing - generic cases - $(basename(module_dir)) - $(basename(xml_path))" for (
        xml_path,
        expected_path,
    ) in xml_files
        output_path = joinpath(output_dir, basename(xml_path))
        @test begin
            xml_loaded = load(xml_path, module_ref)
            write_xml(xml_loaded, output_path)
            compare_xml_files(expected_path, output_path)
        end
    end
end

# A module generated with renames writes each renamed field under its element name.
@testset "writing - renamed elements" begin
    mapping_data_dir = joinpath(dirname(generic_data_dir), "mapping_cases")
    module_path = xsd_to_struct_module(
        joinpath(mapping_data_dir, "renamed_elements.xsd"),
        output_dir;
        mapping = Dict(
            "record-type" => "RecordType",
            "single-record" => "single_record",
            "repeated-record" => "repeated_record",
            "Element-string" => "element_string",
            "Element-double" => "element_double",
        ),
    )
    xml_path = joinpath(mapping_data_dir, "renamed_elements.xml")
    module_ref = XmlStructLoader.import_module_from_xml(xml_path, dirname(module_path))
    xml_loaded = load(xml_path, module_ref)

    output_path = joinpath(output_dir, "renamed_elements.xml")
    write_xml(xml_loaded, output_path)
    @test compare_xml_files(xml_path, output_path)

    named_output_path = joinpath(output_dir, "renamed_elements_named_root.xml")
    write_xml(xml_loaded, "document", named_output_path)
    @test compare_xml_files(xml_path, named_output_path)
end

# Renames change only Julia names, so a document written through a module generated with every
# element and type renamed must match the one written through the plain module. Each module is
# included into a fresh module so the plain and renamed ones, which share a name, stay apart.
xsd_names(xsd_text::AbstractString, tags::AbstractString) =
    unique(m.captures[1] for m in eachmatch(Regex("<(?:\\w+:)?(?:$tags)\\s[^>]*?name=\"([^\"]+)\""), xsd_text))

@testset "writing - every element and type renamed - $(basename(module_dir))" for (module_dir, xml_files) in
    generic_test_files
    isempty(xml_files) && continue
    xsd_path = module_dir * ".xsd"
    xsd_text = read(xsd_path, String)
    schema_name = XsdToStruct.name(XsdToStruct.read_xsd(xsd_path))
    mapping = Dict(
        "Fields" => Dict(name => name * "_field" for name in xsd_names(xsd_text, "element")),
        "Types" => Dict(
            name => name * "_type" for name in xsd_names(xsd_text, "complexType|simpleType") if name != schema_name
        ),
    )
    plain = Base.include(Module(), xsd_to_struct_module(xsd_path, joinpath(output_dir, "plain")))
    renamed = Base.include(Module(), xsd_to_struct_module(xsd_path, joinpath(output_dir, "renamed"); mapping))
    renamed_root = Base.invokelatest(getglobal, Base.invokelatest(getglobal, renamed, :__meta), :root_type)
    @test all(field -> endswith(String(field), "_field") || startswith(String(field), "__"), fieldnames(renamed_root))

    @testset "$(basename(xml_path))" for (xml_path, _) in xml_files
        plain_path = joinpath(output_dir, "plain", basename(xml_path))
        renamed_path = joinpath(output_dir, "renamed", basename(xml_path))
        write_xml(Base.invokelatest(load, xml_path, plain), plain_path)
        write_xml(Base.invokelatest(load, xml_path, renamed), renamed_path)
        @test read(renamed_path, String) == read(plain_path, String)
    end
end

@testset "writing - a module storing the whole split mapping" begin
    split_module = Module()
    Core.eval(split_module, :(module __meta
        XSDMapping = Dict("Fields" => Dict("a-b" => "a_b"), "Types" => Dict("T" => "U"))
    end))
    @test XmlStructWriter.field_element_names(split_module) == Dict(:a_b => "a-b")

    flat_module = Module()
    Core.eval(flat_module, :(module __meta
        XSDMapping = Dict("Fields" => "fields", "a-b" => "a_b")
    end))
    @test XmlStructWriter.field_element_names(flat_module) == Dict(:fields => "Fields", :a_b => "a-b")
end

@testset "writing - durations" begin
    dir = mktempdir()
    xsd_path = joinpath(dir, "Durations.xsd")
    write(
        xsd_path,
        """
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:Durations="Durations" targetNamespace="Durations">
            <xs:element name="document" type="Durations:documentType"/>
            <xs:simpleType name="Wait"><xs:restriction base="xs:duration">
                <xs:maxInclusive value="P1D"/>
            </xs:restriction></xs:simpleType>
            <xs:complexType name="documentType"><xs:sequence>
                <xs:element name="at" type="xs:duration"/>
                <xs:element name="many" type="xs:duration" maxOccurs="unbounded"/>
                <xs:element name="wait" type="Durations:Wait"/>
                <xs:element name="fallback" type="xs:duration" default="PT1H" minOccurs="0"/>
            </xs:sequence></xs:complexType>
        </xs:schema>
        """,
    )
    module_dir = dirname(xsd_to_struct_module(xsd_path, dir))
    xml_path = joinpath(dir, "document.xml")
    write(
        xml_path,
        """<?xml version="1.0"?><Durations:document xmlns:Durations="Durations">""" *
        "<at>-P1Y2M3DT4H5M6.5S</at><many>P1D</many><many>PT0S</many><wait>PT0.25S</wait><fallback></fallback>" *
        "</Durations:document>",
    )
    output_path = joinpath(dir, "written.xml")
    write_xml(load(xml_path, module_dir), output_path)

    # The empty `fallback` is written with the schema's default.
    expected_path = joinpath(dir, "expected.xml")
    write(expected_path, replace(read(xml_path, String), "<fallback></fallback>" => "<fallback>PT1H</fallback>"))
    @test compare_xml_files(expected_path, output_path)
end

@testset "writing - a type no generated module carries" begin
    @test isnothing(XmlStructWriter.generated_module(Int))
    @test isempty(XmlStructWriter.field_element_names(nothing))
end
