# Phase 2 bake-off: pugixml-shim-backed prototype loader vs the saved baseline. Same methodology
# as run_loader_bench.jl / run_bakeoff_xmljl.jl.

using Chairmarks, JSON, XsdToStruct, XmlStructLoader
using Statistics: median, quantile

const HERE = @__DIR__
include(joinpath(HERE, "prototype_pugixml", "loader_pugixml.jl"))
include(joinpath(HERE, "..", "test", "test_utilities.jl"))

const MAX_STORE_SAMPLES = 2000
function _subsample(s, k)
    length(s) <= k && return Float64.(s)
    z = sort(s)
    Float64.(z[unique(round.(Int, range(1, length(z); length = k)))])
end
function stats(b)
    s = Float64[x.time for x in b.samples]
    (
        median = median(s),
        relsigma = (quantile(s, 0.75) - quantile(s, 0.25)) / 2 / median(s),
        n = length(s),
        samples = _subsample(s, MAX_STORE_SAMPLES),
    )
end

generic_data_dir = joinpath(HERE, "..", "test", "test_data", "generic_cases")
generic_test_files = get_test_files(generic_data_dir)

println("pugixml-prototype loader bake-off — warm median, Chairmarks @be.")

out = Dict{String,Any}()
for (module_dir, xml_files) in generic_test_files
    isempty(xml_files) && continue
    module_name = basename(module_dir)
    module_ref = XmlStructLoader.import_module_from_xml(first(xml_files), module_dir)

    for xml_path in xml_files
        xml_name = basename(xml_path)
        key = "$(module_name)/$(xml_name)"
        b = @be PugixmlLoaderProto.load($xml_path, $module_ref) seconds = 2
        r = stats(b)
        println("  $(key):  median=$(round(r.median * 1e6, digits = 2))us  (n=$(r.n), relsigma=$(round(100r.relsigma, digits = 1))%)")
        out[key] = Dict("median_s" => r.median, "relsigma" => r.relsigma, "n" => r.n, "samples" => r.samples)
    end
end

large_xsd = joinpath(HERE, "fixtures", "large_synthetic.xsd")
large_xml = joinpath(HERE, "fixtures", "large_synthetic.xml")
xsd_to_struct_module(large_xsd, joinpath(HERE, "fixtures"))
large_module_ref = XmlStructLoader.import_module_from_xml(large_xml, joinpath(HERE, "fixtures", "large_synthetic"))
b = @be PugixmlLoaderProto.load($large_xml, $large_module_ref) seconds = 15
r = stats(b)
n_entries = length(PugixmlLoaderProto.load(large_xml, large_module_ref).Entry)
println(
    "  large_synthetic ($(n_entries) entries):  median=$(round(r.median * 1e3, digits = 2))ms  (n=$(r.n), relsigma=$(round(100r.relsigma, digits = 1))%)",
)
out["large_synthetic"] =
    Dict("median_s" => r.median, "relsigma" => r.relsigma, "n" => r.n, "samples" => r.samples, "n_entries" => n_entries)

resdir = joinpath(HERE, "results")
mkpath(resdir)
resfile = joinpath(resdir, "loader_bakeoff_pugixml.json")
open(resfile, "w") do io
    JSON.print(io, out, 2)
end
println("\nsaved raw medians -> ", resfile)
