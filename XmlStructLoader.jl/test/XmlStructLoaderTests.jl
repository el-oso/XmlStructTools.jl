module XmlStructLoaderTests

using ReTest
using Logging
using XmlStructLoader
using XsdToStruct
using Dates
using TimeZones

include("test_utilities.jl")
include(joinpath("XmlStructLoaderGenericTests", "XmlStructLoaderGenericTests.jl"))
include("XmlStructLoaderEdgeTests.jl")
include("real_world_tests.jl")

end
