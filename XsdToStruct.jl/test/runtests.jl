
include("XsdToStructTests.jl")

XsdToStructTests.runtests()

using ReTestItems, XsdToStruct
ReTestItems.runtests(XsdToStruct; testitem_timeout = 300)
