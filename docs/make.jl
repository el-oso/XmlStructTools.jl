using Documenter, DocumenterVitepress
using AbstractXsdTypes, XsdToStruct, XmlStructLoader, XmlStructWriter, XmlStructPugixml

const REPO = "github.com/el-oso/XmlStructTools.jl"

makedocs(;
    modules = [AbstractXsdTypes, XsdToStruct, XmlStructLoader, XmlStructWriter, XmlStructPugixml],
    repo = Remotes.GitHub("el-oso", "XmlStructTools.jl"),
    sitename = "XmlStructTools.jl",
    authors = "Tom Lemmens and contributors",
    format = DocumenterVitepress.MarkdownVitepress(;
        repo = REPO,
        devurl = "dev",
        deploy_url = "https://el-oso.github.io/XmlStructTools.jl",
        inventory_version = string(pkgversion(XmlStructLoader)),
    ),
    pages = [
        "Home" => "index.md",
        "Getting started" => "getting_started.md",
        "Guide" => [
            "Generating modules" => "guide/generating.md",
            "Loading XML" => "guide/loading.md",
            "Lazy loading" => "guide/lazy_loading.md",
            "Writing XML" => "guide/writing.md",
            "Renaming elements and types" => "guide/renaming.md",
            "Generated types" => "guide/types.md",
            "Shipping a schema in a package" => "guide/packaging.md",
        ],
        "Reference" => [
            "XsdToStruct" => "api/xsdtostruct.md",
            "XmlStructLoader" => "api/xmlstructloader.md",
            "XmlStructWriter" => "api/xmlstructwriter.md",
            "AbstractXsdTypes" => "api/abstractxsdtypes.md",
            "XmlStructPugixml" => "api/xmlstructpugixml.md",
        ],
        "Limitations" => "limitations.md",
    ],
)

DocumenterVitepress.deploydocs(; repo = REPO, devbranch = "main", push_preview = true)
