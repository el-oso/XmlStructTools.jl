# Phase 2 bake-off: final consolidated head-to-head of all four candidates (baseline EzXML,
# XML.jl, pugixml, quick-xml) in one process, on the large_synthetic fixture - the
# decision-relevant scale. Small-fixture numbers are already saved separately per candidate
# (bench/results/loader_baseline.json / loader_bakeoff_{xmljl,pugixml,quickxml}.json); all four
# beat baseline there uniformly, so this focuses the final call on the large-fixture numbers,
# which is where they actually diverge.
#
#   taskset -c 2 julia --project=. run_bakeoff_final.jl

using Chairmarks, JSON, XsdToStruct, XmlStructLoader
using Statistics: median, quantile

const HERE = @__DIR__
include(joinpath(HERE, "prototype_xmljl", "loader_xmljl.jl"))
include(joinpath(HERE, "prototype_pugixml", "loader_pugixml.jl"))
include(joinpath(HERE, "prototype_quickxml", "loader_quickxml.jl"))

function stats(b)
    s = Float64[x.time for x in b.samples]
    (median = median(s), relsigma = (quantile(s, 0.75) - quantile(s, 0.25)) / 2 / median(s), n = length(s))
end

large_xsd = joinpath(HERE, "fixtures", "large_synthetic.xsd")
large_xml = joinpath(HERE, "fixtures", "large_synthetic.xml")
xsd_to_struct_module(large_xsd, joinpath(HERE, "fixtures"))
module_ref = XmlStructLoader.import_module_from_xml(large_xml, joinpath(HERE, "fixtures", "large_synthetic"))

println("Large fixture (20,000 records) — warm median, Chairmarks @be, 20s budget each, cpu2 pinned.\n")

results = Dict{String,Any}()

println("baseline (LightXML/EzXML, current):")
b = @be XmlStructLoader.load($large_xml, $module_ref) seconds = 20
r = stats(b)
results["baseline"] = r
println("  median=$(round(r.median*1e3, digits=2))ms  n=$(r.n)  relsigma=$(round(100r.relsigma, digits=1))%\n")

println("XML.jl:")
b = @be XmlJLLoaderProto.load($large_xml, $module_ref) seconds = 20
r = stats(b)
results["xmljl"] = r
println("  median=$(round(r.median*1e3, digits=2))ms  n=$(r.n)  relsigma=$(round(100r.relsigma, digits=1))%\n")

println("pugixml:")
b = @be PugixmlLoaderProto.load($large_xml, $module_ref) seconds = 20
r = stats(b)
results["pugixml"] = r
println("  median=$(round(r.median*1e3, digits=2))ms  n=$(r.n)  relsigma=$(round(100r.relsigma, digits=1))%\n")

println("quick-xml:")
b = @be QuickxmlLoaderProto.load($large_xml, $module_ref) seconds = 20
r = stats(b)
results["quickxml"] = r
println("  median=$(round(r.median*1e3, digits=2))ms  n=$(r.n)  relsigma=$(round(100r.relsigma, digits=1))%\n")

fastest = argmin(k -> results[k].median, collect(keys(results)))
println("=== Summary (ratio vs fastest = $fastest) ===")
for (k, r) in sort(collect(results); by = kv -> kv[2].median)
    ratio = r.median / results[fastest].median
    println("  $(rpad(k, 10)) $(round(r.median*1e3, digits=1))ms  ($(round(ratio, digits=2))x fastest)")
end

out = Dict(k => Dict("median_s" => r.median, "relsigma" => r.relsigma, "n" => r.n) for (k, r) in results)
resfile = joinpath(HERE, "results", "loader_bakeoff_final_summary.json")
open(resfile, "w") do io
    JSON.print(io, out, 2)
end
println("\nsaved -> ", resfile)
