# Task 8 of the lazy-loading plan: before/after benchmark, ReadAllData (eager) vs ReadOnAccess
# (lazy), on real fixtures. Methodology matches this bench dir's other scripts: Chairmarks `@be`,
# report the median (Statistics.median on the Chairmarks sample), save to bench/results/*.json.
#
#   julia --project=bench bench/run_lazy_loading_bench.jl
#
# Note: ReadOnAccess() requires validate=false (XSD restriction validation needs the parsed value,
# which would force materializing every field, defeating the point) - the eager comparison keeps
# the default validate=true since that's how ReadAllData is normally used. This mirrors the real
# tradeoff the API forces, it is not an unfair comparison.

using Chairmarks
using JSON
using XmlStructLoader
using XsdToStruct: xsd_to_struct_module
using Statistics: median

const HERE = @__DIR__

function touch_first_field(loaded)
    # matches the "large document, only a handful of fields touched" motivating use case
    props = propertynames(loaded)
    isempty(props) && return nothing
    return getproperty(loaded, first(props))
end

function run_and_save(name::String, xsd_path::String, xml_path::String, module_dir::String)
    # Matches test/test_real_world_loading.jl's own proven pattern for this fixture:
    # Base.include(Main, generated_path) returns the module directly, avoiding
    # import_module_from_xml's self-include-into-XmlStructLoader path (which chokes on schemas with
    # a `Document` root type this size - confirmed while writing this script).
    generated_path = xsd_to_struct_module(xsd_path, module_dir)
    module_ref = Base.include(Main, generated_path)

    eager_result = @be XmlStructLoader.load($xml_path, $module_ref; load_strategy = XmlStructLoader.ReadAllData()) seconds = 5
    lazy_load_result = @be XmlStructLoader.load($xml_path, $module_ref; load_strategy = XmlStructLoader.ReadOnAccess(), validate = false) seconds = 5
    lazy_touch_result = @be touch_first_field(XmlStructLoader.load($xml_path, $module_ref; load_strategy = XmlStructLoader.ReadOnAccess(), validate = false)) seconds = 5

    return Dict(
        "fixture" => name,
        "eager_readalldata_median_s" => median(eager_result).time,
        "lazy_readonaccess_load_only_median_s" => median(lazy_load_result).time,
        "lazy_readonaccess_load_plus_one_field_median_s" => median(lazy_touch_result).time,
        "eager_readalldata_allocs" => median(eager_result).allocs,
        "lazy_readonaccess_load_only_allocs" => median(lazy_load_result).allocs,
    )
end

results = [
    run_and_save(
        "large_synthetic",
        joinpath(HERE, "fixtures", "large_synthetic.xsd"),
        joinpath(HERE, "fixtures", "large_synthetic.xml"),
        joinpath(HERE, "fixtures"),
    ),
    run_and_save(
        "pacs.008.001.09 (real ISO 20022)",
        joinpath(HERE, "..", "test", "test_data", "real_world", "pacs.008.001.09.xsd"),
        joinpath(HERE, "..", "test", "test_data", "real_world", "pacs.008.001.09_instance.xml"),
        mktempdir(),
    ),
]

open(joinpath(HERE, "results", "lazy_loading_readalldata_vs_readonaccess.json"), "w") do io
    JSON.print(io, results, 2)
end

for r in results
    println(r["fixture"], ":")
    println("  eager (ReadAllData):              ", r["eager_readalldata_median_s"], "s")
    println("  lazy load() only (ReadOnAccess):   ", r["lazy_readonaccess_load_only_median_s"], "s")
    println("  lazy load() + touch one field:     ", r["lazy_readonaccess_load_plus_one_field_median_s"], "s")
end
