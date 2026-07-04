# Correctness check: run both the real (EzXML-backed) loader and the XML.jl prototype over every
# small fixture and confirm they produce identical results (compared via string repr, since the
# generated struct types have a custom Base.show via AbstractXsdTypes.print_tree - a structural
# diff would need per-type field walking, string comparison is simpler and sufficient here).

include("loader_xmljl.jl")
using XmlStructLoader, XsdToStruct

include("../../test/test_utilities.jl")
generic_data_dir = joinpath(@__DIR__, "..", "..", "test", "test_data", "generic_cases")
test_files = get_test_files(generic_data_dir)

n_ok = 0
n_fail = 0
for (module_dir, xml_files) in test_files
    isempty(xml_files) && continue
    module_name = basename(module_dir)
    for xml_path in xml_files
        real_ref = XmlStructLoader.import_module_from_xml(xml_path, module_dir)
        real_result = XmlStructLoader.load(xml_path, real_ref)

        proto_result = XmlJLLoaderProto.load(xml_path, real_ref)

        real_str = sprint(show, real_result)
        proto_str = sprint(show, proto_result)

        if real_str == proto_str
            global n_ok += 1
            println("OK   $(module_name)/$(basename(xml_path))")
        else
            global n_fail += 1
            println("FAIL $(module_name)/$(basename(xml_path))")
            println("  real:  ", real_str)
            println("  proto: ", proto_str)
        end
    end
end

println("\n$(n_ok) matched, $(n_fail) mismatched")
n_fail == 0 || error("$(n_fail) fixtures mismatched between real and XML.jl-prototype loaders")
