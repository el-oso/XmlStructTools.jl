@testset "sample xml synthesis" begin
    @testset "basic_types — produces XML with all top-level element tags" begin
        xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "basic_types.xsd")
        xsd_tree = XsdToStruct.read_xsd(xsd_path)
        XsdToStruct.process_xsd_tree!(xsd_tree)

        outdir = mktempdir()
        sample_xml = open(joinpath(outdir, "top.jl"), "w") do io_top
            open(joinpath(outdir, "struct.jl"), "w") do io_struct
                xsd_module_builder = XsdToStruct.XSDStructModuleBuilderType(
                    indent_string = "    ",
                    xsd_tree = xsd_tree,
                    io_top = io_top,
                    io_struct = io_struct,
                    xsd_filename = "basic_types.xsd",
                )
                XsdToStruct.write_struct_module_to_io(xsd_module_builder)
                return XsdToStruct.synthesize_sample_xml(xsd_module_builder)
            end
        end

        @test !isnothing(sample_xml)
        # root element uses the schema's own root field name
        @test occursin("<document>", sample_xml)
        # nested complex fields recursed into
        @test occursin("<TestElement1>", sample_xml)
        @test occursin("<TestElement3>", sample_xml)
        # scalar leaves got dummy values
        @test occursin("<Element_string>x</Element_string>", sample_xml)
        @test occursin("<Element_boolean>false</Element_boolean>", sample_xml)
        @test occursin("<Element_dateTime>2000-01-01T00:00:00</Element_dateTime>", sample_xml)
        # TestElement2 is TestSimpleType1 (restriction base="string", pattern="([0-9A-Z]{4})?") —
        # resolved one level to its base scalar shape ("String") and got a dummy value ("x") that
        # doesn't match the pattern at all. Only possible because the workload calls load() with
        # validate=false, which skips AbstractXsdTypes.check_restrictions entirely.
        @test occursin("<TestElement2>x</TestElement2>", sample_xml)
    end

    @testset "choice_element — only the first choice option is emitted" begin
        xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "choice_element.xsd")
        xsd_tree = XsdToStruct.read_xsd(xsd_path)
        XsdToStruct.process_xsd_tree!(xsd_tree)

        outdir = mktempdir()
        sample_xml = open(joinpath(outdir, "top.jl"), "w") do io_top
            open(joinpath(outdir, "struct.jl"), "w") do io_struct
                xsd_module_builder = XsdToStruct.XSDStructModuleBuilderType(
                    indent_string = "    ",
                    xsd_tree = xsd_tree,
                    io_top = io_top,
                    io_struct = io_struct,
                    xsd_filename = "choice_element.xsd",
                )
                XsdToStruct.write_struct_module_to_io(xsd_module_builder)
                return XsdToStruct.synthesize_sample_xml(xsd_module_builder)
            end
        end

        @test !isnothing(sample_xml)
        @test occursin("<choice1>x</choice1>", sample_xml)
        @test !occursin("<choice2>", sample_xml)
    end

    @testset "optional_elements — can_be_missing fields are omitted" begin
        xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "optional_elements.xsd")
        xsd_tree = XsdToStruct.read_xsd(xsd_path)
        XsdToStruct.process_xsd_tree!(xsd_tree)

        outdir = mktempdir()
        sample_xml = open(joinpath(outdir, "top.jl"), "w") do io_top
            open(joinpath(outdir, "struct.jl"), "w") do io_struct
                xsd_module_builder = XsdToStruct.XSDStructModuleBuilderType(
                    indent_string = "    ",
                    xsd_tree = xsd_tree,
                    io_top = io_top,
                    io_struct = io_struct,
                    xsd_filename = "optional_elements.xsd",
                )
                XsdToStruct.write_struct_module_to_io(xsd_module_builder)
                return XsdToStruct.synthesize_sample_xml(xsd_module_builder)
            end
        end

        @test !isnothing(sample_xml)
        # TestComplexType1 (referenced by documentType's required TestElement1) mixes optional and
        # required fields: Element_string and Element_simple1 both have minOccurs="0"
        # (can_be_missing=true) and must be omitted; Element_double has no minOccurs at all
        # (can_be_missing=false, required) and must still appear with a dummy value.
        #
        # Scope these checks to TestElement1's own block, not the whole document: TestComplexType2
        # (TestElement2) also has a field literally named "Element_string" (default="aaa", no
        # minOccurs - so can_be_missing=false, required, correctly emitted) - a whole-document
        # occursin check would see that unrelated occurrence and give a false failure.
        te1_start = first(findfirst("<TestElement1>", sample_xml))
        te1_end = last(findfirst("</TestElement1>", sample_xml))
        te1_block = sample_xml[te1_start:te1_end]
        @test !occursin("<Element_string>", te1_block)
        @test !occursin("<Element_simple1>", te1_block)
        @test occursin("<Element_double>0</Element_double>", te1_block)
        # TestElement1 itself is a required field of documentType — still present
        @test occursin("<TestElement1>", sample_xml)
    end
end
