
function parse_xml_node_in_module(node::XmlStructLoaderNode, module_ref::Module, validate::Bool)

    # this is parse_simple

    xml_node = node.node
    T = node.type
    default_value = get_default(node)

    if haschildren(xml_node)
        # T is a genuine multi-child complex type reached through the single-node eager-fallback
        # path (e.g. a lazy struct's field whose own type is a choice-bearing complex type, which -
        # unlike a choice-free complex type - has no per-field @lazy accessors of its own, so
        # materializing it needs a full eager construction). The "single field" branch below only
        # ever handled wrapper types (one value field); reuse the same subtree walk the document
        # root uses, just rooted here instead of at the true document root.
        child_object_dict = construct_xml_node_child_objects(xml_node, module_ref, validate; start_type = T)
        xml_attributes = getattributes_dict(xml_node)
        constructed_object = T(; __xml_attributes = xml_attributes, __validated = validate, child_object_dict...)
    elseif isempty(content(xml_node))
        if !isnothing(default_value)
            # no data in node, construct with default value
            @debug "Constructing $T with default value."
            constructed_object = T(value = default_value)
        elseif T <: module_ref.AbstractXsdTypes.AbstractXSDString && isnothing(default_value)
            # special case for empty string
            @debug "Constructing $T with empty string."
            constructed_object = T(value = "")
        elseif T <: module_ref.AbstractXsdTypes.AbstractXSDComplex && isnothing(default_value)
            @debug "Constructing $T with only default values."
            # Thread the real validate flag and this node's own (possibly non-empty) attributes
            # through - a bare T() would silently fall back to the type's own kwarg defaults
            # (__validated=true, __xml_attributes=nothing) regardless of what the caller actually
            # asked for, which is wrong for a validate=false caller and drops any real attributes
            # on an otherwise-empty tag (e.g. <TestElement3 id="x"></TestElement3>).
            constructed_object = T(; __xml_attributes = getattributes_dict(xml_node), __validated = validate)
        else
            @debug "Skip constructing $T, no node content or default value."
            constructed_object = nothing
        end
    else
        # data in node content, only a single field should be defined for type T apart from __xml_attributes
        field_type = get_base_field_type(T, 1)
        field_value =
            construct_xml_node_object(XmlStructLoaderNode(node.node, field_type, node.parent), module_ref, validate)
        xml_attributes = getattributes_dict(xml_node)  # get xml attributes
        @debug "Constructing $T with $field_value."
        constructed_object = T(field_value, xml_attributes, validate)
    end

    return constructed_object
end

function construct_xml_node_child_objects(
    @nospecialize(xml_node::UnifiedXMLElement),
    module_ref::Module,
    validate::Bool;
    start_type = module_ref.__meta.root_type,
)::Dict
    start_node = XmlStructLoaderNode(xml_node, start_type, nothing)

    fields = Dict{typeof(xml_node),Dict{Symbol,Any}}()

    for node in AbstractTrees.PostOrderDFS(start_node)
        isroot(node) && continue
        xml_child = node.node
        field_symbol = tag_symbol(name(xml_child))
        field_type = get_base_field_type(node.parent.type, field_symbol)
        @debug "Parsing: node ->\n\t$xml_child,\ntype -> $field_type"

        if !haschildren(xml_child)
            element = construct_xml_node_object(node, module_ref, validate)
        else
            xml_attributes = getattributes_dict(xml_child)
            child_object_dict = pop!(fields, xml_child)
            # construct object with child objects
            @debug begin
                child_string = join(["$key => $value" for (key, value) in child_object_dict], "\n")
                "Constructing: $field_type\n from children:\n\t$child_string"
            end

            if field_type <: Vector  # TODO:handle with dispatch in a minute
                T = eltype(field_type)
                element = [T(; __xml_attributes = xml_attributes, __validated = validate, child_object_dict...)]
            else
                element = field_type(; __xml_attributes = xml_attributes, __validated = validate, child_object_dict...)
            end
        end

        parent_key = AbstractTrees.parent(xml_child)
        working_dict = get!(() -> Dict{Symbol,Any}(), fields, parent_key)

        if field_type <: Vector  # TODO:handle with dispatch in a minute
            if haskey(working_dict, field_symbol)
                append!(working_dict[field_symbol], element)
            else
                working_dict[field_symbol] = element
            end
        else
            push!(working_dict, field_symbol => element)
        end
    end
    return fields |> first |> last |> Dict
end
