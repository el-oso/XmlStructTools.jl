
include("XmlStructWriterTests.jl")

XmlStructWriterTests.runtests()

using ReTestItems, XmlStructWriter
ReTestItems.runtests(XmlStructWriter; testitem_timeout = 300)
