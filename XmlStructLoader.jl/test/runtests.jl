include("XmlStructLoaderTests.jl")

XmlStructLoaderTests.runtests()

using ReTestItems, XmlStructLoader
ReTestItems.runtests(XmlStructLoader; testitem_timeout = 600)
