# Type definitions to represent a tree of xsd nodes
include("xsd_tree_node_types.jl")

# functions to help construct xsd tree structs
include("xsd_tree_utilities.jl")

# renames of elements and types requested by the caller
include("xsd_tree_mapping.jl")

# functions to post process the created xsd tree struct
include("xsd_tree_process.jl")

# functions to print a representation of the xsd tree
include("xsd_tree_show.jl")
