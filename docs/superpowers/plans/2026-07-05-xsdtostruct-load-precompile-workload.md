# XsdToStruct eager load() warm-up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** every module `XsdToStruct.xsd_to_struct_module` generates runs an eager, synthesized, schema-shaped sample document through `XmlStructLoader.load` the moment it's `include()`d, so the expensive per-schema specialization (`type_in_module`, `get_base_field_type`, `construct_xml_node_child_objects`) is already compiled by the time a real caller makes its own first `load()` call in that process.

**Architecture:** A new synthesis pass in `XsdToStruct.jl` walks the same `ComplexTreeNode`/`FieldData` tree the struct-writer already walks, building a minimal type-parseable (not restriction-satisfying) sample XML string for the schema's root type. That string plus a plain top-level `try/catch` calling `XmlStructLoader.load(IOBuffer(SAMPLE), @__MODULE__; validate=false)` get emitted into the generated top-level module file — no `PrecompileTools`/`@compile_workload` involved (verified inert for plain `include()`'d files — see spec). The `try/catch` means an unanticipated schema shape can never break module generation — it only forfeits the warm-up for that one schema. This moves the compile-tax cost from "your first real `load()` call is slow" to "the `include()` of the generated module is slow" — it does not reduce total work, and does not persist across separate `julia` process restarts.

**Tech Stack:** Julia 1.12, `XsdToStruct.jl` (this plan's package), `XmlStructLoader.jl` (new test-only + generated-module dependency). No `PrecompileTools` dependency anywhere — ruled out empirically (see spec's "Mechanism" section: its body never runs outside real package precompilation of an installed package, and `xsd_to_struct_module`'s output is a loose `.jl` file, never installed).

**Branch:** `feature/xsdtostruct-load-precompile-workload` (already checked out, off `main` — this plan targets `main`'s current state, not the unmerged `perf/xml-backend-bakeoff` branch. `main` still uses `LightXML` in `XsdToStruct.jl`; that's unaffected by this plan either way.)

## Global Constraints

- Spec: `docs/superpowers/specs/2026-07-05-xsdtostruct-load-precompile-workload-design.md` — every requirement below traces back to it.
- `validate=false` in the eager call's `load()` call — dummy values only need to be type-parseable, never restriction-compliant (no min/max/digits/pattern/enumeration logic needed).
- Every generated module gains `import XmlStructLoader` unconditionally — no opt-out flag, no `PrecompileTools` dependency.
- The eager call is wrapped in a silent `try/catch` — synthesis failures must never break a generated module.
- `GroupFieldData` fields and any tree-node kind other than `ComplexTreeNode`/`SimpleTreeNode` are skipped (omitted) in synthesis — out of scope for v1, safe because of the try/catch above.
- Element attributes (`__xml_attributes`) are not synthesized — out of scope, no per-schema benefit (see spec).
- `XsdToStruct.jl`'s own `Project.toml` gains **no new runtime dependency** — it only emits text referencing `XmlStructLoader`, it doesn't `using` it itself.

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
        @test !occursin("<Element_string>", sample_xml)
        @test !occursin("<Element_simple1>", sample_xml)
        @test occursin("<Element_double>0</Element_double>", sample_xml)
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

### Task 2: Wire the synthesized sample + an eager `load()` warm-up into generated modules

**Files:**
- Modify: `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder.jl` (`write_module` — reorder the two writer calls)
- Modify: `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_top.jl` (`write_top_module_to_io`, `write_docstring_part`; add `write_precompile_workload_part`)
- Test: `XsdToStruct.jl/test/test_generated_module_precompile_workload.jl` (new)
- Modify: `XsdToStruct.jl/test/XsdToStructTests.jl` (add the include)

No new test dependency needed for this task — `XmlStructLoader` was already added as a test-only dep in Task 1, and no `PrecompileTools` dependency is needed anywhere (ruled out — see spec).

**Interfaces:**
- Consumes: `synthesize_sample_xml(xsd_module_builder)` from Task 1.
- Produces: every file `xsd_to_struct_module` generates now contains `import XmlStructLoader`, a `const` sample-XML string, and a plain top-level `try/catch` calling `load(...)` — this is the deliverable a real caller sees, nothing further consumes it internally.

- [ ] **Step 1: Write the failing test**

Create `XsdToStruct.jl/test/test_generated_module_precompile_workload.jl`:

```julia
@testset "generated module eager load() warm-up" begin
    @testset "basic_types — generated file contains the warm-up, and a real load() still works after it" begin
        xsd_path = joinpath(@__DIR__, "test_data", "generic_data", "basic_types.xsd")
        outdir = mktempdir()
        generated_path = xsd_to_struct_module(xsd_path, outdir)

        generated_source = read(generated_path, String)
        @test occursin("import XmlStructLoader", generated_source)
        @test occursin("XmlStructLoader.load(", generated_source)
        @test occursin("validate = false", generated_source)
        @test occursin("try", generated_source)
        @test occursin("catch", generated_source)

        # the generated file must still be valid, loadable Julia, and a REAL load() against real
        # data (not the synthesized dummy) must still return correct values — this is the
        # no-contamination check: running the eager warm-up call at include-time must not leave
        # any state that corrupts a subsequent real load() in the same process.
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
        @test occursin("XmlStructLoader.load(", read(generated_path, String))
    end
end
```

Add the include to `XsdToStruct.jl/test/XsdToStructTests.jl`:

```julia
include("test_generated_module_precompile_workload.jl")
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd XsdToStruct.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: FAIL — `occursin("XmlStructLoader.load(", generated_source)` is `false` (nothing emits it yet).

- [ ] **Step 3: Reorder `write_module` so struct-writing populates `defined_nodes` before the top-module writer needs it**

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

- [ ] **Step 4: Add `write_precompile_workload_part` and wire it in**

In `XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_top.jl`, add a new function (place it after `write_struct_module_part`, before `write_meta_module_part`):

```julia
function write_precompile_workload_part(xsd_module_builder::XSDStructModuleBuilderType)::Nothing
    sample_xml = synthesize_sample_xml(xsd_module_builder)
    isnothing(sample_xml) && return nothing

    writeln(xsd_module_builder, IOTop, "import XmlStructLoader")

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "const __XSDTOSTRUCT_SAMPLE_XML__ = \"\"\"$sample_xml\"\"\"")

    write(xsd_module_builder, IOTop, "\n")

    writeln(xsd_module_builder, IOTop, "try")
    writeln(
        xsd_module_builder,
        IOTop,
        "XmlStructLoader.load(IOBuffer(__XSDTOSTRUCT_SAMPLE_XML__), @__MODULE__; validate = false)",
        indent_level = 1,
    )
    writeln(xsd_module_builder, IOTop, "catch")
    writeln(xsd_module_builder, IOTop, "end")

    return nothing
end
```

Note: no `@compile_workload`/`PrecompileTools` here — the `try`/`catch` runs as plain top-level code, executed unconditionally the moment this file is `include()`d. That's the entire mechanism (see spec's "Mechanism" section for why `@compile_workload` and signature-only `precompile()` were both ruled out empirically).

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

- [ ] **Step 5: Update the generated docstring's dependency list**

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
    writeln(xsd_module_builder, IOTop, "XmlStructLoader", indent_level = 1)
    if xsd_module_builder.xsd_tree.requires_TimeZones
        writeln(xsd_module_builder, IOTop, "Dates", indent_level = 1)
        writeln(xsd_module_builder, IOTop, "TimeZones", indent_level = 1)
    end
    writeln(xsd_module_builder, IOTop)
```

- [ ] **Step 6: Run test to verify it passes**

```bash
cd XsdToStruct.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: PASS, including the real `load()` assertions against `basic_types.xml`.

- [ ] **Step 7: Commit**

```bash
git add XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder.jl \
        XsdToStruct.jl/src/xsd_module_builder/xsd_module_builder_top.jl \
        XsdToStruct.jl/test/test_generated_module_precompile_workload.jl \
        XsdToStruct.jl/test/XsdToStructTests.jl
git commit -m "Emit an eager XmlStructLoader.load warm-up call in every generated module"
```

---

### Task 3: Full-suite gate + cold-latency verification

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
cd ../XmlStructLoader.jl && julia --project=. -e 'using Pkg; Pkg.test()'
cd ../XmlStructWriter.jl && julia --project=. -e 'using Pkg; Pkg.test()'
cd ..
```

(Skip `XmlStructPugixml.jl` — it doesn't exist on `main`, only on the unmerged `perf/xml-backend-bakeoff` branch.)

Expected: all PASS. `XsdToStruct.jl`'s own test suite is the only one that exercises the new code path directly (neither `XmlStructWriter.jl` nor `XmlStructLoader.jl` call `xsd_to_struct_module`'s codegen in a way that would newly break from this change), so this step is a should-be-a-no-op regression check.

- [ ] **Step 3: Measure the actual latency shift**

The benefit doesn't show up as "less total work" — it shows up as "`include()` gets slower, but the
caller's own first real `load()` call afterward gets dramatically faster" (measured directly during
design: first call 3.24s, second call in the same process 0.0017s). So the measurement must
explicitly separate include-time from first-real-load-time, not lump them into one
`load(path, module_path::AbstractString)` call (which internally does both the `include()`
and the real construction in a single call, and so wouldn't show the shift distinctly).

Generate the module fresh, then in a **fresh** process (this branch, eager warm-up present),
time `import_module_from_xml` (which triggers the `include()`, hence the eager warm-up call)
separately from a subsequent real `load()`:

```bash
cd XsdToStruct.jl
DIR=$(mktemp -d)
julia --project=. -e "
using XsdToStruct
xsd_to_struct_module(\"test/test_data/generic_data/basic_types.xsd\", \"$DIR\")
"
julia --project=. --startup-file=no -e "
using XmlStructLoader
xml = \"../XmlStructLoader.jl/test/test_data/generic_cases/basic_types.xml\"
t_include = @elapsed module_ref = XmlStructLoader.import_module_from_xml(xml, \"$DIR/basic_types\")
println(\"time to import/include the generated module (now does the eager warm-up): \", t_include, \" s\")
t_load = @elapsed XmlStructLoader.load(xml, module_ref)
println(\"first real load() call afterward, same process: \", t_load, \" s\")
"
```

Then stash this branch's changes and repeat against `main` as the baseline:

```bash
git stash
DIR2=$(mktemp -d)
julia --project=. -e "
using XsdToStruct
xsd_to_struct_module(\"test/test_data/generic_data/basic_types.xsd\", \"$DIR2\")
"
julia --project=. --startup-file=no -e "
using XmlStructLoader
xml = \"../XmlStructLoader.jl/test/test_data/generic_cases/basic_types.xml\"
t_include = @elapsed module_ref = XmlStructLoader.import_module_from_xml(xml, \"$DIR2/basic_types\")
println(\"baseline (no warm-up) time to import/include: \", t_include, \" s\")
t_load = @elapsed XmlStructLoader.load(xml, module_ref)
println(\"baseline first real load() call: \", t_load, \" s\")
"
git stash pop
```

Expected: on this branch, `t_include` should be dramatically higher than baseline's `t_include`
(it now pays the full compile tax via the eager warm-up), and `t_load` should be dramatically lower
than baseline's `t_load` (near-instant, since the specialization is already warm) — the opposite
pattern from baseline, where `t_include` is fast (~0.5s, just defining structs) and `t_load` is slow
(~3.7s, full compile tax deferred to first real use). Report all four numbers; if this branch's
`t_load` is *not* meaningfully faster than baseline's, that's a signal the `try/catch` in Task 2
Step 4 is silently swallowing the eager call (e.g. the synthesized sample doesn't actually parse) —
worth investigating before considering this plan done.

- [ ] **Step 4: No commit needed** — this task is verification-only; Tasks 1 and 2 already committed everything.

---

## Self-Review Notes

- **Spec coverage:** `validate=false` (Task 1 Step 4, Task 2 Step 4) ✓; unconditional new `XmlStructLoader` dep in generated modules, no `PrecompileTools` anywhere (Task 2 Steps 4-5) ✓; silent try/catch (Task 2 Step 4) ✓; `GroupFieldData`/unhandled-node-kind skip (Task 1 Step 4) ✓; no new runtime dep on `XsdToStruct.jl`'s own `Project.toml` (only `test/Project.toml` touched, in Task 1 only) ✓; latency-shift verification against the spec's measured numbers (Task 3 Step 3) ✓.
- **Type consistency:** `synthesize_sample_xml(xsd_module_builder::XSDStructModuleBuilderType)::Union{Nothing,String}` is defined in Task 1 Step 4 and consumed with that exact name/signature in Task 2 Step 4 — matches.
- **Scope:** single cohesive feature, one package (`XsdToStruct.jl`), two implementation tasks plus a verification-only gate — not further decomposable without creating an artificial task boundary.
