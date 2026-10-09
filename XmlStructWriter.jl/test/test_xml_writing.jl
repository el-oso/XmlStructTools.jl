
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
