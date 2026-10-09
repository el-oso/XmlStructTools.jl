
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

@testset "Edge tests load - dateTime to the nanosecond" begin
    DateTimeNs = XmlStructLoader.AbstractXsdTypes.DateTimeNs
    parse_date = XmlStructLoader.parse_xml_date
    base = DateTime(2022, 5, 10, 10, 22, 49, 152)

    @test parse_date("2022-05-10T10:22:49.152") === DateTimeNs(base)
    @test parse_date("2022-05-10T10:22:49.1525575") === DateTimeNs(base, 557_500)
    @test parse_date("2022-05-10T10:22:49.152557501") === DateTimeNs(base, 557_501)
    @test parse_date("2022-05-10T10:22:49.1525575+01:00") == DateTimeNs(ZonedDateTime(base, tz"UTC+1"), 557_500)
    @test parse_date("2022-05-10T10:22:49.1525575Z") == DateTimeNs(ZonedDateTime(base, tz"UTC"), 557_500)
    @test string(parse_date("2022-05-10T10:22:49.1525575Z")) == "2022-05-10T10:22:49.1525575Z"

    cut = @test_logs (:warn, r"anything below nanoseconds is cut off") parse_date("2022-05-10T10:22:49.1525575019")
    @test cut === DateTimeNs(base, 557_501)
end

Base.@kwdef struct BuilderProbe
    required::Int
    optional::Union{Nothing, String} = nothing
end

@testset "Edge tests load - keyword builders" begin
    both = XmlStructLoader.keyword_builder(BuilderProbe, [:required, :optional])
    @test XmlStructLoader.keyword_builder(BuilderProbe, [:required, :optional]) === both
    @test both(Any[1, "x"]) == BuilderProbe(1, "x")

    # A different set of names present gets its own builder, and the keyword defaults still apply.
    required_only = XmlStructLoader.keyword_builder(BuilderProbe, [:required])
    @test required_only !== both
    @test required_only(Any[2]) == BuilderProbe(2, nothing)

    @test_throws UndefKeywordError XmlStructLoader.keyword_builder(BuilderProbe, [:optional])(Any["y"])
end

# A schema with one element `at` of the simple type `body` defines. The module takes its name from
# the namespace prefix, so each schema needs its own `name` to get a module of its own.
function load_at(name::AbstractString, body::AbstractString, text::AbstractString)
    dir = mktempdir()
    xsd_path = joinpath(dir, name * ".xsd")
    write(
        xsd_path,
        """
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:$name="$name" targetNamespace="$name">
            <xs:element name="document" type="$name:documentType"/>
            $body
            <xs:complexType name="documentType">
                <xs:sequence><xs:element name="at" type="$name:At"/></xs:sequence>
            </xs:complexType>
        </xs:schema>
        """,
    )
    module_dir = dirname(xsd_to_struct_module(xsd_path, dir))
    xml_path = joinpath(dir, "document.xml")
    write(xml_path, """<?xml version="1.0"?><$name:document xmlns:$name="$name"><at>$text</at></$name:document>""")
    return Base.invokelatest(getproperty, load(xml_path, module_dir).at, :value)
end

@testset "Edge tests load - dateTime bounds" begin
    zoned_bounds = """
        <xs:simpleType name="At"><xs:restriction base="xs:dateTime">
            <xs:minInclusive value="2000-01-01T00:00:00Z"/><xs:maxExclusive value="2100-01-01T00:00:00.5Z"/>
        </xs:restriction></xs:simpleType>"""
    local_bounds = """
        <xs:simpleType name="At"><xs:restriction base="xs:dateTime">
            <xs:minExclusive value="2000-01-01T00:00:00"/><xs:maxInclusive value="2100-01-01T00:00:00.1525575"/>
        </xs:restriction></xs:simpleType>"""

    @test string(load_at("ZonedInside", zoned_bounds, "2022-05-10T10:22:49.1525575Z")) == "2022-05-10T10:22:49.1525575Z"
    @test_throws XmlStructLoader.AbstractXsdTypes.XSDValueRestrictionViolationError load_at("ZonedBelow", zoned_bounds, "1999-12-31T23:59:59.999999999Z")
    @test_throws XmlStructLoader.AbstractXsdTypes.XSDValueRestrictionViolationError load_at("ZonedAtMax", zoned_bounds, "2100-01-01T00:00:00.5Z")
    @test string(load_at("LocalAtMax", local_bounds, "2100-01-01T00:00:00.1525575")) == "2100-01-01T00:00:00.1525575"
    @test_throws XmlStructLoader.AbstractXsdTypes.XSDValueRestrictionViolationError load_at("LocalAbove", local_bounds, "2100-01-01T00:00:00.1525576")
    @test_throws "one has a zone offset and the other does not" load_at("Mixed", zoned_bounds, "2022-05-10T10:22:49")
end

@testset "Edge tests load - unions take the first member that accepts the text" begin
    union_of(first_base, second_base) = """
        <xs:simpleType name="At"><xs:union>
            <xs:simpleType><xs:restriction base="$first_base"/></xs:simpleType>
            <xs:simpleType><xs:restriction base="$second_base"/></xs:simpleType>
        </xs:union></xs:simpleType>"""
    stamp = "2022-05-10T10:22:49.1525575+01:00"

    @test string(load_at("DateFirstDate", union_of("xs:dateTime", "xs:double"), stamp)) == stamp
    @test load_at("DateFirstDouble", union_of("xs:dateTime", "xs:double"), "1.5") == 1.5
    @test load_at("DoubleFirstDouble", union_of("xs:double", "xs:dateTime"), "1.5") == 1.5
    @test string(load_at("DoubleFirstDate", union_of("xs:double", "xs:dateTime"), stamp)) == stamp
    @test_throws "is not a value of any member" load_at("Neither", union_of("xs:double", "xs:dateTime"), "neither")
end
