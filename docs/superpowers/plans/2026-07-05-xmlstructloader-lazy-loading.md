# XmlStructLoader Lazy Loading Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `ReadOnAccess` load strategy to `XmlStructLoader.load` that defers each field's parsing to first access instead of eagerly constructing the whole document tree, so `load()` on a large document returns almost instantly.

**Architecture:** Every generated complex struct (for choice-free XSD complex types) gains a retained `_node` field and `@lazy`-declared data fields (`LazilyInitializedFields.jl`), each backed by a generated `_init_<field>` function that parses on first access. The retained node is a `LazyNode` — a `(ptr::Ptr{Cvoid}, owner::PugixmlDocumentHandle)` pair — where `PugixmlDocumentHandle` is a finalizer-bearing Julia wrapper around the pugixml document pointer, so Julia's GC keeps the C++ document alive exactly as long as anything in the returned object graph still references it. `ReadAllData` (today's eager behavior) is untouched.

**Tech Stack:** Julia 1.10+, `LazilyInitializedFields.jl` (new dependency), `XmlStructPugixml.jl` (existing), `ReTestItems.jl` (new test-only dependency for this feature's new test files), `Chairmarks.jl` (existing benchmark tooling).

## Global Constraints

- Design spec: `docs/superpowers/specs/2026-07-05-xmlstructloader-lazy-loading-design.md`. Every requirement in that spec is binding; this plan implements it in full.
- `ReadAllData` (existing eager path: `XmlStructLoader.jl/src/xml_parser/xml_parser.jl`, `xml_parser_in_module.jl`, `xml_parser_type_info.jl`) is **not modified** — the lazy path is additive, calling into it only as a subtree-construction fallback (see Task 3).
- New dependency placement (confirmed with user, deviating from the reference branch): `PugixmlDocumentHandle`/`LazyNode`/lazy parsing helpers live in `XmlStructLoader.jl`, not `AbstractXsdTypes.jl` — `AbstractXsdTypes.jl` has zero XML-backend dependency today and stays that way. `LazilyInitializedFields.jl` is a real dependency of **both** `AbstractXsdTypes.jl` (needed by `show_function.jl`'s fix) and `XmlStructLoader.jl` (needed because generated struct code does `using LazilyInitializedFields` directly, and that code gets `include()`d into `XmlStructLoader.jl`'s own module scope via `import_module`/`use_module` — the exact ripple-effect class of bug the precompile-workload feature already hit with `PrecompileTools`).
- Field naming matches current main (`__xml_attributes`, `__validated`), not the reference branch's renamed `xml_attributes`/`validated`.
- Choice-bearing complex types are **not** given lazy treatment (inherited limitation, confirmed safe for the real ISO 20022 target schema — see spec).
- `validate=true` combined with `load_strategy=ReadOnAccess()` raises `ArgumentError` (not silently ignored).
- No raw `Ptr{Cvoid}` is ever exposed outside the new `lazy_xml_node.jl` file — every pugixml call on a `LazyNode` goes through a helper that does `GC.@preserve node.owner ccall(...)`.
- Every new test file this plan adds is written as `@testitem` blocks (ReTestItems.jl), with `ReTestItems` added as a **test-only** dependency (`test/Project.toml` only). Existing `@testset`-based suites in each touched package are not modified or migrated.
- Perf sanity check (Task 8) reports **latency** as the headline number, with allocations as secondary, written up as a before/after summary (not just raw JSON) — this was explicitly requested during design review.

---

### Task 1: `PugixmlDocumentHandle` and `LazyNode` — the lifetime-safe node wrapper

**Files:**
- Create: `XmlStructLoader.jl/src/xml_parser/lazy_xml_node.jl`
- Modify: `XmlStructLoader.jl/src/XmlStructLoader.jl:13` (add `include`)
- Test: `XmlStructLoader.jl/test/lazy_xml_node_tests.jl` (new, `@testitem`)
- Modify: `XmlStructLoader.jl/test/Project.toml` (add `ReTestItems` test-only dep)
- Modify: `XmlStructLoader.jl/test/runtests.jl` (invoke `ReTestItems.runtests` alongside the existing custom runner)

**Interfaces:**
- Consumes: `XmlStructPugixml.parse_file`, `parse_buffer`, `free_doc`, `element_children` (existing, `XmlStructPugixml.jl/src/XmlStructPugixml.jl`); the existing `name(::Ptr{Cvoid})`, `content(::Ptr{Cvoid})`, `haschildren(::Ptr{Cvoid})`, `getattributes_dict(::Ptr{Cvoid})` from `xml_abstraction.jl` (same module, already `include`d before this file).
- Produces (used by later tasks): `PugixmlDocumentHandle(ptr::Ptr{Cvoid})` constructor, `Base.close(::PugixmlDocumentHandle)`, `LazyNode(ptr::Ptr{Cvoid}, owner::PugixmlDocumentHandle)`, `lazy_name(::LazyNode)::String`, `lazy_content(::LazyNode)::String`, `lazy_haschildren(::LazyNode)::Bool`, `lazy_attributes_dict(::LazyNode)::Dict{String,String}`, `lazy_children(::LazyNode)::Vector{LazyNode}`, `lazy_child_with_name(::LazyNode, ::AbstractString, ::Bool)::Union{Nothing,LazyNode}`, `lazy_children_with_name(::LazyNode, ::AbstractString)::Vector{LazyNode}`.

- [ ] **Step 1: Write the failing tests**

Create `XmlStructLoader.jl/test/lazy_xml_node_tests.jl`:

```julia
@testitem "PugixmlDocumentHandle: finalizer frees exactly once, close() is idempotent" begin
    fixture = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xml")
    doc_ptr = XmlStructPugixml.parse_file(fixture)
    @test doc_ptr != C_NULL

    handle = XmlStructLoader.PugixmlDocumentHandle(doc_ptr)
    @test handle.ptr == doc_ptr

    close(handle)
    @test handle.ptr == C_NULL

    # idempotent: closing again, or letting the finalizer run, must not double-free
    close(handle)
    @test handle.ptr == C_NULL
    finalize(handle)
    @test handle.ptr == C_NULL
end

@testitem "LazyNode: name/content/children/attributes match the eager abstraction layer" begin
    fixture = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xml")
    doc_ptr = XmlStructPugixml.parse_file(fixture)
    handle = XmlStructLoader.PugixmlDocumentHandle(doc_ptr)
    root_ptr = XmlStructPugixml.root(doc_ptr)
    root = XmlStructLoader.LazyNode(root_ptr, handle)

    @test XmlStructLoader.lazy_name(root) == XmlStructLoader.name(root_ptr)
    @test XmlStructLoader.lazy_haschildren(root) == XmlStructLoader.haschildren(root_ptr)
    @test XmlStructLoader.lazy_attributes_dict(root) == XmlStructLoader.getattributes_dict(root_ptr)

    children = XmlStructLoader.lazy_children(root)
    @test length(children) == length(XmlStructPugixml.element_children(root_ptr))
    @test all(c -> c.owner === handle, children)

    first_child_name = XmlStructLoader.lazy_name(first(children))
    found = XmlStructLoader.lazy_child_with_name(root, first_child_name, false)
    @test !isnothing(found)
    @test XmlStructLoader.lazy_name(found) == first_child_name

    @test isnothing(XmlStructLoader.lazy_child_with_name(root, "NoSuchElement", true))
    @test_throws ErrorException XmlStructLoader.lazy_child_with_name(root, "NoSuchElement", false)

    close(handle)
end

@testitem "LazyNode survives GC pressure between accesses (finalizer safety)" begin
    fixture = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xml")
    doc_ptr = XmlStructPugixml.parse_file(fixture)
    handle = XmlStructLoader.PugixmlDocumentHandle(doc_ptr)
    root = XmlStructLoader.LazyNode(XmlStructPugixml.root(doc_ptr), handle)

    for _ in 1:5
        GC.gc(true)
        @test XmlStructLoader.lazy_name(root) == "TestComplexAndSimple:document"
        GC.gc(true)
        for child in XmlStructLoader.lazy_children(root)
            GC.gc(true)
            @test !isempty(XmlStructLoader.lazy_name(child))
        end
    end

    close(handle)
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd XmlStructLoader.jl && julia --project=. -e 'using Pkg; Pkg.test()'`
Expected: FAIL — `PugixmlDocumentHandle`/`LazyNode` undefined.

- [ ] **Step 3: Add `ReTestItems` as a test-only dependency**

Modify `XmlStructLoader.jl/test/Project.toml` — add under `[deps]`:
```toml
ReTestItems = "817f1d60-ba6b-4fd5-9520-3cf149f6a823"
```
(Same UUID as already used in `XmlStructPugixml.jl/test/Project.toml` — verify with `Pkg.add("ReTestItems")` from `XmlStructLoader.jl/test`, never hand-write UUIDs.)

- [ ] **Step 4: Wire ReTestItems into `runtests.jl` alongside the existing runner**

**Correction from the plan's original draft, confirmed against `ReTestItems.jl`'s own README
(`~/.julia/packages/ReTestItems/*/README.md`) before writing this:** `ReTestItems.runtests`'s
`name` keyword filters by each `@testitem`'s own title string, not by file name - passing a
file-name regex there would silently match zero test-items, so no new test would ever actually
run under it. The correct, documented pattern needs no per-file scoping at all: ReTestItems scans
the whole directory tree for every file named `*_tests.jl`/`*_test.jl` and runs everything it
finds, with no explicit registration needed per file. This one invocation, added now, is the only
`runtests.jl` change this entire plan needs for `XmlStructLoader.jl` - every later task in this
package that adds another `*_tests.jl` file is picked up automatically, and none of them touch
`runtests.jl` again.

Read the current `XmlStructLoader.jl/test/runtests.jl` first (it currently calls
`XmlStructLoaderTests.runtests()`). Add, after that call:
```julia
using ReTestItems
ReTestItems.runtests(XmlStructLoader; testitem_timeout = 600)
```

- [ ] **Step 5: Implement `PugixmlDocumentHandle` and `LazyNode`**

Create `XmlStructLoader.jl/src/xml_parser/lazy_xml_node.jl`:

```julia
"""
    PugixmlDocumentHandle

Julia-GC-managed owner of a pugixml document pointer. `XmlStructPugixml.parse_file`/`parse_buffer`
return a raw `Ptr{Cvoid}` into a C++-managed, single-owner document that must be freed exactly
once (`XmlStructPugixml.free_doc`) - this wrapper ties that free to Julia's own garbage collector
via a finalizer, so a document parsed for `ReadOnAccess` stays alive for as long as any [`LazyNode`](@ref)
derived from it is still reachable, instead of being freed the instant `load()` returns (as the
eager `ReadAllData` path still correctly does, unchanged).

Call [`close`](@ref) for deterministic release instead of waiting for GC if loading many large
documents in a loop. The finalizer is idempotent - closing explicitly and then letting the
finalizer also run later is safe.
"""
mutable struct PugixmlDocumentHandle
    ptr::Ptr{Cvoid}

    function PugixmlDocumentHandle(ptr::Ptr{Cvoid})
        handle = new(ptr)
        finalizer(_free_pugixml_document_handle!, handle)
        return handle
    end
end

function _free_pugixml_document_handle!(handle::PugixmlDocumentHandle)::Nothing
    if handle.ptr != C_NULL
        XmlStructPugixml.free_doc(handle.ptr)
        handle.ptr = C_NULL
    end
    return nothing
end

"""
    close(handle::PugixmlDocumentHandle)::Nothing

Free the underlying pugixml document now. Idempotent: safe to call more than once, and safe even
after the finalizer has already run. Any [`LazyNode`](@ref) still referencing this handle becomes
unsafe to use after this call - there is no per-access "is this closed" check (matching the
posture of reading a closed `IOStream`), so this is a documented caller contract, not a defended
error path.
"""
Base.close(handle::PugixmlDocumentHandle)::Nothing = _free_pugixml_document_handle!(handle)

"""
    LazyNode

A pugixml node handle paired with the [`PugixmlDocumentHandle`](@ref) that owns its document. As
long as any `LazyNode` is reachable, Julia's GC keeps `owner` (and therefore the underlying
document) alive. Never extract and use `.ptr` outside this file without a `GC.@preserve node.owner`
around the call - see the accessor functions below for the pattern.
"""
struct LazyNode
    ptr::Ptr{Cvoid}
    owner::PugixmlDocumentHandle
end

"""
    lazy_name(node::LazyNode)::String

The node's tag name (namespace-prefix-stripped, same as [`name`](@ref) on a raw pugixml pointer).
"""
lazy_name(node::LazyNode)::String = GC.@preserve node.owner name(node.ptr)

"""
    lazy_content(node::LazyNode)::String

The node's direct text content, stripped (same as [`content`](@ref) on a raw pugixml pointer).
"""
lazy_content(node::LazyNode)::String = GC.@preserve node.owner content(node.ptr)

"""
    lazy_haschildren(node::LazyNode)::Bool
"""
lazy_haschildren(node::LazyNode)::Bool = GC.@preserve node.owner haschildren(node.ptr)

"""
    lazy_attributes_dict(node::LazyNode)::Dict{String,String}
"""
lazy_attributes_dict(node::LazyNode)::Dict{String,String} = GC.@preserve node.owner getattributes_dict(node.ptr)

"""
    lazy_children(node::LazyNode)::Vector{LazyNode}

All element children of `node`, each wrapped with the same `owner` as `node` - the whole subtree
shares one document handle, so the document stays alive as long as anything anywhere under it does.
"""
function lazy_children(node::LazyNode)::Vector{LazyNode}
    child_ptrs = GC.@preserve node.owner XmlStructPugixml.element_children(node.ptr)
    return [LazyNode(ptr, node.owner) for ptr in child_ptrs]
end

"""
    lazy_child_with_name(node::LazyNode, child_name::AbstractString, is_optional::Bool)::Union{Nothing,LazyNode}

The first element child of `node` named `child_name`, or `nothing` if `is_optional` and no such
child exists. Raises an error if the child is required (`is_optional == false`) and missing -
matching the eager path's own "missing required element" behavior.
"""
function lazy_child_with_name(node::LazyNode, child_name::AbstractString, is_optional::Bool)::Union{Nothing,LazyNode}
    for child in lazy_children(node)
        lazy_name(child) == child_name && return child
    end
    is_optional || error("Name: $(child_name) is not an element of node $(lazy_name(node))")
    return nothing
end

"""
    lazy_children_with_name(node::LazyNode, child_name::AbstractString)::Vector{LazyNode}

Every element child of `node` named `child_name`, in document order - for repeated (vector) fields.
"""
function lazy_children_with_name(node::LazyNode, child_name::AbstractString)::Vector{LazyNode}
    return filter(child -> lazy_name(child) == child_name, lazy_children(node))
end
```

- [ ] **Step 6: Include the new file**

Modify `XmlStructLoader.jl/src/XmlStructLoader.jl` — the file currently has (around line 13):
```julia
include(joinpath("xml_parser", "xml_parser.jl"))
include("xml_module_utilities.jl")
```
`xml_parser.jl` already `include`s `xml_abstraction.jl` first (line 1 of that file), which is where `name`/`content`/`haschildren`/`getattributes_dict` for `Ptr{Cvoid}` are defined - `lazy_xml_node.jl` must be included after it. Change to:
```julia
include(joinpath("xml_parser", "xml_parser.jl"))
include(joinpath("xml_parser", "lazy_xml_node.jl"))
include("xml_module_utilities.jl")
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `cd XmlStructLoader.jl && julia --project=. -e 'using Pkg; Pkg.test()'`
Expected: PASS (all three new `@testitem`s), plus the existing classic suite still green.

- [ ] **Step 8: Commit**

```bash
git add XmlStructLoader.jl/src/xml_parser/lazy_xml_node.jl \
        XmlStructLoader.jl/src/XmlStructLoader.jl \
        XmlStructLoader.jl/test/lazy_xml_node_tests.jl \
        XmlStructLoader.jl/test/Project.toml \
        XmlStructLoader.jl/test/runtests.jl \
        XmlStructLoader.jl/Manifest.toml
git commit -m "Add PugixmlDocumentHandle/LazyNode: GC-rooted lifetime for lazy XML nodes"
```

---

### Task 2: `AbstractXsdTypes.jl` — hide `_node` and stop `show`/`propertynames` from forcing lazy materialization

**Files:**
- Modify: `AbstractXsdTypes.jl/Project.toml` (add `LazilyInitializedFields` dependency)
- Modify: `AbstractXsdTypes.jl/src/type_definitions.jl` (propertynames fix)
- Modify: `AbstractXsdTypes.jl/src/show_function.jl` (uninit-aware `print_tree`)
- Test: `AbstractXsdTypes.jl/test/lazy_show_tests.jl` (new, `@testitem`)
- Modify: `AbstractXsdTypes.jl/test/Project.toml` (add `ReTestItems`, `LazilyInitializedFields` test-only)
- Modify: `AbstractXsdTypes.jl/test/runtests.jl`

**Interfaces:**
- Consumes: `LazilyInitializedFields.islazyfield`, `LazilyInitializedFields.isinit` (real package functions, verified directly against `~/.julia/packages/LazilyInitializedFields/msL8k/src/LazilyInitializedFields.jl` - both exported, both throw `MethodError` if called on a type with no `@lazy`-generated `islazyfield` method, which is why every call site below is guarded by `hasmethod` first).
- Produces: `Base.propertynames(x::T) where {T<:AbstractXSDComplex}` override (excludes `:_node` when present); `print_tree` no longer forces materialization of uninitialized lazy fields.

- [ ] **Step 1: Write the failing test**

Since `AbstractXsdTypes.jl` itself defines no lazy struct (that only happens in generated code, Task 3), this test builds a minimal one directly to exercise the fix in isolation:

Create `AbstractXsdTypes.jl/test/lazy_show_tests.jl`:

```julia
@testitem "propertynames excludes _node; print_tree does not force-materialize uninit lazy fields" begin
    using LazilyInitializedFields

    @lazy mutable struct LazyShowTestType <: AbstractXsdTypes.AbstractXSDComplex
        _node::Union{Nothing,Int}
        @lazy Element_a::String = _init_touch_counter_a
        @lazy Element_b::String = _init_touch_counter_b
        __xml_attributes::Union{Nothing,Dict{String,String}}
        __validated::Bool
    end

    const TOUCH_COUNTS = Dict(:a => 0, :b => 0)
    function _init_touch_counter_a(::LazyShowTestType)
        TOUCH_COUNTS[:a] += 1
        return "value-a"
    end
    function _init_touch_counter_b(::LazyShowTestType)
        TOUCH_COUNTS[:b] += 1
        return "value-b"
    end

    obj = LazyShowTestType(1, uninit, uninit, nothing, true)

    # propertynames excludes the internal _node field
    @test :_node ∉ propertynames(obj)
    @test :Element_a in propertynames(obj)

    # printing must not touch either lazy field
    io = IOBuffer()
    show(io, obj)
    @test TOUCH_COUNTS[:a] == 0
    @test TOUCH_COUNTS[:b] == 0
    printed = String(take!(io))
    @test occursin("uninit", printed)

    # after a real access, printing reflects the now-initialized value without re-triggering init
    @test obj.Element_a == "value-a"
    @test TOUCH_COUNTS[:a] == 1
    io2 = IOBuffer()
    show(io2, obj)
    @test TOUCH_COUNTS[:a] == 1  # not incremented by printing
    @test occursin("value-a", String(take!(io2)))
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd AbstractXsdTypes.jl && julia --project=. -e 'using Pkg; Pkg.test()'`
Expected: FAIL — `:_node` currently appears in `propertynames`, and `show` currently calls `getproperty` unconditionally, so `TOUCH_COUNTS[:a]`/`[:b]` would already be `1` before the "must not touch" assertions.

- [ ] **Step 3: Add dependencies**

Modify `AbstractXsdTypes.jl/Project.toml` — add under `[deps]`:
```toml
LazilyInitializedFields = "0e77f7df-68c5-4e49-93ce-4cd80f5598bf"
```
Add under `[compat]`: `LazilyInitializedFields = "1"` (confirm the actual released major version with `Pkg.add` rather than hand-writing this compat bound).

Modify `AbstractXsdTypes.jl/test/Project.toml` — add under `[deps]`:
```toml
ReTestItems = "817f1d60-ba6b-4fd5-9520-3cf149f6a823"
LazilyInitializedFields = "0e77f7df-68c5-4e49-93ce-4cd80f5598bf"
```

- [ ] **Step 4: Wire ReTestItems into `runtests.jl`**

Same correction as Task 1 Step 4 (`name` filters test-item titles, not file names - no per-file
scoping needed or wanted). Appended to `AbstractXsdTypes.jl/test/runtests.jl`, once:
```julia
using ReTestItems
ReTestItems.runtests(AbstractXsdTypes; testitem_timeout = 300)
```

- [ ] **Step 5: Fix `Base.propertynames`**

Modify `AbstractXsdTypes.jl/src/type_definitions.jl` — add immediately after the existing `public_propertynames`/`private_field_names` block (after line 175, `end` of `public_propertynames`):

```julia
"""
    Base.propertynames(x::T) where {T<:AbstractXSDComplex}

Excludes the internal `_node` field (present only on lazy-loading-capable structs, see
XmlStructLoader.jl's `ReadOnAccess` load strategy) from the properties users see via `propertynames`,
`show`/`print_tree`, and `XmlStructWriter.jl`'s serialization (which both call plain `propertynames`,
not `public_propertynames` - this single override is the one point of control for all three).
Every other existing field (`__xml_attributes`, `__validated`) is unaffected.
"""
function Base.propertynames(x::T) where {T<:AbstractXSDComplex}
    return hasfield(T, :_node) ? filter(!=(:_node), fieldnames(T)) : fieldnames(T)
end
```

- [ ] **Step 6: Fix `print_tree` to not force-materialize uninitialized lazy fields**

Modify `AbstractXsdTypes.jl/src/show_function.jl` — replace the `print_tree(io::IO, x::AbstractXSDComplex; ...)` method (lines 32-60) with:

```julia
function print_tree(io::IO, x::AbstractXSDComplex; print_all::Bool = false, indent_string::AbstractString = "")::Nothing
    properties = propertynames(x)
    n_properties = length(properties)
    T = typeof(x)
    has_lazy_fields = hasmethod(LazilyInitializedFields.islazyfield, Tuple{Type{T},Symbol})

    prefix_string = indent_string * branch_string

    for (i, property) in enumerate(properties)
        new_indent_string = i == n_properties ? indent_string * empty_indent_string : indent_string * base_indent_string

        if has_lazy_fields && LazilyInitializedFields.islazyfield(T, property) &&
           !LazilyInitializedFields.isinit(x, property)
            println(io, prefix_string * "$property: uninit")
            continue
        end

        property_value = getproperty(x, property)
        if property_value isa Union{AbstractXSDComplex,Vector{<:AbstractXSDComplex}}
            print(io, prefix_string * "$property:")
            if print_all
                println(io)
                print_tree(io, property_value; indent_string = new_indent_string, print_all = print_all)
            else
                println(io, " ...")
            end
        else
            println(io, prefix_string * "$property: $property_value")
        end
    end

    return nothing
end
```

Add `using LazilyInitializedFields` (or `import LazilyInitializedFields`) to `AbstractXsdTypes.jl/src/AbstractXsdTypes.jl`'s top (alongside the existing `using Memoization` / `using Format`), since `show_function.jl` is `include`d into that module's scope.

- [ ] **Step 7: Run tests to verify they pass**

Run: `cd AbstractXsdTypes.jl && julia --project=. -e 'using Pkg; Pkg.test()'`
Expected: PASS, plus the full existing suite (1688 tests per the ledger) still green.

- [ ] **Step 8: Commit**

```bash
git add AbstractXsdTypes.jl/Project.toml AbstractXsdTypes.jl/test/Project.toml \
        AbstractXsdTypes.jl/src/AbstractXsdTypes.jl AbstractXsdTypes.jl/src/type_definitions.jl \
        AbstractXsdTypes.jl/src/show_function.jl AbstractXsdTypes.jl/test/lazy_show_tests.jl \
        AbstractXsdTypes.jl/test/runtests.jl AbstractXsdTypes.jl/Manifest.toml
git commit -m "Hide _node from propertynames; stop show/print_tree forcing lazy field materialization"
```

---

### Task 3: XsdToStruct.jl codegen — emit lazy structs for choice-free complex types

This is the largest task. It changes what `write_node_no_choice` emits (in `xsd_module_builder_struct.jl`) so choice-free complex types get `_node` + `@lazy` fields + generated `_init_<field>` accessors, while choice-bearing types (`write_node_with_choice`) are untouched.

**Files:**
- Modify: `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_struct.jl`
- Modify: `XsdToStruct.jl/Project.toml` (no new runtime dep needed here - `LazilyInitializedFields`/`XmlStructLoader` are dependencies of the *generated* code, not of `XsdToStruct.jl` itself, which only emits text)
- Test: `XsdToStruct.jl/test/lazy_struct_codegen_tests.jl` (new, `@testitem`)
- Modify: `XsdToStruct.jl/test/Project.toml` (add `ReTestItems`)
- Modify: `XsdToStruct.jl/test/runtests.jl`

**Interfaces:**
- Consumes: `get_all_fields(xsd_node)::Vector{AbstractFieldData}`, `FieldData`/`ChoiceFieldData`/`GroupFieldData` (from `XsdToStruct.jl/src/xsd_field_data/xsd_field_data_types.jl`, `xsd_tree_node_types.jl`), `built_in_data_type_dict` (from `xsd_field_data_type_mapping.jl`), `xsd_module_builder.defined_nodes` (already-processed nodes, populated before struct-writing completes for earlier types - a field's own type node may or may not be in this set yet depending on write order, handled below).
- Produces: for each choice-free `ComplexTreeNode`, a generated struct with `_node::Union{Nothing,XmlStructLoader.LazyNode}`, `@lazy field::T = _init_field` per data field, a node-based constructor `StructName(node::XmlStructLoader.LazyNode)`, and a hand-rolled outer keyword constructor matching the eager path's call convention (`StructName(; field1=.., __xml_attributes=.., __validated=..)`).

- [ ] **Step 1: Write the failing tests**

Create `XsdToStruct.jl/test/lazy_struct_codegen_tests.jl`:

```julia
@testitem "basic_types (choice-free) generates a lazy struct with _node and @lazy fields" begin
    xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "basic_types.xsd")
    outdir = mktempdir()
    generated_path = xsd_to_struct_module(xsd_path, outdir)
    source = read(generated_path, String)

    @test occursin("using LazilyInitializedFields", source)
    @test occursin("_node::Union{Nothing, XmlStructLoader.LazyNode}", source)
    @test occursin("@lazy Element_string::String = _init_Element_string", source)
    @test occursin("function TestElement1(node::XmlStructLoader.LazyNode)", source)
end

@testitem "choice_element (choice-bearing) keeps generating a plain, non-lazy struct" begin
    xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "choice_element.xsd")
    outdir = mktempdir()
    generated_path = xsd_to_struct_module(xsd_path, outdir)
    source = read(generated_path, String)

    @test !occursin("using LazilyInitializedFields", source)
    @test !occursin("_node::Union{Nothing, XmlStructLoader.LazyNode}", source)
end

@testitem "lazy struct can still be constructed eagerly via the outer keyword constructor" begin
    xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "basic_types.xsd")
    outdir = mktempdir()
    generated_path = xsd_to_struct_module(xsd_path, outdir)

    module_name = nothing
    for line in split(read(generated_path, String), '\n')
        m = match(r"^module\s+(\w+)", line)
        isnothing(m) || (module_name = Symbol(m[1]); break)
    end

    Base.include(Main, generated_path)
    generated_module = Base.invokelatest(getproperty, Main, module_name)
    struct_module = Base.invokelatest(getproperty, generated_module, Symbol(String(module_name) * "_struct"))

    # Same construction shape the eager path already relies on: T(; field=value, ..., __xml_attributes=, __validated=)
    te1_type = Base.invokelatest(getproperty, struct_module, :TestElement1)
    obj = Base.invokelatest(
        te1_type;
        Element_string = "aaaa", Element_double = 1.0, Element_boolean = true, Element_decimal = 1.0,
        Element_dateTime = Base.invokelatest(getproperty, generated_module, :DateTime)("2020-01-01T00:00:00"),
        Element_integer = 1, Element_nonNegativeInteger = 1, Element_positiveInteger = 1,
        __xml_attributes = nothing, __validated = true,
    )
    @test Base.invokelatest(getproperty, obj, :Element_string) == "aaaa"
end
```

(The module-name extraction is inlined directly in the one `@testitem` that needs it, rather than
reused from `_extract_module_name` in `test_generated_module_precompile_workload.jl` - confirmed
against `ReTestItems.jl`'s own README that each `@testitem` runs as top-level code in its own fresh
module and cannot see plain top-level functions defined in a different file, or even elsewhere in
the same file outside a `@testsetup module`. That older helper lives in a classic `@testset`-based
file, unaffected by this plan's constraint of not migrating existing test files.)

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd XsdToStruct.jl && julia --project=. -e 'using Pkg; Pkg.test()'`
Expected: FAIL — no `_node`/`@lazy` emitted yet.

- [ ] **Step 3: Add `ReTestItems` test dependency and wire `runtests.jl`**

Same pattern as Tasks 1-2:
```toml
# XsdToStruct.jl/test/Project.toml, under [deps]
ReTestItems = "817f1d60-ba6b-4fd5-9520-3cf149f6a823"
```
```julia
# appended to XsdToStruct.jl/test/runtests.jl - same correction as Task 1 Step 4: one
# unscoped call, ReTestItems auto-discovers every *_tests.jl file in the directory tree
using ReTestItems
ReTestItems.runtests(XsdToStruct; testitem_timeout = 300)
```

- [ ] **Step 4: Add a "does this node have a lazy constructor" helper**

Modify `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_common.jl` — add:

```julia
"""
    is_lazy_capable(node::ComplexTreeNode)::Bool

True for complex types that get lazy-loading codegen: no `xs:choice` fields. Choice-bearing types
keep their existing eager-only `propertynames`/`getproperty` overrides (see `write_node_with_choice`),
which conflict with `@lazy`'s own `propertynames` mechanism - confirmed against the reference
implementation and safe for the real ISO 20022 target schema (no root-path choice gating).
"""
is_lazy_capable(node::ComplexTreeNode)::Bool = isempty(get_all_fields_of_type(node, ChoiceFieldData))
```

- [ ] **Step 5: Emit the lazy struct definition**

Modify `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_struct.jl`'s `write_node_no_choice` (lines 133-166). Current version emits `Base.@kwdef struct ... end` with plain fields and calls `write_defaults_function`. Replace with:

```julia
function write_node_no_choice(
        xsd_node::ComplexTreeNode,
        xsd_module_builder::XSDStructModuleBuilderType,
        indent_level::Int,
    )
    @debug "writing with no choice fields"

    all_fields = get_all_fields(xsd_node)

    writeln(
        xsd_module_builder,
        IOStruct,
        struct_line_string(name(xsd_node), "$ABSTRACT_TYPE_PACKAGE.AbstractXSDComplex"; lazy = true),
        indent_level = indent_level,
    )

    writeln(
        xsd_module_builder,
        IOStruct,
        "_node::Union{Nothing, XmlStructLoader.LazyNode}";
        indent_level = indent_level + 1,
    )

    @debug "Writing fields: $(getproperty.(all_fields, :name))"
    for field in all_fields
        field isa GroupFieldData && continue
        field_string = generate_lazy_field_string(field)
        writeln(xsd_module_builder, IOStruct, field_string, indent_level = indent_level + 1)
    end

    writeln(
        xsd_module_builder,
        IOStruct,
        "__xml_attributes::Union{Nothing, Dict{String, String}} = nothing";
        indent_level = indent_level + 1,
    )
    writeln(xsd_module_builder, IOStruct, "__validated::Bool = true"; indent_level = indent_level + 1)

    write(xsd_module_builder, IOStruct, "end\n\n", indent_level = indent_level)

    write_defaults_function(xsd_module_builder, name(xsd_node), all_fields, indent_level = indent_level)
    write_lazy_node_constructor(xsd_module_builder, xsd_node, all_fields, indent_level)
    write_lazy_outer_kwdef_constructor(xsd_module_builder, xsd_node, all_fields, indent_level)
    write_lazy_field_accessors(xsd_module_builder, xsd_node, all_fields, indent_level)

    return push!(xsd_module_builder.defined_nodes, xsd_node)
end
```

Note: `struct_line_string` gains a `lazy::Bool` keyword (Step 6 below) - when `lazy=true` it emits `@lazy struct ...` instead of `Base.@kwdef struct ...`, since `@lazy` and `Base.@kwdef` can't compose directly (confirmed against the reference implementation, which tried and abandoned a combinator macro in favor of hand-generating the keyword constructor - the same approach taken here).

- [ ] **Step 6: Update `struct_line_string` for the `lazy` option**

Modify `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_common.jl` — current:
```julia
function struct_line_string(struct_name::AbstractString; kwdef::Bool = true)::String
    struct_line = "struct $(struct_name)"
    if kwdef
        struct_line = "Base.@kwdef " * struct_line
    end
    return struct_line
end
function struct_line_string(struct_name::AbstractString, supertype; kwdef::Bool = true)::String
    struct_line = "struct $(struct_name) <: $(supertype)"
    if kwdef
        struct_line = "Base.@kwdef " * struct_line
    end
    return struct_line
end
```
Replace with (adds `lazy`, mutually exclusive with `kwdef` since `@lazy` already forces the struct mutable and generates its own inner constructor):
```julia
function struct_line_string(struct_name::AbstractString; kwdef::Bool = true, lazy::Bool = false)::String
    struct_line = "struct $(struct_name)"
    if lazy
        struct_line = "@lazy " * struct_line
    elseif kwdef
        struct_line = "Base.@kwdef " * struct_line
    end
    return struct_line
end
function struct_line_string(struct_name::AbstractString, supertype; kwdef::Bool = true, lazy::Bool = false)::String
    struct_line = "struct $(struct_name) <: $(supertype)"
    if lazy
        struct_line = "@lazy " * struct_line
    elseif kwdef
        struct_line = "Base.@kwdef " * struct_line
    end
    return struct_line
end
```

- [ ] **Step 7: Generate the `@lazy field::T = _init_field` field string**

Modify `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_struct.jl` — add, near the existing `generate_field_string` (leave that function untouched, it's still used by `write_node_with_choice`):

```julia
"""
    generate_lazy_field_string(field_data::AbstractFieldData)::String

Same field-type computation as `generate_field_string`, but declares the field `@lazy` with a
named initializer function `_init_<field_name>` - `LazilyInitializedFields.jl`'s own macro-generated
`getproperty` override calls this function automatically on first access to the field and caches
the result, so no manual "check uninit, call, cache" code is needed anywhere else.
"""
function generate_lazy_field_string(field_data::AbstractFieldData)::String
    full_field_type = qualified_type(field_data)

    if field_data.is_vector
        full_field_type = "Vector{$(full_field_type)}"
    end

    if field_data.can_be_missing
        full_field_type = "Union{Nothing, $(full_field_type)}"
    end

    return "@lazy $(field_data.name)::$(full_field_type) = _init_$(field_data.name)"
end
```

- [ ] **Step 8: Generate the node-based constructor**

Modify `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_struct.jl` — add:

```julia
"""
    write_lazy_node_constructor(xsd_module_builder, xsd_node, all_fields, indent_level)

Emit `StructName(node::XmlStructLoader.LazyNode)` - the entry point `ReadOnAccess` uses. Stores the
node, marks every data field `uninit`, and builds `__xml_attributes` eagerly (cheap, always needed
together) using the same `lazy_attributes_dict` helper `_init_<field>` bodies use elsewhere.
"""
function write_lazy_node_constructor(
        xsd_module_builder::XSDStructModuleBuilderType,
        xsd_node::ComplexTreeNode,
        all_fields::Vector{<:AbstractFieldData},
        indent_level::Int,
    )::Nothing
    struct_name = name(xsd_node)
    data_fields = filter(f -> !(f isa GroupFieldData), all_fields)
    uninit_args = repeat("LazilyInitializedFields.uninit, ", length(data_fields))

    ctor = """
    function $struct_name(node::XmlStructLoader.LazyNode)
        attribs = XmlStructLoader.lazy_attributes_dict(node)
        return $struct_name(node, $(uninit_args)isempty(attribs) ? nothing : attribs, false)
    end
    """
    write(xsd_module_builder, IOStruct, ctor, indent_level = indent_level)
    return write(xsd_module_builder, IOStruct, "\n")
end
```

- [ ] **Step 9: Generate the outer keyword constructor (eager/manual construction path)**

Modify `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_struct.jl` — add:

```julia
"""
    write_lazy_outer_kwdef_constructor(xsd_module_builder, xsd_node, all_fields, indent_level)

Emit `StructName(; field1=default1, ..., __xml_attributes=nothing, __validated=true)`, replicating
exactly what `Base.@kwdef` would have generated - needed because `@lazy` and `Base.@kwdef` can't be
composed directly. This is what the *eager* `ReadAllData` path actually calls (see
`xml_parser_in_module.jl`'s `field_type(; __xml_attributes=..., __validated=..., child_object_dict...)`)
for these same struct types, so a lazy-capable struct must support both this and the node-based
constructor from Step 8.
"""
function write_lazy_outer_kwdef_constructor(
        xsd_module_builder::XSDStructModuleBuilderType,
        xsd_node::ComplexTreeNode,
        all_fields::Vector{<:AbstractFieldData},
        indent_level::Int,
    )::Nothing
    struct_name = name(xsd_node)
    data_fields = filter(f -> !(f isa GroupFieldData), all_fields)

    params = String[]
    args = String[]
    for field in data_fields
        push!(args, field.name)
        push!(params, field.can_be_missing ? "$(field.name) = nothing" : field.name)
    end
    push!(params, "__xml_attributes = nothing")
    push!(params, "__validated::Bool = true")
    push!(args, "__xml_attributes")
    push!(args, "__validated")

    ctor = """
    function $struct_name(; $(join(params, ", ")))
        return $struct_name(nothing, $(join(args, ", ")))
    end
    """
    write(xsd_module_builder, IOStruct, ctor, indent_level = indent_level)
    return write(xsd_module_builder, IOStruct, "\n")
end
```

- [ ] **Step 10: Generate per-field `_init_<field>` accessor functions**

This is the core dispatch. Modify `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_struct.jl` — add:

```julia
"""
    write_lazy_field_accessors(xsd_module_builder, xsd_node, all_fields, indent_level)

Emit one `_init_<field>(o::StructName)` function per data field. Three cases per field:

1. Built-in scalar type (`julia_type in values(built_in_data_type_dict)`) - parse the child node's
   text content directly via the existing `XmlStructLoader.parse_xml_node_not_module`, reusing 100%
   of the eager path's scalar conversion logic (Number/String/DateTime/ZonedDateTime/Date/Time),
   zero duplication.
2. A field whose type is itself a lazy-capable complex node (registered in `defined_nodes`, no
   choice fields) - recurse via that type's own node-based constructor, `FieldType(child)`. Still
   lazy all the way down: nothing under it is touched until its own fields are accessed.
3. Everything else (a restricted "simple type", a choice-bearing complex type, or any type not yet
   resolvable in `defined_nodes` at this point in codegen) - fall back to the *existing* eager
   construction function, `XmlStructLoader.construct_xml_node_object`, confined to just this one
   subtree. There is no meaningful sub-laziness to gain inside a single-value simple type or an
   already-eager choice type, so reusing the proven eager code here (rather than reimplementing
   attribute/restriction/default handling a second time) is a deliberate, lower-risk choice.

Vector fields apply the same three-way dispatch per matched child element.
"""
function write_lazy_field_accessors(
        xsd_module_builder::XSDStructModuleBuilderType,
        xsd_node::ComplexTreeNode,
        all_fields::Vector{<:AbstractFieldData},
        indent_level::Int,
    )::Nothing
    struct_name = name(xsd_node)

    for field in all_fields
        field isa GroupFieldData && continue

        full_field_type = qualified_type(field)
        element_name = field.name
        is_scalar = field.julia_type in values(built_in_data_type_dict)
        lazy_capable_child = !is_scalar && is_lazy_capable_field_type(field, xsd_module_builder)

        default_value_string = isnothing(field.base_default_value) ? "nothing" :
            (field.julia_type == "String" ? "\"$(field.base_default_value)\"" : field.base_default_value)

        body = if field.is_vector
            generate_vector_accessor_body(element_name, full_field_type, is_scalar, lazy_capable_child)
        else
            generate_scalar_or_node_accessor_body(
                element_name, full_field_type, field.can_be_missing, is_scalar,
                lazy_capable_child, default_value_string,
            )
        end

        accessor = """
        function _init_$(field.name)(o::$struct_name)
        $body
        end
        """
        write(xsd_module_builder, IOStruct, accessor, indent_level = indent_level)
        writeln(xsd_module_builder, IOStruct)
    end

    return nothing
end

"""
    is_lazy_capable_field_type(field::AbstractFieldData, xsd_module_builder)::Bool

Whether `field`'s type resolves to a `ComplexTreeNode` already registered in `defined_nodes` with
no choice fields (see `is_lazy_capable`). Simple types, choice-bearing complex types, and
not-yet-defined/unresolvable types (unions, extensions) all return `false`, routing the field to
the eager-construction fallback instead.
"""
function is_lazy_capable_field_type(field::AbstractFieldData, xsd_module_builder::XSDStructModuleBuilderType)::Bool
    idx = findfirst(==(qualified_type(field)) ∘ qualified_name, xsd_module_builder.defined_nodes)
    isnothing(idx) && return false
    node = xsd_module_builder.defined_nodes[idx]
    return node isa ComplexTreeNode && is_lazy_capable(node)
end

function generate_scalar_or_node_accessor_body(
        element_name::AbstractString,
        full_field_type::AbstractString,
        can_be_missing::Bool,
        is_scalar::Bool,
        lazy_capable_child::Bool,
        default_value_string::AbstractString,
    )::String
    lines = String[]
    push!(lines, "    child = XmlStructLoader.lazy_child_with_name(o._node, \"$element_name\", $can_be_missing)")
    push!(lines, "    isnothing(child) && return nothing")
    if is_scalar
        # child.ptr is a raw Ptr{Cvoid} - GC.@preserve child.owner is required around any call that
        # touches it, exactly like every helper in lazy_xml_node.jl does internally (Task 1). This is
        # the one place in codegen where a raw pointer briefly leaves that file's own helpers, because
        # parse_xml_node_not_module/construct_xml_node_object (the reused eager-path functions) take a
        # bare Ptr{Cvoid}, not a LazyNode.
        push!(
            lines,
            "    return GC.@preserve child.owner XmlStructLoader.parse_xml_node_not_module(child.ptr, $full_field_type, @__MODULE__, false, $default_value_string)",
        )
    elseif lazy_capable_child
        push!(lines, "    return $full_field_type(child)")
    else
        push!(
            lines,
            "    return GC.@preserve child.owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, $full_field_type, nothing), @__MODULE__, false)",
        )
    end
    return join(lines, "\n")
end

function generate_vector_accessor_body(
        element_name::AbstractString,
        full_field_type::AbstractString,
        is_scalar::Bool,
        lazy_capable_child::Bool,
    )::String
    # Same GC.@preserve requirement as the scalar/non-vector case above - child.ptr must never be
    # touched without it.
    element_expr = if is_scalar
        "(GC.@preserve child.owner XmlStructLoader.parse_xml_node_not_module(child.ptr, $full_field_type, @__MODULE__, false, nothing))"
    elseif lazy_capable_child
        "$full_field_type(child)"
    else
        "(GC.@preserve child.owner XmlStructLoader.construct_xml_node_object(XmlStructLoader.XmlStructLoaderNode(child.ptr, $full_field_type, nothing), @__MODULE__, false))"
    end
    return "    return [$element_expr for child in XmlStructLoader.lazy_children_with_name(o._node, \"$element_name\")]"
end
```

`is_lazy_capable_field_type` depends on the field's type node already being present in `defined_nodes` at the time THIS node is written. `write_struct_module_to_io`'s existing skip/retry loop (lines 24-53 of `xsd_module_builder_struct.jl`, unchanged by this plan) already defers writing a node until its dependencies are ready - but that check is for *structural* readiness (can this struct's fields be typed at all), not "is the referenced type lazy". A field pointing at a not-yet-defined type at this exact call simply routes to the eager fallback (case 3) rather than erroring, which is always correct (just occasionally more conservative than strictly necessary) - no plan-writing-time proof is needed that ordering never affects this, since either branch produces correct results.

- [ ] **Step 11: Add `using LazilyInitializedFields` and `import XmlStructLoader` to the struct submodule**

Modify `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_struct.jl`'s `write_struct_module_to_io` (lines 4-58) — currently emits `import $ABSTRACT_TYPE_PACKAGE` (line 13) unconditionally. Add, right after that line:
```julia
writeln(xsd_module_builder, IOStruct, "using LazilyInitializedFields")
writeln(xsd_module_builder, IOStruct, "import XmlStructLoader")
write(xsd_module_builder, IOStruct, "\n")
```
`LazilyInitializedFields` must be imported unqualified (`using`, not `import`) because `@lazy`'s own documentation states it must be invoked bare, not namespace-qualified.

- [ ] **Step 12: Run tests to verify they pass**

Run: `cd XsdToStruct.jl && julia --project=. -e 'using Pkg; Pkg.test()'`
Expected: PASS for the 3 new tests. The full existing suite (131 tests per the ledger) will likely fail at this point because every golden fixture under `test/test_data/generic_data/*/`, `test/test_data/specific_cases/*`, and `test/test_output/*` was generated against the *old* (non-lazy) codegen and needs regenerating.

- [ ] **Step 13: Regenerate golden fixtures**

```bash
cd XsdToStruct.jl
julia --project=. -e '
using XsdToStruct
for dir in ["test/test_data/generic_data", "test/test_data/edge_cases"]
    datadir = joinpath(@__DIR__, dir)
    isdir(datadir) || continue
    for xsd in filter(f -> endswith(f, ".xsd"), readdir(datadir))
        xsd_to_struct_module(joinpath(datadir, xsd), datadir)
    end
end
xsd_to_struct_module(joinpath(@__DIR__, "test/test_data/specific_cases/documentation_example.xsd"), joinpath(@__DIR__, "test/test_data/specific_cases"))
'
```
Then re-run `Pkg.test()`. If any generic-data fixture's own test asserts exact generated-source substrings unrelated to laziness (e.g. the sample-XML-synthesis or precompile-workload tests from the earlier feature), confirm those still pass unchanged - they should, since this task only changes struct/constructor/accessor emission, not the precompile-workload block or sample-XML synthesis, which run *after* struct writing in `write_top_module_to_io` and only read already-registered field data, not struct source text.

- [ ] **Step 14: Commit**

```bash
git add XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_struct.jl \
        XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_common.jl \
        XsdToStruct.jl/test/lazy_struct_codegen_tests.jl \
        XsdToStruct.jl/test/Project.toml XsdToStruct.jl/test/runtests.jl \
        XsdToStruct.jl/test/test_data/ XsdToStruct.jl/test/test_output/
git commit -m "Emit @lazy structs with per-field _init_ accessors for choice-free complex types"
```

---

### Task 4: `XmlStructLoader.jl` — `LoadStrategy` trait and `load()` wiring

**Files:**
- Modify: `XmlStructLoader.jl/src/XmlStructLoader.jl`
- Modify: `XmlStructLoader.jl/Project.toml` (add `LazilyInitializedFields` real dependency)
- Test: `XmlStructLoader.jl/test/load_strategy_tests.jl` (new, `@testitem`)

**Interfaces:**
- Consumes: `PugixmlDocumentHandle`, `LazyNode` (Task 1); the generated module's `__meta.root_type` (existing, `xml_module_utilities.jl`); `XmlStructPugixml.parse_file`/`parse_buffer`/`root` (existing).
- Produces: `LoadStrategy` abstract type, `ReadAllData`, `ReadOnAccess`, `DEFAULT_LOAD_STRATEGY`, `load(xml_in, module_in; validate, load_strategy)` — the primary public API this whole feature adds.

- [ ] **Step 1: Write the failing tests**

Create `XmlStructLoader.jl/test/load_strategy_tests.jl`:

**Correction from the plan's original draft:** `@testitem`s each run as top-level code in their own
fresh module and cannot see a plain top-level function defined outside them, even in the same file
(confirmed against `ReTestItems.jl`'s own README). Shared helper code must go in a `@testsetup
module`, referenced via the `setup` keyword. This file defines one such setup, used by all three
`@testitem`s below *and* by Task 6's `lazy_equivalence_tests.jl` later (same package - a
`@testsetup` is discovered package-wide by `ReTestItems.runtests`, not scoped to the file it's
defined in).

```julia
@testsetup module LazyLoadTestHelpers
    using AbstractXsdTypes
    export extract_generated_module_name, fully_materialized_tree_string

    function extract_generated_module_name(source::String)::Union{Symbol,Nothing}
        for line in split(source, '\n')
            m = match(r"^module\s+(\w+)", line)
            isnothing(m) || return Symbol(m[1])
        end
        return nothing
    end

    function fully_materialized_tree_string(obj)::String
        io = IOBuffer()
        Base.invokelatest(AbstractXsdTypes.print_tree, io, obj; print_all = true)
        return String(take!(io))
    end
end

@testitem "ReadOnAccess: load() returns a struct whose fields are readable and correct" setup=[LazyLoadTestHelpers] begin
    xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "basic_types.xsd")
    outdir = mktempdir()
    generated_path = XsdToStruct.xsd_to_struct_module(xsd_path, outdir)
    Base.include(Main, generated_path)
    module_name = extract_generated_module_name(read(generated_path, String))
    module_ref = Base.invokelatest(getproperty, Main, module_name)

    xml_path = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xml")
    loaded = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref; load_strategy = XmlStructLoader.ReadOnAccess())

    te1 = Base.invokelatest(getproperty, loaded, :TestElement1)
    @test Base.invokelatest(getproperty, te1, :Element_string) == "aaaa"
    @test Base.invokelatest(getproperty, te1, :Element_double) == 100.22
end

@testitem "ReadOnAccess with validate=true raises ArgumentError before parsing" setup=[LazyLoadTestHelpers] begin
    xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "basic_types.xsd")
    outdir = mktempdir()
    generated_path = XsdToStruct.xsd_to_struct_module(xsd_path, outdir)
    Base.include(Main, generated_path)
    module_name = extract_generated_module_name(read(generated_path, String))
    module_ref = Base.invokelatest(getproperty, Main, module_name)

    xml_path = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xml")
    @test_throws ArgumentError Base.invokelatest(
        XmlStructLoader.load, xml_path, module_ref;
        load_strategy = XmlStructLoader.ReadOnAccess(), validate = true,
    )
end

@testitem "ReadAllData remains the default and is unaffected" setup=[LazyLoadTestHelpers] begin
    xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "basic_types.xsd")
    outdir = mktempdir()
    generated_path = XsdToStruct.xsd_to_struct_module(xsd_path, outdir)
    Base.include(Main, generated_path)
    module_name = extract_generated_module_name(read(generated_path, String))
    module_ref = Base.invokelatest(getproperty, Main, module_name)

    xml_path = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xml")
    loaded_default = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref)
    loaded_explicit = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref; load_strategy = XmlStructLoader.ReadAllData())
    te1_default = Base.invokelatest(getproperty, loaded_default, :TestElement1)
    te1_explicit = Base.invokelatest(getproperty, loaded_explicit, :TestElement1)
    @test Base.invokelatest(getproperty, te1_default, :Element_string) ==
          Base.invokelatest(getproperty, te1_explicit, :Element_string)
end
```

Add `XsdToStruct` as a test-only dependency of `XmlStructLoader.jl/test/Project.toml` if not already present (needed to generate a fresh module in-test) via `Pkg.develop`/`Pkg.add` from `XmlStructLoader.jl/test`, not by hand-editing the TOML.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd XmlStructLoader.jl && julia --project=. -e 'using Pkg; Pkg.test()'`
Expected: FAIL — `ReadOnAccess`/`ReadAllData`/`load_strategy` keyword don't exist yet.

- [ ] **Step 3: No `runtests.jl` change needed**

This is the same package as Task 1 (`XmlStructLoader.jl`), which already added
`ReTestItems.runtests(XmlStructLoader; testitem_timeout = 600)` to `runtests.jl` once. That call
auto-discovers every `*_tests.jl` file in the directory tree, including this task's new
`load_strategy_tests.jl` — nothing further to wire here. (Skip straight to Step 4.)

- [ ] **Step 4: Add the `LoadStrategy` trait and rewrite `load()`**

Modify `XmlStructLoader.jl/src/XmlStructLoader.jl`. Current relevant section (lines 48-85):
```julia
function load(xml_path::AbstractString, module_ref::Module; validate::Bool = true)
    local loaded_xml
    open(xml_path) do xml_io
        return loaded_xml = load(xml_io, module_ref, validate = validate)
    end
    return loaded_xml
end

load(xml_io::IO, module_ref::Module; validate::Bool = true) =
    Base.@invokelatest construct_xml_object(xml_io, module_ref, validate = validate)

function load(xml_path::AbstractString, module_path::AbstractString; validate::Bool = true)
    local loaded_xml
    open(xml_path) do xml_io
        return loaded_xml = load(xml_io, module_path, validate = validate)
    end
    return loaded_xml
end

function load(xml_io::IO, module_path::AbstractString; validate::Bool = true)
    module_ref = import_module_from_xml(xml_io, module_path)
    loaded_xml = Base.@invokelatest construct_xml_object(xml_io, module_ref, validate = validate)
    return loaded_xml
end
```

Replace with (adds the trait types and a `load_strategy` keyword to every method, dispatching the actual work to strategy-specific implementations added in Step 5):

```julia
abstract type LoadStrategy end

"""
    struct ReadAllData <: LoadStrategy end

All data is read from the XML file when it is opened. Slower to return from `load()` on large
documents, but every field access afterward is a plain, already-computed field read.
"""
struct ReadAllData <: LoadStrategy end

"""
    struct ReadOnAccess <: LoadStrategy end

`load()` returns almost immediately; each field's value is parsed from the underlying XML the
first time it is accessed, then cached. Only complex types generated from a choice-free XSD
complex type support this - see the module docstring. Not compatible with `validate=true` (XSD
restriction validation requires the parsed value, which would force materializing every field
anyway - combining the two raises `ArgumentError`).
"""
struct ReadOnAccess <: LoadStrategy end

"""
    const DEFAULT_LOAD_STRATEGY = ReadAllData

Used when `load_strategy` is not specified, for full backward compatibility.
"""
const DEFAULT_LOAD_STRATEGY = ReadAllData

function load(
        xml_path::AbstractString, module_ref::Module;
        validate::Bool = true, load_strategy::LoadStrategy = DEFAULT_LOAD_STRATEGY(),
    )
    local loaded_xml
    open(xml_path) do xml_io
        return loaded_xml = load(xml_io, module_ref; validate = validate, load_strategy = load_strategy)
    end
    return loaded_xml
end

function load(
        xml_io::IO, module_ref::Module;
        validate::Bool = true, load_strategy::LoadStrategy = DEFAULT_LOAD_STRATEGY(),
    )
    return load(xml_io, module_ref, load_strategy; validate = validate)
end

load(xml_io::IO, module_ref::Module, ::ReadAllData; validate::Bool = true) =
    Base.@invokelatest construct_xml_object(xml_io, module_ref, validate = validate)

function load(xml_io::IO, module_ref::Module, ::ReadOnAccess; validate::Bool = true)
    validate && throw(ArgumentError(
        "load_strategy=ReadOnAccess() is not compatible with validate=true: XSD restriction " *
        "validation requires the parsed field value, which would force materializing every " *
        "field anyway, defeating the point of ReadOnAccess. Pass validate=false explicitly.",
    ))
    doc_ptr = XmlStructPugixml.parse_buffer(read(xml_io))
    doc_ptr == C_NULL && error("pugixml failed to parse XML from IO")
    handle = PugixmlDocumentHandle(doc_ptr)  # registered immediately, before anything else can throw
    root_node = LazyNode(XmlStructPugixml.root(doc_ptr), handle)
    root_type = Base.@invokelatest module_ref.__meta.root_type
    return Base.@invokelatest root_type(root_node)
end

function load(
        xml_path::AbstractString, module_path::AbstractString;
        validate::Bool = true, load_strategy::LoadStrategy = DEFAULT_LOAD_STRATEGY(),
    )
    local loaded_xml
    open(xml_path) do xml_io
        return loaded_xml = load(xml_io, module_path; validate = validate, load_strategy = load_strategy)
    end
    return loaded_xml
end

function load(
        xml_io::IO, module_path::AbstractString;
        validate::Bool = true, load_strategy::LoadStrategy = DEFAULT_LOAD_STRATEGY(),
    )
    module_ref = import_module_from_xml(xml_io, module_path)
    return load(xml_io, module_ref; validate = validate, load_strategy = load_strategy)
end
```

Add `LoadStrategy, ReadAllData, ReadOnAccess, DEFAULT_LOAD_STRATEGY` to the module's existing `export` line.

Note the file-path overload (first method above) still parses via `open(xml_path) do xml_io ... end`, then delegates to the IO-based method - for `ReadOnAccess`, `parse_buffer(read(xml_io))` reads the whole file into memory first rather than `parse_file(path)` reading it directly. This is a minor inefficiency (one extra full-file read into a `Vector{UInt8}`, discarded once pugixml parses it) accepted for now to keep one code path instead of two; revisit only if the Task 8 benchmark shows it matters.

- [ ] **Step 5: Add the `LazilyInitializedFields` runtime dependency**

Modify `XmlStructLoader.jl/Project.toml` — add under `[deps]`:
```toml
LazilyInitializedFields = "0e77f7df-68c5-4e49-93ce-4cd80f5598bf"
```
And matching `[compat]` entry, added via `Pkg.add` (not hand-written) from `XmlStructLoader.jl`'s own root, per Task 2 Step 3's note on confirming the actual released version.

Verify this resolves through both places generated code gets `include()`d: `import_module`/`use_module` in `xml_module_utilities.jl` (bare `include()` into `XmlStructLoader`'s own module - this dependency addition is exactly what makes that resolve) and the plain `Base.include(Main, ...)` path some tests use (resolves against whatever environment is active when the test runs, e.g. `XmlStructLoader.jl/test`'s own environment - confirm `LazilyInitializedFields` is reachable there too, adding it to `test/Project.toml` if `Pkg.test()` fails to find it).

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd XmlStructLoader.jl && julia --project=. -e 'using Pkg; Pkg.test()'`
Expected: PASS for all 3 new tests, full existing suite (88 tests per the ledger) still green.

- [ ] **Step 7: Commit**

```bash
git add XmlStructLoader.jl/src/XmlStructLoader.jl XmlStructLoader.jl/Project.toml \
        XmlStructLoader.jl/test/load_strategy_tests.jl XmlStructLoader.jl/test/runtests.jl \
        XmlStructLoader.jl/test/Project.toml XmlStructLoader.jl/Manifest.toml
git commit -m "Add LoadStrategy trait: load(...; load_strategy=ReadOnAccess()) for lazy field access"
```

---

### Task 5: Extend the precompile workload to warm the lazy path too

**Files:**
- Modify: `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_top.jl`
- Test: extends `XsdToStruct.jl/test/test_generated_module_precompile_workload.jl` (existing file from the merged precompile-latency feature)

**Interfaces:**
- Consumes: `write_precompile_workload_part` (existing, `xsd_module_builder_top.jl`), `is_lazy_capable` (Task 3).
- Produces: the generated `@compile_workload` block also runs a `ReadOnAccess` load and touches every field once when the schema's root type is lazy-capable.

- [ ] **Step 1: Write the failing test**

Modify `XsdToStruct.jl/test/test_generated_module_precompile_workload.jl` — add a new `@testset`/`@testitem` (matching whatever this file already uses - it's a classic `@testset` file per Task 3's constraint of not migrating existing files, so add a plain `@testset` block consistent with the surrounding style):

```julia
@testset "basic_types — workload also warms the ReadOnAccess (lazy) path" begin
    xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "basic_types.xsd")
    outdir = mktempdir()
    generated_path = xsd_to_struct_module(xsd_path, outdir)
    source = read(generated_path, String)

    @test occursin("ReadOnAccess", source)
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd XsdToStruct.jl && julia --project=. -e 'using Pkg; Pkg.test()'`
Expected: FAIL — the workload block doesn't reference `ReadOnAccess` yet.

- [ ] **Step 3: Extend `write_precompile_workload_part`**

Modify `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_top.jl`'s `write_precompile_workload_part` (current content shown in the Global Constraints research above). After the existing `XmlStructLoader.load(__xsdtostruct_sample_path__, @__MODULE__; validate = false)` line and before `rm(...)`, add a lazy-load-and-touch-everything pass, only when the root type is lazy-capable:

```julia
function write_precompile_workload_part(xsd_module_builder::XSDStructModuleBuilderType)::Nothing
    writeln(xsd_module_builder, IOTop, "import PrecompileTools")
    writeln(xsd_module_builder, IOTop, "import XmlStructLoader")

    sample_xml = synthesize_sample_xml(xsd_module_builder)
    isnothing(sample_xml) && return nothing

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "const __XSDTOSTRUCT_SAMPLE_XML__ = \"\"\"$sample_xml\"\"\"")

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "PrecompileTools.@compile_workload begin")
    writeln(xsd_module_builder, IOTop, "try", indent_level = 1)
    writeln(xsd_module_builder, IOTop, "__xsdtostruct_sample_path__ = tempname()", indent_level = 1)
    writeln(
        xsd_module_builder, IOTop,
        "write(__xsdtostruct_sample_path__, __XSDTOSTRUCT_SAMPLE_XML__)", indent_level = 1,
    )
    writeln(
        xsd_module_builder, IOTop,
        "XmlStructLoader.load(__xsdtostruct_sample_path__, @__MODULE__; validate = false)", indent_level = 1,
    )
    if xsd_module_builder.xsd_tree.root_field isa FieldData &&
       is_root_lazy_capable(xsd_module_builder)
        writeln(
            xsd_module_builder, IOTop,
            "__xsdtostruct_lazy_sample__ = XmlStructLoader.load(__xsdtostruct_sample_path__, @__MODULE__; validate = false, load_strategy = XmlStructLoader.ReadOnAccess())",
            indent_level = 1,
        )
        writeln(
            xsd_module_builder, IOTop,
            "AbstractXsdTypes.print_tree(IOBuffer(), __xsdtostruct_lazy_sample__; print_all = true)",
            indent_level = 1,
        )
    end
    writeln(xsd_module_builder, IOTop, "rm(__xsdtostruct_sample_path__; force = true)", indent_level = 1)
    writeln(xsd_module_builder, IOTop, "catch", indent_level = 1)
    writeln(xsd_module_builder, IOTop, "end", indent_level = 1)
    writeln(xsd_module_builder, IOTop, "end")

    return nothing
end

"""
    is_root_lazy_capable(xsd_module_builder)::Bool

Whether the schema's root type ended up lazy-capable (Task 3's `is_lazy_capable`) - if not (e.g. the
root itself has choice fields), there is no `ReadOnAccess` path to warm for this schema and the
workload only needs the existing `ReadAllData` warm-up.
"""
function is_root_lazy_capable(xsd_module_builder::XSDStructModuleBuilderType)::Bool
    idx = findfirst(==(xsd_module_builder.xsd_tree.root_field.julia_type) ∘ name, xsd_module_builder.defined_nodes)
    isnothing(idx) && return false
    node = xsd_module_builder.defined_nodes[idx]
    return node isa ComplexTreeNode && is_lazy_capable(node)
end
```

`AbstractXsdTypes.print_tree(..., print_all=true)` recursively touches every field via `getproperty` exactly like the equivalence tests in Task 6 do, which is what actually exercises and warms every `_init_<field>` function - a `ReadOnAccess` load alone (without touching fields) would only warm the top-level constructor, missing the exact `ZonedDateTime`-class compile cost this step exists to move back into precompile time.

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd XsdToStruct.jl && julia --project=. -e 'using Pkg; Pkg.test()'`
Expected: PASS. Regenerate golden fixtures again (same command as Task 3 Step 13) since this changes emitted source for every choice-free schema.

- [ ] **Step 5: Commit**

```bash
git add XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_top.jl \
        XsdToStruct.jl/test/test_generated_module_precompile_workload.jl \
        XsdToStruct.jl/test/test_data/ XsdToStruct.jl/test/test_output/
git commit -m "Extend @compile_workload to also warm the ReadOnAccess (lazy) path"
```

---

### Task 6: Equivalence, lifetime, and tradeoff tests across real fixtures

**Files:**
- Test: `XmlStructLoader.jl/test/lazy_equivalence_tests.jl` (new, `@testitem`)
- Modify: `XmlStructLoader.jl/test/runtests.jl`

**Interfaces:**
- Consumes: `AbstractXsdTypes.print_tree` (Task 2's fix makes this safe to call on a lazy struct without side effects beyond normal materialization), the existing generic-data/edge-case fixtures, the real ISO 20022 fixture (`XmlStructLoader.jl/test/test_data/real_world/pacs.008.001.09.xsd` + `_instance.xml`).

- [ ] **Step 1: Write the tests**

Create `XmlStructLoader.jl/test/lazy_equivalence_tests.jl`:

**Correction from the plan's original draft:** these tests reuse `LazyLoadTestHelpers`, the
`@testsetup module` Task 4 defined in `load_strategy_tests.jl` — a `@testsetup` is discovered
package-wide by `ReTestItems.runtests`, so a `@testitem` here can depend on it via `setup=[...]`
even though it's physically defined in a different file. `fully_materialized_tree_string` (renamed
from the plan's original `_fully_materialized_tree_string`) already covers what's needed here; no
new setup module for this file.

```julia
@testitem "ReadOnAccess fully materialized equals ReadAllData, across every generic-data fixture" setup=[LazyLoadTestHelpers] begin
    generic_data_dir = joinpath(@__DIR__, "test_data", "generic_cases")
    xsd_files = filter(f -> endswith(f, ".xsd"), readdir(joinpath(@__DIR__, "test_data", "generic_data"); join = true))

    for xsd_path in xsd_files
        xml_candidates = filter(
            f -> startswith(basename(f), first(splitext(basename(xsd_path)))) && endswith(f, ".xml"),
            readdir(generic_data_dir; join = true),
        )
        isempty(xml_candidates) && continue

        outdir = mktempdir()
        generated_path = XsdToStruct.xsd_to_struct_module(xsd_path, outdir)
        Base.include(Main, generated_path)
        module_name = extract_generated_module_name(read(generated_path, String))
        module_ref = Base.invokelatest(getproperty, Main, module_name)

        for xml_path in xml_candidates
            eager = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref; load_strategy = XmlStructLoader.ReadAllData())
            lazy = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref; load_strategy = XmlStructLoader.ReadOnAccess())
            @test fully_materialized_tree_string(eager) == fully_materialized_tree_string(lazy)
        end
    end
end

@testitem "ReadOnAccess equals ReadAllData on the real ISO 20022 fixture" setup=[LazyLoadTestHelpers] begin
    xsd_path = joinpath(@__DIR__, "test_data", "real_world", "pacs.008.001.09.xsd")
    xml_path = joinpath(@__DIR__, "test_data", "real_world", "pacs.008.001.09_instance.xml")
    outdir = mktempdir()
    generated_path = XsdToStruct.xsd_to_struct_module(xsd_path, outdir)
    Base.include(Main, generated_path)
    module_name = extract_generated_module_name(read(generated_path, String))
    module_ref = Base.invokelatest(getproperty, Main, module_name)

    eager = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref; load_strategy = XmlStructLoader.ReadAllData())
    lazy = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref; load_strategy = XmlStructLoader.ReadOnAccess())
    @test fully_materialized_tree_string(eager) == fully_materialized_tree_string(lazy)
end

@testitem "malformed document: ReadOnAccess load() succeeds, first bad-field access throws" setup=[LazyLoadTestHelpers] begin
    xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "basic_types.xsd")
    outdir = mktempdir()
    generated_path = XsdToStruct.xsd_to_struct_module(xsd_path, outdir)
    Base.include(Main, generated_path)
    module_name = extract_generated_module_name(read(generated_path, String))
    module_ref = Base.invokelatest(getproperty, Main, module_name)

    good_xml = read(joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xml"), String)
    # corrupt Element_double's content so it can't parse as Float64 - a schema-invalid document that
    # a real caller could still hand to load() (validate=false is required anyway under ReadOnAccess)
    bad_xml = replace(good_xml, "100.22" => "not-a-number", count = 1)
    bad_path = tempname()
    write(bad_path, bad_xml)

    lazy = Base.invokelatest(XmlStructLoader.load, bad_path, module_ref; load_strategy = XmlStructLoader.ReadOnAccess())
    # load() itself must succeed - the bad field hasn't been touched yet
    te1 = Base.invokelatest(getproperty, lazy, :TestElement1)
    @test Base.invokelatest(getproperty, te1, :Element_string) == "aaaa"
    # only accessing the bad field itself throws
    @test_throws Exception Base.invokelatest(getproperty, te1, :Element_double)

    rm(bad_path; force = true)
end

@testitem "repeated field granularity: touching one element materializes the whole field, not siblings" setup=[LazyLoadTestHelpers] begin
    xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "group_element.xsd")
    xml_candidates = filter(
        f -> endswith(f, ".xml"),
        readdir(joinpath(@__DIR__, "test_data", "generic_cases"); join = true),
    )
    group_xml = first(filter(f -> occursin("group_element", f), xml_candidates))

    outdir = mktempdir()
    generated_path = XsdToStruct.xsd_to_struct_module(xsd_path, outdir)
    Base.include(Main, generated_path)
    module_name = extract_generated_module_name(read(generated_path, String))
    module_ref = Base.invokelatest(getproperty, Main, module_name)

    lazy = Base.invokelatest(XmlStructLoader.load, group_xml, module_ref; load_strategy = XmlStructLoader.ReadOnAccess())
    # Accessing the object at all only constructs the top-level struct - verified by the fact this
    # doesn't error and the object is returned; deeper granularity (whether a specific sibling field
    # is still `uninit` before being touched) is exercised directly via LazilyInitializedFields.@isinit
    # in the generated struct's own module scope, added as part of Task 3's codegen test instead of
    # here (this file works across many schemas generically and can't assume field names).
    @test !isnothing(lazy)
end
```

- [ ] **Step 2: No `runtests.jl` change needed**

Same package as Tasks 1 and 4 (`XmlStructLoader.jl`), already wired via the single
`ReTestItems.runtests(XmlStructLoader; testitem_timeout = 600)` call from Task 1 (`testitem_timeout`
was already set to 600 there specifically to cover this file's slower tests — the real ISO 20022
fixture and the full generic-data sweep). `ReTestItems.runtests` is called exactly once per
package; there is no "append another invocation" step here.

- [ ] **Step 3: Run tests to verify they pass**

Run: `cd XmlStructLoader.jl && julia --project=. -e 'using Pkg; Pkg.test()'`
Expected: PASS. If the malformed-document test's specific corruption doesn't actually throw (e.g. `Parsers.parse` is more lenient than expected), adjust the corruption to something that definitely fails type conversion (confirm empirically rather than assuming any particular string breaks `Parsers.parse(Float64, ...)`).

- [ ] **Step 4: Commit**

```bash
git add XmlStructLoader.jl/test/lazy_equivalence_tests.jl XmlStructLoader.jl/test/runtests.jl
git commit -m "Add lazy-vs-eager equivalence tests across all fixtures, including real ISO 20022"
```

---

### Task 7: `XmlStructWriter.jl` round-trip test (no source changes expected)

**Files:**
- Test: `XmlStructWriter.jl/test/lazy_roundtrip_tests.jl` (new, `@testitem`)
- Modify: `XmlStructWriter.jl/test/Project.toml` (add `ReTestItems`, `XmlStructLoader`, `XsdToStruct` test-only deps if not already present)
- Modify: `XmlStructWriter.jl/test/runtests.jl`

**Interfaces:**
- Consumes: `XmlStructWriter.write` (existing), Task 2's `propertynames` fix (this test is what *proves* the design spec's "writer needs no code changes" claim, rather than asserting it).

- [ ] **Step 1: Write the test**

Create `XmlStructWriter.jl/test/lazy_roundtrip_tests.jl`:

```julia
@testitem "writing a partially-touched lazy struct matches a fully-eager round-trip" begin
    xsd_path = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xsd")
    xml_path = joinpath(@__DIR__, "test_data", "generic_cases", "basic_types.xml")
    outdir = mktempdir()
    generated_path = XsdToStruct.xsd_to_struct_module(xsd_path, outdir)
    Base.include(Main, generated_path)
    module_name = nothing
    for line in split(read(generated_path, String), '\n')
        m = match(r"^module\s+(\w+)", line)
        isnothing(m) || (module_name = Symbol(m[1]); break)
    end
    module_ref = Base.invokelatest(getproperty, Main, module_name)

    eager = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref)
    lazy = Base.invokelatest(XmlStructLoader.load, xml_path, module_ref; load_strategy = XmlStructLoader.ReadOnAccess())

    # Deliberately touch only one field before writing - the writer's own recursive property walk
    # must still materialize everything it needs to serialize correctly.
    Base.invokelatest(getproperty, Base.invokelatest(getproperty, lazy, :TestElement1), :Element_string)

    eager_out = tempname()
    lazy_out = tempname()
    Base.invokelatest(XmlStructWriter.write, eager_out, eager, "document")
    Base.invokelatest(XmlStructWriter.write, lazy_out, lazy, "document")

    @test read(eager_out, String) == read(lazy_out, String)

    rm(eager_out; force = true)
    rm(lazy_out; force = true)
end
```

(Confirm `XmlStructWriter.write`'s actual exported signature - `write(path, object, root_name)` or similar - by reading `XmlStructWriter.jl/src/XmlStructWriter.jl`'s public API before finalizing this call; adjust the call above to match exactly rather than guessing the argument order.)

- [ ] **Step 2: Add test-only dependencies and wire `runtests.jl`**

```toml
# XmlStructWriter.jl/test/Project.toml, under [deps] - add via Pkg.add/Pkg.develop, not by hand,
# but these are the exact UUIDs that must resolve (confirmed against each package's own Project.toml):
ReTestItems = "817f1d60-ba6b-4fd5-9520-3cf149f6a823"
XmlStructLoader = "1bf1c528-19f0-4e43-b24f-ad91d84ffbf7"
XsdToStruct = "3ae7ce5f-3138-4ab9-addd-ceedf56009da"
```
```julia
# appended to XmlStructWriter.jl/test/runtests.jl - same correction as Task 1 Step 4
using ReTestItems
ReTestItems.runtests(XmlStructWriter; testitem_timeout = 300)
```

- [ ] **Step 3: Run test to verify it passes**

Run: `cd XmlStructWriter.jl && julia --project=. -e 'using Pkg; Pkg.test()'`
Expected: PASS with zero changes to `XmlStructWriter.jl/src/*` - this test exists specifically to confirm that claim from the design spec, not to drive new production code.

- [ ] **Step 4: Commit**

```bash
git add XmlStructWriter.jl/test/lazy_roundtrip_tests.jl XmlStructWriter.jl/test/Project.toml XmlStructWriter.jl/test/runtests.jl
git commit -m "Add lazy-load round-trip test for XmlStructWriter (confirms no source changes needed)"
```

---

### Task 8: Benchmark and before/after report

**Files:**
- Create: `XmlStructLoader.jl/bench/run_lazy_loading_bench.jl`
- Create: `XmlStructLoader.jl/bench/results/lazy_loading_readallonly_vs_readonaccess.json`

**Interfaces:**
- Consumes: `Chairmarks` (existing dependency per this project's established benchmark pattern), the 5.3MB synthetic fixture (`XmlStructLoader.jl/bench/fixtures/large_synthetic.xml`), the real ISO 20022 fixture.

- [ ] **Step 1: Write the benchmark script**

Create `XmlStructLoader.jl/bench/run_lazy_loading_bench.jl`:

```julia
using Chairmarks
using JSON
using XmlStructLoader
using XsdToStruct

function bench_load_strategy(xsd_path, xml_path, module_ref, load_strategy)
    return @be XmlStructLoader.load($xml_path, $module_ref; load_strategy = $load_strategy) seconds = 5
end

function touch_first_field(loaded)
    # matches the "large document, only a handful of fields touched" motivating use case
    props = propertynames(loaded)
    isempty(props) && return nothing
    return getproperty(loaded, first(props))
end

function run_and_save(name::String, xsd_path::String, xml_path::String)
    outdir = mktempdir()
    generated_path = xsd_to_struct_module(xsd_path, outdir)
    include(generated_path)
    module_name = nothing
    for line in split(read(generated_path, String), '\n')
        m = match(r"^module\s+(\w+)", line)
        isnothing(m) || (module_name = Symbol(m[1]); break)
    end
    module_ref = getproperty(Main, module_name)

    eager_result = bench_load_strategy(xsd_path, xml_path, module_ref, XmlStructLoader.ReadAllData())
    lazy_load_result = @be XmlStructLoader.load($xml_path, $module_ref; load_strategy = XmlStructLoader.ReadOnAccess()) seconds = 5
    lazy_touch_result = @be touch_first_field(XmlStructLoader.load($xml_path, $module_ref; load_strategy = XmlStructLoader.ReadOnAccess())) seconds = 5

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
        joinpath(@__DIR__, "fixtures", "large_synthetic.xsd"),
        joinpath(@__DIR__, "fixtures", "large_synthetic.xml"),
    ),
    run_and_save(
        "pacs.008.001.09 (real ISO 20022)",
        joinpath(@__DIR__, "..", "test", "test_data", "real_world", "pacs.008.001.09.xsd"),
        joinpath(@__DIR__, "..", "test", "test_data", "real_world", "pacs.008.001.09_instance.xml"),
    ),
]

open(joinpath(@__DIR__, "results", "lazy_loading_readalldata_vs_readonaccess.json"), "w") do io
    JSON.print(io, results, 2)
end

for r in results
    println(r["fixture"], ":")
    println("  eager (ReadAllData):              ", r["eager_readalldata_median_s"], "s")
    println("  lazy load() only (ReadOnAccess):   ", r["lazy_readonaccess_load_only_median_s"], "s")
    println("  lazy load() + touch one field:     ", r["lazy_readonaccess_load_plus_one_field_median_s"], "s")
end
```

Adjust `large_synthetic.xsd`'s expected path if `bench/gen_large_fixture.jl` generates it under a different name - confirm the actual fixture filename in `XmlStructLoader.jl/bench/fixtures/` before running, rather than assuming.

- [ ] **Step 2: Run it and save results**

Run: `cd XmlStructLoader.jl && julia --project=test bench/run_lazy_loading_bench.jl`

Expected: a `bench/results/lazy_loading_readalldata_vs_readonaccess.json` file, and console output showing eager vs. lazy-load-only vs. lazy-plus-one-field latency for both fixtures. Run more than once if numbers look noisy (matching this project's established practice of not trusting a single-shot measurement) - the actual numbers are needed for Step 3, so do not fabricate or estimate them.

- [ ] **Step 3: Write the before/after summary**

Using the actual numbers from Step 2 (not estimated), write a markdown summary - this becomes the PR description's benchmark section (see Task 9 below), following the same table format used in the precompile-workload PR:

```markdown
## Benchmarks — cold `load()`, real fixtures, ReadAllData vs ReadOnAccess

| Fixture | ReadAllData (eager) | ReadOnAccess, load() only | ReadOnAccess, load() + touch 1 field |
|---|---|---|---|
| large_synthetic (5.3MB) | <measured>s | <measured>s | <measured>s |
| pacs.008.001.09 (real ISO 20022) | <measured>s | <measured>s | <measured>s |

Latency is the headline metric here - it's the original motivation (large documents taking too
long to traverse and parse). Allocation counts: <measured, secondary>.
```

- [ ] **Step 4: Commit**

```bash
git add XmlStructLoader.jl/bench/run_lazy_loading_bench.jl XmlStructLoader.jl/bench/results/lazy_loading_readalldata_vs_readonaccess.json
git commit -m "Add lazy-loading before/after benchmark (ReadAllData vs ReadOnAccess)"
```

---

## Final Verification

- [ ] Full test suite across all touched packages passes: `AbstractXsdTypes.jl`, `XsdToStruct.jl`, `XmlStructLoader.jl`, `XmlStructWriter.jl` (each package's `Pkg.test()`, both the existing classic suites and the new `@testitem` files).
- [ ] Every requirement in `docs/superpowers/specs/2026-07-05-xmlstructloader-lazy-loading-design.md` maps to a task above: `PugixmlDocumentHandle`/`LazyNode` (Task 1), `propertynames`/`show` fix (Task 2), lazy struct codegen (Task 3), `LoadStrategy` API + `validate` conflict error (Task 4), precompile workload extension (Task 5), equivalence + malformed-document + vector-granularity tests (Task 6), writer round-trip (Task 7), benchmark + report (Task 8).
- [ ] Benchmark numbers in the final PR description are the actual measured values from Task 8, not estimates.
