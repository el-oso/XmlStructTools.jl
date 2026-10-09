
# generic test cases
@testset "xsd reader - generic data" begin
    for test_file in get_test_files(generic_data_dir)
        @testset "xsd reader - generic data - $(basename(test_file))" begin
            base_name = basename(test_file)
            input_path = test_file * ".xsd"
            expected_output_dir = test_file

            output_path = xsd_to_struct_module(input_path, output_dir)
            @test compare_all_text_files(dirname(output_path), expected_output_dir)
        end
    end
end

# edge cases
@testset "xsd reader - edge cases" begin
    @testset "xsd reader - edge cases - broken cases - $(basename(test_file))" for test_file in
        get_test_files(joinpath(edge_data_dir, "broken_cases"))
        @test_throws ErrorException xsd_to_struct_module(test_file * ".xsd", output_dir)
    end

    @testset "xsd reader - edge cases - name_clashes" begin
        file_name = "name_clashes"
        output_path = xsd_to_struct_module(
            joinpath(edge_data_dir, "$file_name.xsd"),
            output_dir;
            mapping = Dict(
                "Fields" => Dict("Number" => "Number_mapped", "Float64" => "Float64_mapped"),
                "Types" => Dict(
                    "TestElement3" => "TestElement3_mapped",
                    "Number" => "Number_mapped",
                    "Float64" => "Float64_mapped",
                ),
            ),
        )
        @test compare_all_text_files(dirname(output_path), joinpath(edge_data_dir, file_name))
    end
end

@testset "xsd reader - name mapping" begin
    flat = XsdToStruct.NameMapping(Dict("a" => "b"))
    @test flat.fields == flat.types == Dict("a" => "b")

    nested = XsdToStruct.NameMapping(Dict("Fields" => Dict("a" => "b"), "Types" => Dict("C" => "D")))
    @test nested.fields == Dict("a" => "b")
    @test nested.types == Dict("C" => "D")

    types_only = XsdToStruct.NameMapping(Dict("Fields" => Dict(), "Types" => Dict("C" => "D")))
    @test isempty(types_only.fields)
    @test XsdToStruct.NameMapping(Dict("Types" => Dict("C" => "D"))).types == Dict("C" => "D")

    @test_throws "may hold only those two keys" XsdToStruct.NameMapping(Dict("Fields" => Dict(), "Number" => "N"))

    @test XsdToStruct.map_xsd_name("ns:C", nested.types) == "ns:D"
    @test XsdToStruct.map_xsd_name("C", nested.types) == "D"
    @test XsdToStruct.map_xsd_name("ns:E", nested.types) == "ns:E"
    @test XsdToStruct.map_sub_module("CTypes.ETypes", nested.types) == "DTypes.ETypes"
    @test isnothing(XsdToStruct.map_sub_module(nothing, nested.types))
end

# specific examples
@testset "xsd reader - specific examples" begin
    for test_file in get_test_files(specific_data_dir)
        base_name = basename(test_file)
        input_path = test_file * ".xsd"
        expected_output_dir = test_file

        output_path = xsd_to_struct_module(input_path, output_dir)
        @test compare_all_text_files(dirname(output_path), expected_output_dir)
    end
end

# generic test cases with dict
@testset "xsd reader - generic data - dict" begin
    tmp_output_dir = output_dir * "_tmp"
    xsd_locations = Dict{String,String}()

    for test_file in get_test_files(generic_data_dir)
        xsd_locations[basename(test_file)] = generic_data_dir
    end

    generate_modules(xsd_locations, tmp_output_dir)

    for file_name in keys(xsd_locations)
        @test isfile(joinpath(tmp_output_dir, file_name, file_name * ".jl"))
    end

    rm(tmp_output_dir, recursive = true)
end

@testset "xsd reader - name mapping - schema name" begin
    xsd_path = joinpath(generic_data_dir, "basic_types.xsd")
    schema_name = XsdToStruct.name(XsdToStruct.read_xsd(xsd_path))
    @test_throws "the module name cannot be renamed" xsd_to_struct_module(
        xsd_path,
        output_dir;
        mapping = Dict(schema_name => "Renamed"),
    )
end
