function get_simple_type(xsd_root::XsdToStruct.XMLElement, name::String)
    elts = XsdToStruct.xsd_find_all_elements(xsd_root, "simpleType")
    xsd_element = first(el for el in elts if XsdToStruct.xsd_attribute(el, "name") == name)
    return xsd_element
end

function get_simple_type_tree(xsd_root::XsdToStruct.XMLElement, name::String)
    xsd_element = get_simple_type(xsd_root, name)
    tree = XsdToStruct.with_schema_namespaces(() -> XsdToStruct.parse_xsd_simple_type(xsd_element, name), xsd_root)
    return tree
end

@testset "XsdToStruct - XSD reader" begin
    @testset "XsdToStruct - XSD reader - SimpleTypes" begin
        xsd_path = joinpath(generic_data_dir, "simple_types.xsd")
        xsd_doc = XsdToStruct.xsd_parse_file(xsd_path)
        xsd_root = XsdToStruct.xsd_doc_root(xsd_doc)

        name = "TestSimpleType1"
        tree = get_simple_type_tree(xsd_root, name)

        @test tree isa XsdToStruct.SimpleTreeNode
        @test tree.field.julia_type == "String"
        @test tree.restrictions isa AbstractDict{String, String}
        @test tree.restrictions["pattern"] == "([0-9A-Z]{4})?"
        @test tree.restrictions["maxLength"] == "4"
    end

    @testset "XsdToStruct - XSD reader - SimpleType Union" begin
        xsd_path = joinpath(generic_data_dir, "union_types.xsd")
        xsd_doc = XsdToStruct.xsd_parse_file(xsd_path)
        xsd_root = XsdToStruct.xsd_doc_root(xsd_doc)

        # testing some internal functions work properly
        name = "TestDoubleRestrictedDouble"
        xsd_element = get_simple_type(xsd_root, name)
        @test XsdToStruct.is_union(xsd_element)
        tree = XsdToStruct.with_schema_namespaces(() -> XsdToStruct.parse_xsd_simple_type(xsd_element, name), xsd_root)
        @test length(tree.union_nodes) == 2
        @test XsdToStruct.qualified_name(tree.union_nodes[1]) == "$(name)Types.type_1"
        @test XsdToStruct.qualified_name(tree.union_nodes[2]) == "$(name)Types.type_2"

        name = "UnionType"
        xsd_element = get_simple_type(xsd_root, name)
        @test XsdToStruct.is_union(xsd_element)
        tree = XsdToStruct.with_schema_namespaces(() -> XsdToStruct.parse_xsd_simple_type(xsd_element, name), xsd_root)
        @test length(tree.union_nodes) == 2
        @test XsdToStruct.qualified_name(tree.union_nodes[1]) == "$(name)Types.type_1"
        @test XsdToStruct.qualified_name(tree.union_nodes[2]) == "$(name)Types.type_2"
    end

    @testset "XsdToStruct - XSD reader - Complex Type testing" begin
        xsd_path = joinpath(generic_data_dir, "complex_content.xsd")
        xsd_doc = XsdToStruct.xsd_parse_file(xsd_path)
        xsd_root = XsdToStruct.xsd_doc_root(xsd_doc)

        elts = XsdToStruct.xsd_find_all_elements(xsd_root, "complexType")
        TestComplexType1 = elts[1]
        @test XsdToStruct.xsd_attribute(TestComplexType1, "name") == "TestComplexType1"
        TestComplexType2 = elts[2]

        sequence = XsdToStruct.xsd_child_elements(TestComplexType1)[2]
        empty_element = last(XsdToStruct.xsd_child_elements(sequence))
        @test XsdToStruct.xsd_attribute(empty_element, "name") == "Element_empty"

        # this one errored in the past due to the empty element
        tree1 = XsdToStruct.with_schema_namespaces(() -> XsdToStruct.parse_xsd_complex_type(TestComplexType1, "TestComplexType1"), xsd_root)
        @test tree1 isa XsdToStruct.ComplexTreeNode
        first_child_field = first(tree1.child_fields)
        @test first_child_field.name == XsdToStruct.xsd_attribute(empty_element, "name")
        @test length(tree1.child_nodes) == 1
        empty_element_tree = tree1.child_nodes[1]
        @test empty_element_tree isa XsdToStruct.ComplexTreeNode
        @test isempty(empty_element_tree.fields)

        # second type is easier, it's just an extension of the first type
        tree2 = XsdToStruct.with_schema_namespaces(() -> XsdToStruct.parse_xsd_complex_type(TestComplexType2, "TestComplexType2"), xsd_root)
        @test tree2 isa XsdToStruct.ExtensionTreeNode
        @test tree2.base_name == "TestComplexType1"
    end
end

@testset "XsdToStruct - XSD reader - namespace with underscore" begin
    xsd_tree = XsdToStruct.read_xsd(joinpath(edge_data_dir, "underscore_in_name.xsd"))
    @test XsdToStruct.name(xsd_tree) == "TestName_1"
end

@testset "XsdToStruct - XSD reader - built-in types are found by namespace" begin
    dir = mktempdir()
    xsd_path = joinpath(dir, "named.xsd")
    write(
        xsd_path,
        """
        <xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="named" targetNamespace="named">
            <xsd:element name="document" type="documentType"/>
            <xsd:simpleType name="Name"><xsd:restriction base="xsd:unsignedByte"/></xsd:simpleType>
            <xsd:complexType name="documentType">
                <xsd:sequence>
                    <xsd:element name="own" type="Name"/>
                    <xsd:element name="built_in" type="xsd:Name"/>
                </xsd:sequence>
            </xsd:complexType>
        </xsd:schema>
        """,
    )
    tree = XsdToStruct.read_xsd(xsd_path)
    document = only(node for node in tree.child_nodes if node isa XsdToStruct.ComplexTreeNode)
    @test [field.julia_type for field in document.fields] == ["Name", "String"]
    name_type = only(node for node in tree.child_nodes if node isa XsdToStruct.SimpleTreeNode)
    @test name_type.field.julia_type == "UInt8"

    write(xsd_path, replace(read(xsd_path, String), "xmlns=\"named\"" => "xmlns:xs=\"named\""))
    @test_throws "binds the prefix `xs` to \"named\"" XsdToStruct.with_schema_namespaces(
        () -> XsdToStruct.xsd_type_reference("xs:Name"),
        XsdToStruct.xsd_doc_root(XsdToStruct.xsd_parse_file(xsd_path)),
    )
end

@testset "XsdToStruct - XSD patterns" begin
    @test XsdToStruct.xsd_pattern_regex("[A-Z]{2}\$") == r"\A(?:[A-Z]{2}\$)\z"
    @test occursin(XsdToStruct.xsd_pattern_regex("^a"), "^a")
    @test !occursin(XsdToStruct.xsd_pattern_regex("a"), "ba")
    @test occursin(XsdToStruct.xsd_pattern_regex("[^\$]\\."), "x.")
    @test_throws "subtracts a character class" XsdToStruct.xsd_pattern_regex("[a-z-[aeiou]]")
    # A hyphen before a class, outside any class, is a literal hyphen.
    @test occursin(XsdToStruct.xsd_pattern_regex("\\+[0-9]{1,3}-[0-9()+\\-]{1,30}"), "+31-(0)20")
    @test_throws "unfinished escape" XsdToStruct.xsd_pattern_regex("a\\")
end
