
get_xsd_files(directory::AbstractString)::Vector{String} =
    [file_path for file_path in readdir(directory; join = true) if splitext(file_path) |> last == ".xsd"]

"""
	generate_modules(directory::AbstractString)::Nothing

Function to generate Julia modules for all xsd files found in the given directory.
"""
function generate_modules(directory::AbstractString)::Nothing
    @info "generating Julia modules for xsd files found in directory $directory"
    for xsd_file in get_xsd_files(directory)
        xsd_to_struct_module(xsd_file)
    end
    return nothing
end

basename_startswith(file_path::AbstractString, start_string::AbstractString) =
    startswith(basename(file_path), start_string)

get_matching_xml_files(module_folder_path::AbstractString) = [
    file_path_i for file_path_i in readdir(dirname(module_folder_path); join = true) if (
        endswith(file_path_i, ".xml") &&
        basename_startswith(file_path_i, basename(module_folder_path)) &&
        !occursin("_expected", basename(file_path_i))
    )
]

get_matching_expected_files(module_folder_path::AbstractString) = [
    file_path_i for file_path_i in readdir(dirname(module_folder_path); join = true) if (
        endswith(file_path_i, ".xml") &&
        basename_startswith(file_path_i, basename(module_folder_path)) &&
        occursin("_expected", basename(file_path_i))
    )
]

get_base_name_without_extension(file_path::AbstractString) = join(split(basename(file_path), ".")[1:(end - 1)], ".")

get_test_files(data_dir) = [
    (file_path, zip(get_matching_xml_files(file_path), get_matching_expected_files(file_path))) for
    file_path in readdir(data_dir; join = true) if isdir(file_path)
]

function compare_xml_files(file_path_1::AbstractString, file_path_2::AbstractString)::Bool
    xml_doc_1 = parse_file(file_path_1)
    root_1 = root(xml_doc_1)

    xml_doc_2 = parse_file(file_path_2)
    root_2 = root(xml_doc_2)

    return compare_xml_elements(root_1, root_2)
end

function compare_xml_elements(element_1::XMLElement, element_2::XMLElement)::Bool
    if name(element_1) != name(element_2)
        @info "Element $(name(element_1)) is $(name(element_2)) in the second file"
        return false
    end

    child_iterator_1 = collect(child_elements(element_1))
    child_iterator_2 = collect(child_elements(element_2))
    # `has_children` also counts text, so a leaf is told apart by having no child elements.
    if !isempty(child_iterator_1) || !isempty(child_iterator_2)
        n_children_1 = length(child_iterator_1)
        n_children_2 = length(child_iterator_2)

        if n_children_1 != n_children_2
            if n_children_1 < n_children_2
                @info "Amount of children of $(name(element_1)) are different, first file has less children"
                return false
            else
                @info "Amount of children of $(name(element_1)) are different, second file has less children"
                return false
            end
        end

        for (child_1, child_2) in zip(child_iterator_1, child_iterator_2)
            if !compare_xml_elements(child_1, child_2)
                @info "Children of $(name(element_1)) are different"
                return false
            end
        end
    else
        # Numbers compare by value: the writer prints a Float64 as Julia does, `20.0` for `20`.
        content_1 = strip(content(element_1))
        content_2 = strip(content(element_2))
        number_1 = tryparse(Float64, content_1)
        number_2 = tryparse(Float64, content_2)
        same = isnothing(number_1) || isnothing(number_2) ? content_1 == content_2 : number_1 == number_2
        if !same
            @info "Content of $(name(element_1)) is different: $content_1 vs $content_2"
            return false
        end
    end

    # compare all attributes
    attributes_1 = attributes_dict(element_1)
    attributes_2 = attributes_dict(element_2)
    if attributes_1 != attributes_2
        @info "Attributes of $(name(element_1)) are different"
        return false
    end

    # everything is equal
    return true
end
