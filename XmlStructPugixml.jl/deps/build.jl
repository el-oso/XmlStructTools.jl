using pugixml_jll

const shim_src = joinpath(@__DIR__, "shim.cpp")
const shim_lib = joinpath(@__DIR__, "libxmlstructpugixml." * Base.Libc.Libdl.dlext)
const pugixml_root = dirname(dirname(pugixml_jll.libpugixml_path))
const pugixml_inc = joinpath(pugixml_root, "include")
const pugixml_lib = joinpath(pugixml_root, "lib")

cxx = get(ENV, "CXX", "g++")
run(`$cxx -O2 -std=c++14 -fPIC -Wall -Wextra -I$pugixml_inc -shared -o $shim_lib $shim_src -L$pugixml_lib -lpugixml -Wl,-rpath,$pugixml_lib`)

open(joinpath(@__DIR__, "deps.jl"), "w") do io
    println(io, "const libxmlstructpugixml = \"$(escape_string(shim_lib))\"")
end
