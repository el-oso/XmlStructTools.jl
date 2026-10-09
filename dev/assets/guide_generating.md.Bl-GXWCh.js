import{_ as l,C as p,o as i,c as h,j as e,a,b as r,w as n,E as d,ap as k,ao as o}from"./chunks/framework.DJNc2e_g.js";const f=JSON.parse('{"title":"Generating modules","description":"","frontmatter":{},"headers":[],"relativePath":"guide/generating.md","filePath":"guide/generating.md","lastUpdated":null}'),c={name:"guide/generating.md"};function g(u,s,y,m,E,_){const t=p("Mermaid");return i(),h("div",null,[s[1]||(s[1]=e("h1",{id:"Generating-modules",tabindex:"-1"},[a("Generating modules "),e("a",{class:"header-anchor",href:"#Generating-modules","aria-label":'Permalink to "Generating modules {#Generating-modules}"'},"​")],-1)),s[2]||(s[2]=e("p",null,"XsdToStruct turns an XML Schema into Julia source code. The result is a directory holding a module that defines one type per schema type, with constructors that check the schema's restrictions.",-1)),(i(),r(k,null,{default:n(()=>[d(t,{id:"mermaid-6",class:"mermaid",graph:"flowchart%20TD%0A%20%20%20%20xsd%5B(%22orders.xsd%22)%5D%20--%3E%20read%5B%22read%20the%20schema%22%5D%0A%20%20%20%20read%20--%3E%20resolve%5B%22resolve%20extensions%20and%20groups%22%5D%0A%20%20%20%20resolve%20--%3E%20rename%5B%22apply%20the%20name%20mapping%2C%20if%20any%22%5D%0A%20%20%20%20rename%20--%3E%20write%5B%22write%20the%20module%22%5D%0A%20%20%20%20write%20--%3E%20main%5B%22orders%2Forders.jl%3Cbr%2F%3Emodule%20Orders%2C%20with%20__meta%22%5D%0A%20%20%20%20write%20--%3E%20structs%5B%22orders%2Forders_struct.jl%3Cbr%2F%3Emodule%20Orders_struct%2C%20the%20type%20definitions%22%5D%0A%20%20%20%20main%20--%3E%7C%22include%20%2B%20%40reexport%22%7C%20structs%0A"})]),fallback:n(()=>[...s[0]||(s[0]=[a(" Loading... ",-1)])]),_:1})),s[3]||(s[3]=o(`<h2 id="One-schema" tabindex="-1">One schema <a class="header-anchor" href="#One-schema" aria-label="Permalink to &quot;One schema {#One-schema}&quot;">​</a></h2><p><a href="/XmlStructTools.jl/dev/api/xsdtostruct#XsdToStruct.xsd_to_struct_module-Tuple{AbstractString, AbstractString}"><code>xsd_to_struct_module</code></a> takes the schema and an output directory, and returns the path of the module file:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">module_file </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> xsd_to_struct_module</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">joinpath</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(examples, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;orders.xsd&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">), output_dir)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">readdir</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(module_file))</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">2-element Vector{String}:</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;"> &quot;orders.jl&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;"> &quot;orders_struct.jl&quot;</span></span></code></pre></div><p>Without an output directory the module is written next to the schema. The directory and the file are named after the schema file, with characters that are not letters, digits, <code>_</code> or <code>-</code> replaced by <code>_</code>; the module itself is named after the schema&#39;s target namespace.</p><h2 id="What-is-generated" tabindex="-1">What is generated <a class="header-anchor" href="#What-is-generated" aria-label="Permalink to &quot;What is generated {#What-is-generated}&quot;">​</a></h2><p>The main file defines the module and re-exports everything from the file with the type definitions, so including the main file is all that is needed:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">read</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(module_file, String))</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">&quot;&quot;&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    module Orders</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">This module was generated with XsdToStruct version 0.1.0 from &quot;orders.xsd&quot;.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">All generated types are exported by this module and some meta data is included in the submodule __meta.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">In order to use this module the following dependencies need to be installed:</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    AbstractXsdTypes</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    Reexport</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    Dates</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    TimeZones</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">This module can be used/import as follows:</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">\`\`\`julia</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">include(&quot;path/to/orders.jl&quot;)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">using .Orders</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">\`\`\`</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">or:</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">\`\`\`julia</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">include(&quot;path/to/orders.jl&quot;)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">import .Orders</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">\`\`\`</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">&quot;&quot;&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">module Orders</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">using Reexport</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">@reexport using AbstractXsdTypes</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">include(&quot;orders_struct.jl&quot;)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">@reexport using .Orders_struct</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">module __meta</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    import ..Orders_struct</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    root_name = &quot;orders&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    root_type = Orders_struct.OrdersType</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    xsd_filename = &quot;orders.xsd&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    XsdToStruct_version = &quot;0.1.0&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    XSDMapping = Dict{String, String}()</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">end</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">end</span></span></code></pre></div><p>The <code>__meta</code> submodule records what the loader and writer need to know about the schema:</p><table tabindex="0"><thead><tr><th style="text-align:left;">Name</th><th style="text-align:left;">Meaning</th></tr></thead><tbody><tr><td style="text-align:left;"><code>root_type</code></td><td style="text-align:left;">The type of the root element; <a href="/XmlStructTools.jl/dev/api/xmlstructloader#XmlStructLoader.load-Tuple{AbstractString, AbstractString}"><code>load</code></a> builds an object of this type.</td></tr><tr><td style="text-align:left;"><code>root_name</code></td><td style="text-align:left;">The name of the root element; <a href="/XmlStructTools.jl/dev/api/xmlstructwriter#XmlStructWriter.write_xml-Tuple{Any, AbstractString}"><code>write_xml</code></a> names the root element of a document after it.</td></tr><tr><td style="text-align:left;"><code>xsd_filename</code></td><td style="text-align:left;">The schema file the module was generated from.</td></tr><tr><td style="text-align:left;"><code>XsdToStruct_version</code></td><td style="text-align:left;">The version of XsdToStruct that generated it.</td></tr><tr><td style="text-align:left;"><code>XSDMapping</code></td><td style="text-align:left;">The element renames given with <code>mapping</code>; see <a href="./renaming">Renaming elements and types</a>.</td></tr></tbody></table><p>The second file holds the types. Each type&#39;s documentation comes from the schema&#39;s <code>&lt;documentation&gt;</code> annotation:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">read</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">joinpath</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(module_file), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;orders_struct.jl&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">), String))</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">module Orders_struct</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">using Reexport</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">@reexport using Dates</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">@reexport using TimeZones</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">import AbstractXsdTypes</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">&quot;&quot;&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">A product code: three capital letters, a dash and four digits.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">&quot;&quot;&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Base.@kwdef struct Sku &lt;: AbstractXsdTypes.AbstractXSDString</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    value::String</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    __validated::Bool = true</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    function Sku(</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        value::AbstractString,</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        __validated::Bool=true)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        if __validated</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            AbstractXsdTypes.check_restrictions(Sku, value)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        end</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        return new(value, __xml_attributes, __validated)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    end</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">end</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">export Sku</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Base.@kwdef struct Quantity &lt;: AbstractXsdTypes.AbstractXSDSigned</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    value::Int64</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    __validated::Bool = true</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    function Quantity(</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        value::Number,</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        __xml_attributes::Union{Nothing, Dict{String, String}}=nothing,</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        __validated::Bool=true)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        if __validated</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            AbstractXsdTypes.check_restrictions(Quantity, value)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        end</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        return new(value, __xml_attributes, __validated)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    end</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">end</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">@inline AbstractXsdTypes.get_min_value(::Type{Quantity})::Int64 = 1</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">@inline AbstractXsdTypes.is_min_exclusive(::Type{Quantity})::Bool = false</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">@inline AbstractXsdTypes.get_restriction_checks(::Type{Quantity}) = (</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    AbstractXsdTypes.bound_restriction_check,)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">export Quantity</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">&quot;&quot;&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">One product in an order.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">&quot;&quot;&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Base.@kwdef struct Line &lt;: AbstractXsdTypes.AbstractXSDComplex</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    sku::Sku</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    quantity::Quantity</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    price::Float64</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    note::Union{Nothing, String} = nothing</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    __validated::Bool = true</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">end</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">export Line</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">struct Order &lt;: AbstractXsdTypes.AbstractXSDComplex</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    id::String</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    placed::Union{ZonedDateTime, DateTime}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    __Order_choice_1::NamedTuple{(:email, :phone), Tuple{Union{String, Nothing}, Union{String, Nothing}}}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    line::Vector{Line}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    __xml_attributes::Union{Nothing, Dict{String, String}}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    __validated::Bool</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">end</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">function Order(;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    id::String,</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    placed::Union{ZonedDateTime, DateTime},</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    email::Union{String, Nothing}=nothing,</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    phone::Union{String, Nothing}=nothing,</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    line::Vector{Line},</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    __xml_attributes::Union{Nothing, Dict{&lt;:AbstractString, &lt;:AbstractString}} = nothing,</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    __validated::Bool = true)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    if count(!isnothing, [email, phone]) &gt; 1</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        error(&quot;Only one of email or phone can be not nothing&quot;)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    else</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        Order(id, placed, (email=email, phone=phone), line, __xml_attributes, __validated)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    end</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">end</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Base.propertynames(x::Order, private::Bool=false) = Tuple(append!(</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    filter(s-&gt;!startswith(String(s), &quot;__Order&quot;), collect(fieldnames(Order))),</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    [:email, :phone]))</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">function Base.getproperty(x::Order, s::Symbol)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    if s in [:email, :phone]</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        return getfield(getfield(x, Symbol(&quot;__Order_choice_1&quot;)), s)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    else</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        return getfield(x, s)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    end</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">end</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">export Order</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Base.@kwdef struct OrdersType &lt;: AbstractXsdTypes.AbstractXSDComplex</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    order::Vector{Order}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    __xml_attributes::Union{Nothing, Dict{String, String}} = nothing</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    __validated::Bool = true</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">end</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">export OrdersType</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">end</span></span></code></pre></div><p>A few things to note in this output:</p><ul><li><p>A simple type with a restriction wraps its value in a struct whose constructor checks it, such as <code>Quantity</code>, whose <code>minInclusive</code> becomes a bound check.</p></li><li><p>An element with <code>minOccurs=&quot;0&quot;</code> becomes a <code>Union{Nothing, T}</code> field that defaults to <code>nothing</code>.</p></li><li><p>An element with <code>maxOccurs</code> above 1 becomes a <code>Vector</code>.</p></li><li><p>A choice is stored in one private field, <code>__Order_choice_1</code>, and its members are presented as properties of their own, of which at most one may be set. See <a href="./types">Generated types</a>.</p></li><li><p><code>xs:decimal</code> becomes <code>Float64</code>, and <code>xs:dateTime</code> becomes <code>Union{ZonedDateTime, DateTime}</code>.</p></li><li><p>Every type has two more fields, <code>__xml_attributes</code> and <code>__validated</code>, which hold the element&#39;s XML attributes and whether the object was checked against the schema&#39;s restrictions.</p></li></ul><h2 id="Many-schemas" tabindex="-1">Many schemas <a class="header-anchor" href="#Many-schemas" aria-label="Permalink to &quot;Many schemas {#Many-schemas}&quot;">​</a></h2><p><a href="/XmlStructTools.jl/dev/api/xsdtostruct#XsdToStruct.generate_modules-Tuple{Dict{&lt;:AbstractString, &lt;:AbstractString}, AbstractString}"><code>generate_modules</code></a> generates a module per entry of a dictionary. The keys are schema names and the values are where to find each schema: a file, a directory holding <code>&lt;name&gt;.xsd</code>, or a URL to download it from.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> XsdToStruct</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">xsd_locations </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Dict</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &quot;pacs.008.001.09&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> joinpath</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;schemas&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;pacs.008.001.09.xsd&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">),</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &quot;pain.001.001.09&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;schemas&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &quot;camt.053.001.08&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;https://example.com/xsd/camt.053.001.08.xsd&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">generate_modules</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(xsd_locations, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">joinpath</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;src&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;generated&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span></code></pre></div><p>This suits a build script that regenerates a package&#39;s modules from their schemas.</p><h2 id="Using-a-generated-module" tabindex="-1">Using a generated module <a class="header-anchor" href="#Using-a-generated-module" aria-label="Permalink to &quot;Using a generated module {#Using-a-generated-module}&quot;">​</a></h2><p>The module is ordinary Julia source. Include it and bring it into scope:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">include</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">joinpath</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;generated&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;orders&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;orders.jl&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> .</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">Orders          </span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># brings every generated type into scope</span></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># or</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">import</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> .</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">Orders         </span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># keeps them behind the module name: Orders.Line</span></span></code></pre></div><p><code>using</code> puts every exported type of the schema into the current namespace, which for a large schema is hundreds of names. <code>import</code> avoids clashes with your own names.</p><p>For a module used by more than one session, put it in a package so that it is precompiled; see <a href="./packaging">Shipping a schema in a package</a>.</p>`,25))])}const x=l(c,[["render",g]]);export{f as __pageData,x as default};
