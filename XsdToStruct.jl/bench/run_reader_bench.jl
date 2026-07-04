# Baseline benchmark for XsdToStruct.xsd_to_struct_module — Phase 0 of the XML backend bake-off /
# perf plan (see ~/.claude/plans/dynamic-churning-abelson.md). Measures the CURRENT LightXML-backed
# reader; later phases add prototype backends and compare against the numbers saved here.
#
#   julia --project=bench bench/run_reader_bench.jl
#
# Methodology matches XmlStructLoader.jl/bench/run_loader_bench.jl and this workspace's convention
# (BlazingPorts.jl/CLAUDE.md): Chairmarks `@be`, compare the MEDIAN, report rel-sigma. Full per-sample
# distributions saved to bench/results/*.json.

using Chairmarks, JSON, XsdToStruct
using Statistics: median, quantile

const HERE = @__DIR__
const ROOT = dirname(HERE)

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

xsd_dir = joinpath(ROOT, "test", "test_data", "generic_data")
xsd_files = filter(f -> endswith(f, ".xsd"), readdir(xsd_dir; join = true))

println("XsdToStruct.xsd_to_struct_module baseline (current LightXML backend) — warm median, Chairmarks @be.")

out = Dict{String,Any}()
for xsd_path in xsd_files
    key = basename(xsd_path)
    outdir = mktempdir()
    b = @be xsd_to_struct_module($xsd_path, $outdir) seconds = 2
    r = stats(b)
    println("  $(key):  median=$(round(r.median * 1e6, digits = 2))us  (n=$(r.n), relsigma=$(round(100r.relsigma, digits = 1))%)")
    out[key] = Dict(
        "median_s" => r.median,
        "relsigma" => r.relsigma,
        "n" => r.n,
        "samples" => r.samples,
    )
end

resdir = joinpath(HERE, "results")
mkpath(resdir)
resfile = joinpath(resdir, "reader_baseline.json")
open(resfile, "w") do io
    JSON.print(io, out, 2)
end
println("\nsaved raw medians -> ", resfile)
