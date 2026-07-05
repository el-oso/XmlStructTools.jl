include("AbstractXsdTypesTests.jl")

AbstractXsdTypesTests.runtests()

using ReTestItems, AbstractXsdTypes
ReTestItems.runtests(AbstractXsdTypes; testitem_timeout = 300)
