@testset "PugixmlDocumentHandle: finalizer frees exactly once, close() is idempotent" begin
    fixture = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xml")
    doc_ptr = XmlStructPugixml.parse_file(fixture)
    @test doc_ptr != C_NULL

    handle = XmlStructLoader.PugixmlDocumentHandle(doc_ptr)
    @test handle.ptr == doc_ptr

    close(handle)
    @test handle.ptr == C_NULL

    # idempotent: closing again, or letting the finalizer run, must not double-free
    close(handle)
    @test handle.ptr == C_NULL
    finalize(handle)
    @test handle.ptr == C_NULL
end

@testset "LazyNode: name/content/children/attributes match the eager abstraction layer" begin
    fixture = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xml")
    doc_ptr = XmlStructPugixml.parse_file(fixture)
    handle = XmlStructLoader.PugixmlDocumentHandle(doc_ptr)
    root_ptr = XmlStructPugixml.root(doc_ptr)
    root = XmlStructLoader.LazyNode(root_ptr, handle)

    @test XmlStructLoader.lazy_name(root) == XmlStructLoader.name(root_ptr)
    @test XmlStructLoader.lazy_haschildren(root) == XmlStructLoader.haschildren(root_ptr)
    @test XmlStructLoader.lazy_attributes_dict(root) == XmlStructLoader.getattributes_dict(root_ptr)

    children = XmlStructLoader.lazy_children(root)
    @test length(children) == length(XmlStructPugixml.element_children(root_ptr))
    @test all(c -> c.owner === handle, children)

    first_child_name = XmlStructLoader.lazy_name(first(children))
    found = XmlStructLoader.lazy_child_with_name(root, first_child_name, false)
    @test !isnothing(found)
    @test XmlStructLoader.lazy_name(found) == first_child_name

    @test isnothing(XmlStructLoader.lazy_child_with_name(root, "NoSuchElement", true))
    @test_throws ErrorException XmlStructLoader.lazy_child_with_name(root, "NoSuchElement", false)

    close(handle)
end

@testset "LazyNode survives GC pressure between accesses (finalizer safety)" begin
    fixture = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xml")
    doc_ptr = XmlStructPugixml.parse_file(fixture)
    handle = XmlStructLoader.PugixmlDocumentHandle(doc_ptr)
    root = XmlStructLoader.LazyNode(XmlStructPugixml.root(doc_ptr), handle)

    for _ in 1:5
        GC.gc(true)
        @test XmlStructLoader.lazy_name(root) == "TestComplexAndSimple:document"
        GC.gc(true)
        for child in XmlStructLoader.lazy_children(root)
            GC.gc(true)
            @test !isempty(XmlStructLoader.lazy_name(child))
        end
    end

    close(handle)
end
