
# input data
if VERSION < v"1.7"
    edge_data_dir = joinpath(pkgdir(XmlStructLoader), "test", "test_data", "edge_cases")
else
    edge_data_dir = pkgdir(XmlStructLoader, "test", "test_data", "edge_cases")
end

# generate modules for testing
generate_modules(edge_data_dir)

# These schemas are regenerated with renames: `renamed_elements` has element and type names that are
# not Julia identifiers, so its module only compiles with them.
xsd_to_struct_module(
    joinpath(edge_data_dir, "name_clashes.xsd");
    mapping = Dict("Number" => "Number_mapped", "Float64" => "Float64_mapped"),
)
const RENAMED_ELEMENTS_MAPPING = Dict(
    "record-type" => "RecordType",
    "single-record" => "single_record",
    "repeated-record" => "repeated_record",
    "Element-string" => "element_string",
    "Element-double" => "element_double",
)
xsd_to_struct_module(joinpath(edge_data_dir, "renamed_elements.xsd"); mapping = RENAMED_ELEMENTS_MAPPING)

# Listed after generation, so a module directory not yet generated is still found.
edge_test_files = get_test_files(edge_data_dir)

@testset "Edge tests load - renamed elements" begin
    xml_path = joinpath(edge_data_dir, "renamed_elements.xml")
    module_dir = joinpath(edge_data_dir, "renamed_elements")

    # Nothing has included this module yet, so the path form reads bindings newer than its caller.
    lazy = lazyload(xml_path, module_dir)
    @test lazy.single_record.element_string == "one"
    @test length(lazy.repeated_record) == 2
    @test lazy.repeated_record[2].element_double == 3.5

    module_ref = XmlStructLoader.import_module_from_xml(xml_path, module_dir)
    meta = Base.invokelatest(getglobal, module_ref, :__meta)
    @test Base.invokelatest(getglobal, meta, :XSDMapping) == RENAMED_ELEMENTS_MAPPING
    @test Base.invokelatest(getglobal, meta, :root_name) == "document"

    doc = load(xml_path, module_ref)
    @test doc.single_record.element_string == "one"
    @test doc.single_record.element_double == 1.5
    @test [record.element_string for record in doc.repeated_record] == ["two", "three"]
    @test doc.plain == "text"
    @test !haskey(doc.__xml_attributes, "__root_name")
    @test repr(XmlStructLoader.materialize(lazy)) == repr(doc)
    close(lazy)
end

# run tests
@testset "Edge tests load" begin
    @testset "Edge tests load - $(basename(module_dir))" for (module_dir, xml_files) in edge_test_files
        @info "Running edge tests load - $(basename(module_dir))"
        @testset "Edge tests load - $(basename(module_dir)) - $(basename(xml_path))" for xml_path in xml_files
            @info "Running edge tests load - $(basename(module_dir)) - $(basename(xml_path))"

            # with directory
            @test begin
                load(xml_path, module_dir)
                true
            end

            # with loaded module
            @test begin
                module_ref = XmlStructLoader.import_module_from_xml(xml_path, module_dir)
                load(xml_path, module_ref)
                true
            end
        end
    end
end

@testset "Edge tests load - element renames stored with type renames" begin
    split_module = Module()
    Core.eval(split_module, :(module __meta
        XSDMapping = Dict("Fields" => Dict("a-b" => "a_b"), "Types" => Dict("T" => "U"))
    end))
    @test XmlStructLoader.element_field_mapping(split_module) == Dict(Symbol("a-b") => :a_b)

    flat_module = Module()
    Core.eval(flat_module, :(module __meta
        XSDMapping = Dict("Fields" => "fields", "a-b" => "a_b")
    end))
    @test XmlStructLoader.element_field_mapping(flat_module) == Dict(:Fields => :fields, Symbol("a-b") => :a_b)
end

@testset "Edge tests load - dateTime fraction digits" begin
    @test XmlStructLoader.fraction_digit_count("2024-01-01T00:00:37") == 0
    @test XmlStructLoader.fraction_digit_count("2024-01-01T00:00:37.1") == 1
    @test XmlStructLoader.fraction_digit_count("2024-01-01T00:00:37.12+01:00") == 2
    @test XmlStructLoader.fraction_digit_count("-0001-01-01T00:00:37.123456Z") == 6
    @test XmlStructLoader.fraction_digit_count("2024-01-01") == 0
end
