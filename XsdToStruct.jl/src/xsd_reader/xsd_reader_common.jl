function parse_xsd_element_field(xsd_element::XMLElement)::FieldData
    # Extract a field name and field type from the given xsd element.

    attribute_dict = xsd_attributes_dict(xsd_element)
    element_name = pop!(attribute_dict, "name")
    element_type = xsd_type_reference(pop!(attribute_dict, "type"))

    return FieldData(name = element_name, xsd_type = element_type, xsd_attributes = attribute_dict)
end

function parse_restriction(xsd_modification::XMLElement)::Dict{String, String}
    restriction_dict = Dict{String, String}([("base", xsd_type_reference(xsd_attribute(xsd_modification, "base")))])

    for child in xsd_child_elements(xsd_modification)
        facet = xsd_element_name(child)
        value = xsd_attribute(child, "value")
        if facet == "enumeration" || facet == "annotation"
            continue
        elseif facet == "pattern" && haskey(restriction_dict, "pattern")
            # Patterns in one restriction are alternatives: a value matches any one of them.
            restriction_dict["pattern"] = "($(restriction_dict["pattern"]))|($value)"
        else
            restriction_dict[facet] = value
        end
    end

    return restriction_dict
end

parse_enumeration(xsd_restriction::XMLElement)::Vector{String} =
    [xsd_attribute(facet, "value") for facet in xsd_find_all_elements(xsd_restriction, "enumeration")]

function get_xsd_docstring(
        xsd_node::XMLElement;
        extra_docstring::Union{Nothing, AbstractString} = nothing,
    )::Union{Nothing, String}
    annotation_node = xsd_find_element(xsd_node, "annotation")
    if isnothing(annotation_node)
        docstring = nothing
    else
        documentation_node = xsd_find_element(annotation_node, "documentation")
        docstring = isnothing(documentation_node) ? nothing : xsd_content(documentation_node)
    end

    # append to option extra docstring
    if !isnothing(extra_docstring)
        docstring = isnothing(docstring) ? extra_docstring : extra_docstring * "\n" * docstring
    end

    return docstring
end

sub_module_name(parent_name::AbstractString)::String = "$(parent_name)Types"
