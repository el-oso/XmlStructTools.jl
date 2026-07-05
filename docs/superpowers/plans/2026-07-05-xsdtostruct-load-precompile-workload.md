# XsdToStruct @compile_workload Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** every module `XsdToStruct.xsd_to_struct_module` generates carries its own `PrecompileTools.@compile_workload` that runs a synthesized, schema-shaped sample document through `XmlStructLoader.load`, so the expensive per-schema specialization (`type_in_module`, `get_base_field_type`, `construct_xml_node_child_objects`) is already compiled and cached by the time a real caller loads real data — persisting across every future process, since these generated modules are generally consumed by being `include()`d inside another real, separately-installed package (confirmed — not the loose-script pattern the generated docstring's example shows).

**Architecture:** A new synthesis pass in `XsdToStruct.jl` walks the same `ComplexTreeNode`/`FieldData` tree the struct-writer already walks, building a minimal type-parseable (not restriction-satisfying) sample XML string for the schema's root type. That string plus a `PrecompileTools.@compile_workload` block calling `XmlStructLoader.load(IOBuffer(SAMPLE), @__MODULE__; validate=false)` get emitted into the generated top-level module file. A silent `try/catch` around the workload call means an unanticipated schema shape can never break module generation — it only forfeits the warm-up for that one schema.

**Tech Stack:** Julia 1.12, `XsdToStruct.jl` (this plan's package), `XmlStructLoader.jl` (new test-only dependency), `PrecompileTools.jl` (test-only dependency of `XsdToStruct.jl`, needed to exercise `@compile_workload` in tests — already a *main* dependency of `XsdToStruct.jl` on this branch, for its own pre-existing `xsd_to_struct_module` workload).

**Branch:** `feature/xsdtostruct-load-precompile-workload`, rebased onto `el-oso:perf/xml-backend-bakeoff` (not `main`). This was a deliberate, confirmed pivot: `main`'s `XmlStructLoader.jl` currently has a real, unrelated, pre-existing bug (`type_in_module` misroutes plain built-in-scalar-typed fields into the wrong parser branch on modern Julia, causing a `BoundsError` in `get_base_field_type` for essentially any real `load()` call) that blocks this plan's own tests and Task 3's latency verification. That bug is already fixed on `perf/xml-backend-bakeoff` (an unrelated rewrite of `type_in_module` from that branch's own pugixml-backend work) — confirmed by running the full 5-package test suite on the rebased branch (all pass, including `XmlStructLoader.jl`'s real `load()` tests). The eventual PR for this feature will target `perf/xml-backend-bakeoff`, not `main` directly, since that branch's own PR (#80) is still open. Environment setup on this base requires `Pkg.develop`-ing `XmlStructPugixml.jl` (and `Pkg.build("XmlStructPugixml")` to compile its shim) alongside the other siblings, per this monorepo's established local-path-dev convention — do this for every environment (main + test) of every package you touch, and verify with `git diff --stat <Project.toml>` that only expected entries change (a `Pkg.develop` run from the wrong directory, or one that pulls in an unnecessary transitive dependency as a new *direct* one, has bitten this exact monorepo repeatedly — check before trusting the result).

**Design history note:** an earlier pass through this plan mistakenly ruled out `@compile_workload` (tested only against a bare `include()`'d script, where it's genuinely inert) and used a plain eager `try/catch` call instead. That was reverted once it was confirmed that generated modules are normally `include()`d from inside another real, already-installed package — in that context `@compile_workload` fires correctly and beats a plain eager call. The first attempt at measuring this used a single unrepeated sample per variant and reported a dramatic win (no workload 3.33s, eager 2.70s, `@compile_workload` 1.65s); that specific 1.65s number was noise and did not reproduce under repetition — the properly-repeated numbers are no workload ~3.3s, eager call ~3.3-3.4s (no improvement), `@compile_workload` ~2.7-2.8s (a real but modest ~17-20% win). The *decision* (use `@compile_workload`) still holds — a plain eager call gets no benefit even embedded in a real precompiling package — but the *magnitude* is smaller than first reported; see the spec's "Mechanism" section for the full corrected investigation. If Task 2 was already in progress under the eager-call design when this plan version is read, discard that work and start Task 2 fresh from this version.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-07-05-xsdtostruct-load-precompile-workload-design.md` — every requirement below traces back to it.
- `validate=false` in the workload's `load()` call — dummy values only need to be type-parseable, never restriction-compliant (no min/max/digits/pattern/enumeration logic needed).
- Every generated module gains `import PrecompileTools` and `import XmlStructLoader` unconditionally — no opt-out flag.
- The workload's `load()` call is wrapped in a silent `try/catch` — synthesis failures must never break a generated module.
- `GroupFieldData` fields and any tree-node kind other than `ComplexTreeNode`/`SimpleTreeNode` are skipped (omitted) in synthesis — out of scope for v1, safe because of the try/catch above.
- Element attributes (`__xml_attributes`) are not synthesized — out of scope, no per-schema benefit (see spec).
- `XsdToStruct.jl`'s own `Project.toml` gains **no new runtime dependency from this plan** — it only emits text referencing `PrecompileTools`/`XmlStructLoader`, it doesn't `using` them itself. (`PrecompileTools` is already a main dependency there independent of this plan, for `XsdToStruct.jl`'s own pre-existing workload — nothing to add.)
- `@compile_workload`'s body does not run under a plain `include()` — a test that only `include()`s the generated file cannot verify the workload actually fires; that requires a real installed-package harness (own `Project.toml`/UUID, triggered via `using`).

---

### Task 1: Sample-XML synthesis core

**Files:**
- Create: `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_precompile.jl`
- Modify: `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder.jl:1-6` (add the new `include`)
- Modify: `XsdToStruct.jl/test/Project.toml` (add `XmlStructLoader` as a test-only dep)
- Test: `XsdToStruct.jl/test/test_sample_xml_synthesis.jl` (new)
- Modify: `XsdToStruct.jl/test/XsdToStructTests.jl` (add `include("test_sample_xml_synthesis.jl")`)

**Interfaces:**
- Consumes: `XSDStructModuleBuilderType` (`xsd_module_builder_common.jl`), `qualified_type(::Union{FieldData,ChoiceFieldData})` (`xsd_field_data_types.jl`), `qualified_name(::AbstractTreeNode)` (`xsd_tree_node_types.jl`), `get_all_fields(::ComplexTreeNode)` (`xsd_tree_node_types.jl`). All already in-scope inside the `XsdToStruct` module — this file needs no `using`/`import` of its own, matching every other file under `xsd_module_builder/`.
- Produces: `synthesize_sample_xml(xsd_module_builder::XSDStructModuleBuilderType)::Union{Nothing,String}` — the only symbol Task 2 needs. Returns `nothing` if even the root type can't be resolved (defensive; in practice this should not happen since the root type is always a defined node by the time this runs).

This task requires `xsd_module_builder.defined_nodes` to already be fully populated (every `ComplexTreeNode`/`SimpleTreeNode`/union node pushed to it during struct-writing) — the test below builds this by calling the real `write_module` pipeline up through struct-writing, not by hand-constructing a `XSDStructModuleBuilderType`.

- [ ] **Step 1: Add `XmlStructLoader` as a test-only dependency**

Run from the `XsdToStruct.jl` directory (not the repo root — a stray dependency add from the wrong directory has bitten this exact monorepo before):

```bash
cd XsdToStruct.jl/test
julia --project=. -e 'using Pkg; Pkg.develop(path="../../XmlStructLoader.jl")'
```

Verify only `test/Project.toml` and `test/Manifest.toml` changed:

```bash
cd ../..
git status --short XsdToStruct.jl/
```

Expected: only files under `XsdToStruct.jl/test/` show as modified/untracked (`Project.toml`, `Manifest.toml`). If `XsdToStruct.jl/Project.toml` (the main one, not `test/Project.toml`) shows as modified, the command ran in the wrong directory — revert with `git checkout -- XsdToStruct.jl/Project.toml` and redo Step 1 from `XsdToStruct.jl/test/`.

`XmlStructLoader.jl` on this branch itself depends on `XmlStructPugixml.jl` (a C++ shim binding).
`Pkg.instantiate()` (run automatically by the next step's `Pkg.test()`) resolves it transitively via
`XmlStructLoader.jl`'s own manifest without needing its own explicit entry in
`XsdToStruct.jl/test/Project.toml` — confirmed, don't add one. It does need its shim compiled once
per fresh environment: `julia --project=XsdToStruct.jl/test -e 'using Pkg; Pkg.build("XmlStructPugixml")'`.

- [ ] **Step 2: Write the failing test**

Create `XsdToStruct.jl/test/test_sample_xml_synthesis.jl`. This task tests synthesis output shape
only — the end-to-end "does a real `XmlStructLoader.load()` still work after this" assertion
belongs to Task 2's test, since it needs the full generated module (with its `__meta` submodule)
that only exists once `write_top_module_to_io` is wired up:

```julia
@testset "sample xml synthesis" begin
    @testset "basic_types — produces XML with all top-level element tags" begin
        xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "basic_types.xsd")
        xsd_tree = XsdToStruct.read_xsd(xsd_path)
        XsdToStruct.process_xsd_tree!(xsd_tree)

        outdir = mktempdir()
        sample_xml = open(joinpath(outdir, "top.jl"), "w") do io_top
            open(joinpath(outdir, "struct.jl"), "w") do io_struct
                xsd_module_builder = XsdToStruct.XSDStructModuleBuilderType(
                    indent_string = "    ",
                    xsd_tree = xsd_tree,
                    io_top = io_top,
                    io_struct = io_struct,
                    xsd_filename = "basic_types.xsd",
                )
                XsdToStruct.write_struct_module_to_io(xsd_module_builder)
                return XsdToStruct.synthesize_sample_xml(xsd_module_builder)
            end
        end

        @test !isnothing(sample_xml)
        # root element uses the schema's own root field name
        @test occursin("<document>", sample_xml)
        # nested complex fields recursed into
        @test occursin("<TestElement1>", sample_xml)
        @test occursin("<TestElement3>", sample_xml)
        # scalar leaves got dummy values
        @test occursin("<Element_string>x</Element_string>", sample_xml)
        @test occursin("<Element_boolean>false</Element_boolean>", sample_xml)
        @test occursin("<Element_dateTime>2000-01-01T00:00:00</Element_dateTime>", sample_xml)
        # TestElement2 is TestSimpleType1 (restriction base="string", pattern="([0-9A-Z]{4})?") —
        # resolved one level to its base scalar shape ("String") and got a dummy value ("x") that
        # doesn't match the pattern at all. Only possible because the workload calls load() with
        # validate=false, which skips AbstractXsdTypes.check_restrictions entirely.
        @test occursin("<TestElement2>x</TestElement2>", sample_xml)
    end

    @testset "choice_element — only the first choice option is emitted" begin
        xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "choice_element.xsd")
        xsd_tree = XsdToStruct.read_xsd(xsd_path)
        XsdToStruct.process_xsd_tree!(xsd_tree)

        outdir = mktempdir()
        sample_xml = open(joinpath(outdir, "top.jl"), "w") do io_top
            open(joinpath(outdir, "struct.jl"), "w") do io_struct
                xsd_module_builder = XsdToStruct.XSDStructModuleBuilderType(
                    indent_string = "    ",
                    xsd_tree = xsd_tree,
                    io_top = io_top,
                    io_struct = io_struct,
                    xsd_filename = "choice_element.xsd",
                )
                XsdToStruct.write_struct_module_to_io(xsd_module_builder)
                return XsdToStruct.synthesize_sample_xml(xsd_module_builder)
            end
        end

        @test !isnothing(sample_xml)
        @test occursin("<choice1>x</choice1>", sample_xml)
        @test !occursin("<choice2>", sample_xml)
    end

    @testset "optional_elements — can_be_missing fields are omitted" begin
        xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "optional_elements.xsd")
        xsd_tree = XsdToStruct.read_xsd(xsd_path)
        XsdToStruct.process_xsd_tree!(xsd_tree)

        outdir = mktempdir()
        sample_xml = open(joinpath(outdir, "top.jl"), "w") do io_top
            open(joinpath(outdir, "struct.jl"), "w") do io_struct
                xsd_module_builder = XsdToStruct.XSDStructModuleBuilderType(
                    indent_string = "    ",
                    xsd_tree = xsd_tree,
                    io_top = io_top,
                    io_struct = io_struct,
                    xsd_filename = "optional_elements.xsd",
                )
                XsdToStruct.write_struct_module_to_io(xsd_module_builder)
                return XsdToStruct.synthesize_sample_xml(xsd_module_builder)
            end
        end

        @test !isnothing(sample_xml)
        # TestComplexType1 (referenced by documentType's required TestElement1) mixes optional and
        # required fields: Element_string and Element_simple1 both have minOccurs="0"
        # (can_be_missing=true) and must be omitted; Element_double has no minOccurs at all
        # (can_be_missing=false, required) and must still appear with a dummy value.
        #
        # Scope these checks to TestElement1's own block, not the whole document: TestComplexType2
        # (TestElement2) also has a field literally named "Element_string" (default="aaa", no
        # minOccurs - so can_be_missing=false, required, correctly emitted) - a whole-document
        # occursin check would see that unrelated occurrence and give a false failure.
        te1_start = first(findfirst("<TestElement1>", sample_xml))
        te1_end = last(findfirst("</TestElement1>", sample_xml))
        te1_block = sample_xml[te1_start:te1_end]
        @test !occursin("<Element_string>", te1_block)
        @test !occursin("<Element_simple1>", te1_block)
        @test occursin("<Element_double>0</Element_double>", te1_block)
        # TestElement1 itself is a required field of documentType — still present
        @test occursin("<TestElement1>", sample_xml)
    end
end
```

Add the include to `XsdToStruct.jl/test/XsdToStructTests.jl` (append near the other `include(...)` calls, matching the existing style, e.g. right after the `test_real_world_schemas.jl` include if present on this branch, otherwise after the last existing include):

```julia
include("test_sample_xml_synthesis.jl")
```

- [ ] **Step 3: Run test to verify it fails**

```bash
cd XsdToStruct.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: FAIL with `UndefVarError: synthesize_sample_xml not defined` (or similar — the function doesn't exist yet).

- [ ] **Step 4: Write the synthesis implementation**

Create `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_precompile.jl`:

```julia
const SAMPLE_SCALAR_VALUES = Dict(
    "String" => "x",
    "Float64" => "0",
    "Bool" => "false",
    "Int64" => "0",
    "UInt64" => "0",
    "Union{ZonedDateTime, DateTime}" => "2000-01-01T00:00:00",
)

function find_defined_node(
    qualified_type_name::AbstractString,
    xsd_module_builder::XSDStructModuleBuilderType,
)::Union{Nothing,AbstractTreeNode}
    idx = findfirst(==(qualified_type_name) ∘ qualified_name, xsd_module_builder.defined_nodes)
    return isnothing(idx) ? nothing : xsd_module_builder.defined_nodes[idx]
end

"""
    sample_xml_for_type(qualified_type_name, julia_type, xsd_module_builder)::Union{Nothing,String}

Returns the inner XML text/content for a value of the given type — a scalar literal for a
built-in Julia type, or the recursively-built child-element XML for a defined complex/simple
type. Returns `nothing` if the type can't be resolved (unhandled tree-node kind, e.g. a union or
extension) — callers must treat `nothing` as "omit this field", never as an error.
"""
function sample_xml_for_type(
    qualified_type_name::AbstractString,
    julia_type::AbstractString,
    xsd_module_builder::XSDStructModuleBuilderType,
)::Union{Nothing,String}
    haskey(SAMPLE_SCALAR_VALUES, julia_type) && return SAMPLE_SCALAR_VALUES[julia_type]

    node = find_defined_node(qualified_type_name, xsd_module_builder)
    isnothing(node) && return nothing

    if node isa ComplexTreeNode
        return sample_xml_for_complex(node, xsd_module_builder)
    elseif node isa SimpleTreeNode
        # a restricted simple type wraps a base scalar type; recurse one level using that base
        # type's own julia_type as both the qualified name and the julia type to look up — this
        # naturally handles arbitrarily-stacked simple types (a simple type restricting another
        # simple type) since it just recurses again.
        return sample_xml_for_type(node.field.julia_type, node.field.julia_type, xsd_module_builder)
    else
        # UnionTreeNode, ExtensionTreeNode, or any future node kind — not handled in v1, treat as
        # unresolvable so the caller omits the field. Safe: the generated module's eager warm-up
        # call wraps the actual load() call in a try/catch, so an incomplete sample instance only
        # forfeits the warm-up for this one schema, never breaks it.
        return nothing
    end
end

function sample_xml_for_complex(node::ComplexTreeNode, xsd_module_builder::XSDStructModuleBuilderType)::String
    parts = String[]
    for field in get_all_fields(node)
        field_xml = sample_xml_for_field(field, xsd_module_builder)
        isnothing(field_xml) || push!(parts, field_xml)
    end
    return join(parts)
end

sample_xml_for_field(::GroupFieldData, ::XSDStructModuleBuilderType)::Nothing = nothing

function sample_xml_for_field(field::FieldData, xsd_module_builder::XSDStructModuleBuilderType)::Union{Nothing,String}
    field.can_be_missing && return nothing
    inner = sample_xml_for_type(qualified_type(field), field.julia_type, xsd_module_builder)
    isnothing(inner) && return nothing
    return "<$(field.name)>$inner</$(field.name)>"
end

function sample_xml_for_field(
    field::ChoiceFieldData,
    xsd_module_builder::XSDStructModuleBuilderType,
)::Union{Nothing,String}
    field.can_be_missing && return nothing
    isempty(field.choice_options) && return nothing
    return sample_xml_for_field(first(field.choice_options), xsd_module_builder)
end

"""
    synthesize_sample_xml(xsd_module_builder::XSDStructModuleBuilderType)::Union{Nothing,String}

Builds a minimal, type-parseable (not restriction-satisfying) XML instance for the schema's root
type, for use in the generated module's own eager `load()` warm-up call. Must be called after
`write_struct_module_to_io` has populated `xsd_module_builder.defined_nodes` — the type lookups
here depend on every complex/simple/union type in the schema already being registered there.

Returns `nothing` only if the root type itself can't be resolved (shouldn't happen in practice —
the root type is always a defined node by the time struct-writing completes).
"""
function synthesize_sample_xml(xsd_module_builder::XSDStructModuleBuilderType)::Union{Nothing,String}
    root_field = xsd_module_builder.xsd_tree.root_field
    inner = sample_xml_for_type(qualified_type(root_field), root_field.julia_type, xsd_module_builder)
    isnothing(inner) && return nothing
    return "<$(root_field.name)>$inner</$(root_field.name)>"
end
```

- [ ] **Step 5: Wire the new file into the module**

Modify `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder.jl`, changing:

```julia
include("xsd_module_builder_common.jl")
include("xsd_module_builder_top.jl")
include("xsd_module_builder_struct.jl")
include("xsd_module_builder_checks.jl")
```

to:

```julia
include("xsd_module_builder_common.jl")
include("xsd_module_builder_top.jl")
include("xsd_module_builder_struct.jl")
include("xsd_module_builder_checks.jl")
include("xsd_module_builder_precompile.jl")
```

- [ ] **Step 6: Run test to verify it passes**

```bash
cd XsdToStruct.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: PASS, all three new `@testset` blocks green.

- [ ] **Step 7: Commit**

```bash
git add XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_precompile.jl \
        XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder.jl \
        XsdToStruct.jl/test/test_sample_xml_synthesis.jl \
        XsdToStruct.jl/test/XsdToStructTests.jl \
        XsdToStruct.jl/test/Project.toml \
        XsdToStruct.jl/test/Manifest.toml
git commit -m "Add sample-XML synthesis for per-schema load() warm-up calls"
```

---

### Task 2: Wire the synthesized sample + `@compile_workload` into generated modules

**Files:**
- Modify: `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder.jl` (`write_module` — reorder the two writer calls)
- Modify: `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_top.jl` (`write_top_module_to_io`, `write_docstring_part`; add `write_precompile_workload_part`)
- Modify: `XsdToStruct.jl/test/Project.toml` (add `PrecompileTools` as a test-only dep)
- Test: `XsdToStruct.jl/test/test_generated_module_precompile_workload.jl` (new)
- Modify: `XsdToStruct.jl/test/XsdToStructTests.jl` (add the include)

`XmlStructLoader` was already added as a test-only dep in Task 1.

**Interfaces:**
- Consumes: `synthesize_sample_xml(xsd_module_builder)` from Task 1.
- Produces: every file `xsd_to_struct_module` generates now contains `import PrecompileTools`, `import XmlStructLoader`, a `const` sample-XML string, and a `@compile_workload` block — this is the deliverable a real caller sees, nothing further consumes it internally.

**Scope note:** `@compile_workload`'s body only runs during real package precompilation
(`jl_generating_output == 1`), never under a plain `include()` (confirmed empirically — see spec).
This task's own test therefore only checks (a) the generated source text is correct, and (b) a
plain `include()`-based `load()` call still returns correct values (a basic regression/no-syntax-
breakage check — the workload body simply doesn't run in this scenario, so there's nothing to
verify about it here). Proving the workload actually fires and delivers the latency win requires a
real installed-package harness, which is Task 3's job (it already needs one for its A/B
measurement) — don't duplicate that harness here.

- [ ] **Step 1: Add `PrecompileTools` as a test-only dependency**

```bash
cd XsdToStruct.jl/test
julia --project=. -e 'using Pkg; Pkg.add("PrecompileTools")'
cd ../..
git status --short XsdToStruct.jl/
```

Expected: only `XsdToStruct.jl/test/Project.toml` and `test/Manifest.toml` change.

- [ ] **Step 2: Write the failing test**

Create `XsdToStruct.jl/test/test_generated_module_precompile_workload.jl`:

```julia
@testset "generated module @compile_workload" begin
    @testset "basic_types — generated file contains the workload, and a real load() still works after it" begin
        xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "basic_types.xsd")
        outdir = mktempdir()
        generated_path = xsd_to_struct_module(xsd_path, outdir)

        generated_source = read(generated_path, String)
        @test occursin("import PrecompileTools", generated_source)
        @test occursin("import XmlStructLoader", generated_source)
        @test occursin("PrecompileTools.@compile_workload", generated_source)
        @test occursin("validate = false", generated_source)
        @test occursin("try", generated_source)
        @test occursin("catch", generated_source)

        # @compile_workload's body only runs during real package precompilation, never under a
        # plain include() — so this include() only exercises the surrounding code (struct
        # definitions, the sample string, the file being syntactically valid), not the workload
        # body itself. A real load() call afterward must still return correct values.
        Base.include(Main, generated_path)
        generated_module = Base.invokelatest(getproperty, Main, :basic_types)

        real_xml = joinpath(
            @__DIR__, "..", "..", "XmlStructLoader.jl", "test", "test_data", "generic_cases", "basic_types.xml",
        )
        loaded = Base.invokelatest(XmlStructLoader.load, real_xml, generated_module)

        test_element_1 = Base.invokelatest(getproperty, loaded, :TestElement1)
        @test Base.invokelatest(getproperty, test_element_1, :Element_string) == "aaaa"
        @test Base.invokelatest(getproperty, test_element_1, :Element_double) == 100.22
        @test Base.invokelatest(getproperty, test_element_1, :Element_boolean) == true
    end

    @testset "choice_element — generated file still generates cleanly for a choice-bearing schema" begin
        xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "choice_element.xsd")
        outdir = mktempdir()
        generated_path = xsd_to_struct_module(xsd_path, outdir)
        @test occursin("PrecompileTools.@compile_workload", read(generated_path, String))
    end
end
```

Add the include to `XsdToStruct.jl/test/XsdToStructTests.jl`:

```julia
include("test_generated_module_precompile_workload.jl")
```

- [ ] **Step 3: Run test to verify it fails**

```bash
cd XsdToStruct.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: FAIL — `occursin("PrecompileTools.@compile_workload", generated_source)` is `false` (nothing emits it yet).

- [ ] **Step 4: Reorder `write_module` so struct-writing populates `defined_nodes` before the top-module writer needs it**

In `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder.jl`, change:

```julia
            write_top_module_to_io(xsd_module_builder)
            return write_struct_module_to_io(xsd_module_builder)
```

to:

```julia
            write_struct_module_to_io(xsd_module_builder)
            return write_top_module_to_io(xsd_module_builder)
```

(Safe: nothing in `write_top_module_to_io` depends on write-order — `write_docstring_part` only reads `xsd_tree`/`module_name`, `write_struct_module_part` only emits an `include(...)` line referencing the struct file by name, `write_meta_module_part` only reads `xsd_tree.root_field.julia_type`. The two functions write to separate, already-open file handles, so swapping call order doesn't affect either file's own content — it only makes `defined_nodes` available in time for the new precompile part.)

- [ ] **Step 5: Add `write_precompile_workload_part` and wire it in**

In `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_top.jl`, add a new function (place it after `write_struct_module_part`, before `write_meta_module_part`):

```julia
function write_precompile_workload_part(xsd_module_builder::XSDStructModuleBuilderType)::Nothing
    sample_xml = synthesize_sample_xml(xsd_module_builder)
    isnothing(sample_xml) && return nothing

    writeln(xsd_module_builder, IOTop, "import PrecompileTools")
    writeln(xsd_module_builder, IOTop, "import XmlStructLoader")

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "const __XSDTOSTRUCT_SAMPLE_XML__ = \"\"\"$sample_xml\"\"\"")

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "PrecompileTools.@compile_workload begin")
    writeln(xsd_module_builder, IOTop, "try", indent_level = 1)
    writeln(
        xsd_module_builder,
        IOTop,
        "XmlStructLoader.load(IOBuffer(__XSDTOSTRUCT_SAMPLE_XML__), @__MODULE__; validate = false)",
        indent_level = 2,
    )
    writeln(xsd_module_builder, IOTop, "catch", indent_level = 1)
    writeln(xsd_module_builder, IOTop, "end", indent_level = 1)
    writeln(xsd_module_builder, IOTop, "end")

    return nothing
end
```

Then wire it into `write_top_module_to_io` — change:

```julia
function write_top_module_to_io(xsd_module_builder::XSDStructModuleBuilderType)::Nothing
    write_docstring_part(xsd_module_builder)

    writeln(xsd_module_builder, IOTop, "module $(xsd_module_builder.module_name)")

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "using Reexport")

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "@reexport using $ABSTRACT_TYPE_PACKAGE")

    write(xsd_module_builder, IOTop, "\n")

    write_struct_module_part(xsd_module_builder)

    write(xsd_module_builder, IOTop, "\n")

    write_meta_module_part(xsd_module_builder)

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "end")

    return nothing
end
```

to:

```julia
function write_top_module_to_io(xsd_module_builder::XSDStructModuleBuilderType)::Nothing
    write_docstring_part(xsd_module_builder)

    writeln(xsd_module_builder, IOTop, "module $(xsd_module_builder.module_name)")

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "using Reexport")

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "@reexport using $ABSTRACT_TYPE_PACKAGE")

    write(xsd_module_builder, IOTop, "\n")

    write_struct_module_part(xsd_module_builder)

    write(xsd_module_builder, IOTop, "\n")

    write_precompile_workload_part(xsd_module_builder)

    write(xsd_module_builder, IOTop, "\n")

    write_meta_module_part(xsd_module_builder)

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "end")

    return nothing
end
```

- [ ] **Step 6: Update the generated docstring's dependency list**

In `write_docstring_part` (same file), change:

```julia
    writeln(xsd_module_builder, IOTop, "In order to use this module the following dependencies need to be installed:")
    writeln(xsd_module_builder, IOTop, "AbstractXsdTypes", indent_level = 1)
    writeln(xsd_module_builder, IOTop, "Reexport", indent_level = 1)
    if xsd_module_builder.xsd_tree.requires_TimeZones
        writeln(xsd_module_builder, IOTop, "Dates", indent_level = 1)
        writeln(xsd_module_builder, IOTop, "TimeZones", indent_level = 1)
    end
    writeln(xsd_module_builder, IOTop)
```

to:

```julia
    writeln(xsd_module_builder, IOTop, "In order to use this module the following dependencies need to be installed:")
    writeln(xsd_module_builder, IOTop, "AbstractXsdTypes", indent_level = 1)
    writeln(xsd_module_builder, IOTop, "Reexport", indent_level = 1)
    writeln(xsd_module_builder, IOTop, "PrecompileTools", indent_level = 1)
    writeln(xsd_module_builder, IOTop, "XmlStructLoader", indent_level = 1)
    if xsd_module_builder.xsd_tree.requires_TimeZones
        writeln(xsd_module_builder, IOTop, "Dates", indent_level = 1)
        writeln(xsd_module_builder, IOTop, "TimeZones", indent_level = 1)
    end
    writeln(xsd_module_builder, IOTop)
```

- [ ] **Step 7: Run test to verify it passes**

```bash
cd XsdToStruct.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: PASS, including the real `load()` assertions against `basic_types.xml`.

- [ ] **Step 8: Commit**

```bash
git add XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder.jl \
        XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_top.jl \
        XsdToStruct.jl/test/test_generated_module_precompile_workload.jl \
        XsdToStruct.jl/test/XsdToStructTests.jl \
        XsdToStruct.jl/test/Project.toml \
        XsdToStruct.jl/test/Manifest.toml
git commit -m "Emit a PrecompileTools.@compile_workload in every generated module"
```

---

### Task 3: Full-suite gate + real-precompilation latency verification

**Files:** none (verification only).

- [ ] **Step 1: Run the full XsdToStruct.jl test suite one more time as a clean gate**

```bash
cd XsdToStruct.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: PASS, zero failures/errors.

- [ ] **Step 2: Run the other 4 packages' test suites to confirm nothing downstream broke**

```bash
cd ../AbstractXsdTypes.jl && julia --project=. -e 'using Pkg; Pkg.test()'
cd ../XmlStructPugixml.jl && julia --project=. -e 'using Pkg; Pkg.test()'
cd ../XmlStructLoader.jl && julia --project=. -e 'using Pkg; Pkg.test()'
cd ../XmlStructWriter.jl && julia --project=. -e 'using Pkg; Pkg.test()'
cd ..
```

Expected: all PASS (1688 / 18 / 88 / 18 tests respectively, matching the numbers confirmed when
this branch was rebased onto `perf/xml-backend-bakeoff` — see the header's "Branch" note for why
that base was chosen: it already carries the fix for a real `XmlStructLoader.jl` bug that blocks
real `load()` calls on plain `main`).

- [ ] **Step 3: Measure the actual latency win via a real installed-package harness**

`@compile_workload`'s body only runs during real package precompilation
(`jl_generating_output == 1`) — it does **not** run under a bare `include()`, confirmed during
design. So this measurement needs the generated module embedded inside a small, real, separately
installed package (its own `Project.toml`/UUID), the same way it's actually consumed. Build this
fresh each time rather than reusing anything from Task 2's test — Task 2's test deliberately does
NOT exercise real precompilation (see its Scope note).

Generate the module and build the harness package:

```bash
cd XsdToStruct.jl
DIR=$(mktemp -d)
julia --project=. -e "
using XsdToStruct
xsd_to_struct_module(\"test/test_data/generic_data/basic_types.xsd\", \"\$DIR\")
"

HARNESS=$(mktemp -d)
mkdir -p "$HARNESS/HarnessPkg/src"
HARNESS_UUID=$(julia -e 'using UUIDs; print(uuid4())')
cat > "$HARNESS/HarnessPkg/Project.toml" <<EOF
name = "HarnessPkg"
uuid = "$HARNESS_UUID"
version = "0.1.0"

[deps]
AbstractXsdTypes = "894546dd-dc3f-42e8-9b69-a7785ccf72be"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
PrecompileTools = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
Reexport = "189a3867-3050-52da-a836-e630ba90ab69"
TimeZones = "f269a46b-ccf7-5d73-abea-4c690281aa53"
XmlStructLoader = "1bf1c528-19f0-4e43-b24f-ad91d84ffbf7"
EOF
cp "$DIR/basic_types/basic_types.jl" "$HARNESS/HarnessPkg/src/"
cp "$DIR/basic_types/basic_types_struct.jl" "$HARNESS/HarnessPkg/src/"
cat > "$HARNESS/HarnessPkg/src/HarnessPkg.jl" <<'EOF'
module HarnessPkg
include("basic_types.jl")
import .TestComplexAndSimple
end
EOF
```

`basic_types.xsd`'s generated module is named `TestComplexAndSimple` (from the schema's
`targetNamespace`), not `basic_types` — the filename and the module name inside it are different
things. Reference it as `HarnessPkg.TestComplexAndSimple` below, not `HarnessPkg.basic_types`.

```bash
ENV_DIR=$(mktemp -d)
julia --project="$ENV_DIR" -e "using Pkg; Pkg.develop(path=raw\"$HARNESS/HarnessPkg\"); Pkg.develop(path=raw\"$(pwd)/../XmlStructLoader.jl\"); Pkg.instantiate()"
julia --project="$ENV_DIR" -e 'using Pkg; Pkg.build("XmlStructPugixml")'
```

(Careful with the second `Pkg.develop` line's quoting: the whole path must be inside one `raw"..."`
string — `raw\"$(pwd)/../XmlStructLoader.jl\"`, not split across two strings — otherwise Julia
parses it as a string followed by an undefined identifier.)

(The explicit `Pkg.develop` of the sibling `XmlStructLoader.jl` ensures the harness environment uses
this monorepo's local copy, not a registered version — this monorepo's established convention for
avoiding version-skew bugs between sibling packages. `XmlStructLoader.jl` on this branch itself
depends on `XmlStructPugixml.jl`; `Pkg.instantiate()` resolves it transitively via
`XmlStructLoader.jl`'s own manifest without needing an explicit entry in `HarnessPkg/Project.toml`
— confirmed during setup: adding it explicitly there is unnecessary and was reverted after checking.
The `Pkg.build("XmlStructPugixml")` step compiles its C++ shim — needed once per fresh environment.)

Trigger real precompilation in a subprocess (this is where `@compile_workload`'s body actually
executes), then in a **separate fresh** subprocess measure the cold `load()` call against the real
`basic_types.xml` fixture:

```bash
julia --project="$ENV_DIR" -e "using HarnessPkg"

CHECK=$(mktemp --suffix=.jl)
cat > "$CHECK" <<EOF
using HarnessPkg, XmlStructLoader
xml = raw"$(pwd)/../XmlStructLoader.jl/test/test_data/generic_cases/basic_types.xml"
t = @elapsed loaded = XmlStructLoader.load(xml, HarnessPkg.TestComplexAndSimple)
println("cold load() with @compile_workload-precompiled package: ", t, " s")
println("check: ", loaded.TestElement1.Element_string)
EOF
julia --project="$ENV_DIR" --startup-file=no "$CHECK"
```

Run this **3 times** (fresh subprocess each time — the measurement command above already is one),
not once — a single sample is not sufficient to trust a latency number, even for a quick
verification-only check. (This exact mistake was made during design: an earlier single-shot
measurement reported a ~50% win that turned out to be noise and didn't reproduce under repetition.)

Then stash this branch's changes, regenerate the module (now without the workload), rebuild a fresh
harness the same way (new tempdirs — don't reuse the old `HARNESS`/`ENV_DIR`, since the old one is
already precompiled with the workload baked in), and repeat the same steps 3 times to get the
baseline numbers, then `git stash pop`.

Expected: this branch's numbers should be modestly but consistently lower than the baseline's —
around a 17-20% reduction, not a dramatic one (baseline ~3.3s, with the workload ~2.7-2.8s, measured
with proper repetition — see the spec's "Mechanism" section for the full, corrected three-way
comparison and why the original single-shot ~50%/1.65s number didn't hold up). Report all six
numbers (3 per side); if this branch's numbers are *not* meaningfully faster than baseline at all,
that's a signal the workload isn't actually firing during precompilation (check the
`julia --project="$ENV_DIR" -e "using HarnessPkg"` step's output — it should take roughly double a
normal package precompile if the workload ran, e.g. ~1.3s vs ~0.7s) — worth investigating before
considering this plan done. A ~17-20% win, not a ~50% one, is the expected, passing outcome here.

- [ ] **Step 4: No commit needed** — this task is verification-only; Tasks 1 and 2 already committed everything.

---

## Self-Review Notes

- **Spec coverage:** `validate=false` (Task 1 Step 4, Task 2 Step 5) ✓; unconditional new `PrecompileTools`/`XmlStructLoader` deps in generated modules (Task 2 Steps 5-6) ✓; silent try/catch (Task 2 Step 5) ✓; `GroupFieldData`/unhandled-node-kind skip (Task 1 Step 4) ✓; no new runtime dep on `XsdToStruct.jl`'s own `Project.toml` from this plan (only `test/Project.toml` touched, in Tasks 1 and 2) ✓; real-precompilation latency verification against the spec's measured three-way comparison (Task 3 Step 3) ✓.
- **Base branch:** rebased onto `perf/xml-backend-bakeoff` and re-verified end-to-end — all 5 packages' test suites pass on the new base (1688/18/120/88/18), confirmed via direct test runs, not assumed from the rebase alone.
- **Type consistency:** `synthesize_sample_xml(xsd_module_builder::XSDStructModuleBuilderType)::Union{Nothing,String}` is defined in Task 1 Step 4 and consumed with that exact name/signature in Task 2 Step 5 — matches.
- **Scope:** single cohesive feature, one package (`XsdToStruct.jl`), two implementation tasks plus a verification-only gate — not further decomposable without creating an artificial task boundary.
- **Ripple-fix scope:** `PrecompileTools` also had to become a real dependency of `XmlStructLoader.jl` (not just a text-reference emitted by `XsdToStruct.jl`) because its own `import_module`/`use_module` convenience functions `include()` generated code directly into `XmlStructLoader`'s own module scope — confirmed with the user via AskUserQuestion before touching a file outside this plan's originally declared scope.
- **Measurement correction:** the original design-time "~50% win" (3.33s→1.65s) was an unrepeated single sample and did not reproduce — properly repeated measurement (3 samples per variant, two independent module-scoping structures) shows a consistent ~17-20% win instead. The design decision (`@compile_workload` over a plain eager call) still holds — a plain eager call showed no measurable benefit at all when repeated — but report the corrected magnitude, not the original one, in the final review.
