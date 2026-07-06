# XmlStructLoader Lazy Loading — Design

## Problem

`XmlStructLoader.load(xml_path, module_ref)` parses an XML document and eagerly constructs a
full tree of typed Julia structs matching the XSD schema. For large documents this is slow —
measured on a 5.3MB synthetic fixture, the underlying pugixml parse itself takes ~6ms, but the
subsequent step of recursively converting that parsed tree into fully-typed, validated Julia
structs for every element takes ~330ms total (~98% of total load time). Many real callers only
ever touch a handful of fields out of a large document.

Goal: let `load()` return almost instantly, and defer each field's actual parsing/construction to
the first time that field is accessed, caching the result after that. Must work for arbitrarily
deeply nested structs — accessing a field three levels deep should only construct the structs on
the path to it, not sibling subtrees.

## Prior art

A prior internal branch (`lazy`) already built this once, against EzXML.jl (whose `Node` type is
a normal GC-managed Julia object holding a reference to its owning `Document`). Its design is
being adapted here, not redesigned from scratch:

- `XmlStructLoader.load` gains a `load_strategy` keyword: `ReadAllData()` (default, today's eager
  behavior, unchanged) vs `ReadOnAccess()` (new, lazy).
- Every generated complex struct retains the node it was built from (`_node` field).
- Every other field is declared with `LazilyInitializedFields.jl`'s `@lazy` macro:
  `@lazy fieldname::T = _init_fieldname`, where `_init_fieldname(o::StructName)` is a generated,
  per-field, per-struct function doing the real parsing work (pull the child node by name, convert
  to the right type, or recurse into a nested struct constructor) the first time the field is
  accessed. `LazilyInitializedFields.jl` handles the caching/uninit-tracking machinery.
- `ReadOnAccess()`: parse the document, construct just the top-level struct from the root node
  (cheap — the node-based inner constructor just stores the node and marks every lazy field
  `uninit`), return it. No recursion into children at load time.
- Known, accepted limitation: XSD "choice" fields (`xs:choice`) don't get lazy treatment —
  `@lazy`'s custom `propertynames` override conflicts with choice-field handling's own
  `propertynames` implementation, so those stay eager.
- Real gotcha found the hard way: `Base.show` must be special-cased to not force-materialize lazy
  fields just to print/debug an object.
- Independently confirmed (via SnoopCompile on that branch): `ZonedDateTime` parsing has an
  unusually expensive-to-compile code path (~2.4s to JIT-compile one specialization) — same root
  cause independently found and fixed in this repo's `@compile_workload` precompile-latency work.

## What's different now: the pugixml lifetime problem

The current backend is pugixml (via `XmlStructPugixml.jl`, ccall), not EzXML — swapped in an
already-merged, unrelated bake-off because it benchmarked fastest. This changes the design:

- Every "node" is a bare `Ptr{Cvoid}` — pugixml's own internal pointer into its C++-managed memory
  pool. Not a Julia object, no GC integration, no finalizer.
- The document is parsed via `parse_file`/`parse_buffer` (returns `Ptr{Cvoid}`) and must be freed
  via `free_doc` exactly once; every node pointer obtained from it becomes dangling the instant
  `free_doc` runs. Today, `load()` parses inside a `try ... finally free_doc(doc) end` block — the
  document is always freed before `load()` returns, which is exactly why lazy loading doesn't
  already work: any retained node pointer would already be dangling by the time a caller tried to
  lazily access a field.
- Pugixml's document is a single-owner C++ object (`new pugi::xml_document()` / `delete doc` in
  the shim) — no reference counting, no shared-ownership mode. This is standard pugixml design,
  not a limitation of this Julia wrapper, and it is not a barrier to lazy loading: pugixml's own
  full-document parse is already so fast (~6ms of the ~330ms total, on the 5.3MB fixture) that
  there is no benefit to limiting how much of the raw XML it parses. The 98% of time that lazy
  loading actually defers is entirely the Julia-side step of converting pugixml's already-built
  tree into typed structs — not the XML parsing itself.

### Lifetime solution: GC-rooted document handle

Reviewed with a second independent design pass (Fable) before finalizing. Approach:

- `PugixmlDocumentHandle` — mutable struct wrapping the raw `doc::Ptr{Cvoid}`, with an **idempotent**
  finalizer (sets `ptr` to `C_NULL` after freeing, so a later finalizer run or explicit `close()` is
  a no-op) registered immediately after `parse_file`/`parse_buffer` returns — before anything else
  can throw, so no error path can leak the C++ document. Also exposes an explicit `close()` for
  deterministic release (loading many large documents in a loop shouldn't rely on GC timing to
  release multi-MB C++ memory pools).
- `LazyNode` — immutable `(ptr::Ptr{Cvoid}, owner::PugixmlDocumentHandle)` pair. As long as any
  `LazyNode` anywhere in a returned object graph is reachable, Julia's GC transitively keeps
  `owner` (and thus the underlying pugixml document) alive. The finalizer only fires once nothing
  references any node from that document anymore.
- **No raw-pointer accessor is ever exposed from the lazy layer.** Every pugixml call on a
  `LazyNode` goes through an internal helper that does `GC.@preserve node.owner ccall(...)` —
  including `unsafe_string` calls that read pugixml-owned memory for names/text. This is the one
  real hazard: extracting a bare pointer and calling it after the `LazyNode` becomes unreachable is
  a legal-timing use-after-free, since the finalizer can run mid-call otherwise.
- This is standard idiom, not a workaround — `EzXML.Node` itself works this way (holds a reference
  to its owning `Document`), same shape as LibGit2.jl and SQLite.jl. No new dependency needed.
- Thread safety: lazy init is an unsynchronized write to the struct on first access. v1 scope is
  "one struct graph accessed from one task" — documented, not enforced. A lock is a future upgrade
  if concurrent access across tasks is ever needed.
- Choice-field-near-root risk (checked, not assumed): verified against the real ISO 20022 fixture
  (`pacs.008.001.09.xsd`) that the root path (`Document` → `FIToFICstmrCdtTrf` →
  `GrpHdr`/`CdtTrfTxInf`) is entirely `xs:sequence`, no choice gating — all 48 `xs:choice`
  occurrences in that schema are small leaf-level "pick one identifier shape" helpers. The
  inherited eager-choice-field limitation will not defeat laziness for the real target workload.

## Components

**Placement deviation from the reference branch (confirmed with user):** the reference branch put
its lazy node/document types and parsing helpers in `AbstractXsdTypes.jl`, which required adding
`EzXML` as a new direct dependency of that package (confirmed via its `Project.toml`). Current
main's `AbstractXsdTypes.jl` has zero XML backend dependency — by design, it's backend-agnostic —
and `XmlStructLoader.jl` already owns the pugixml dependency plus the exact abstraction layer
(`xml_abstraction.jl`: `name`, `content`, `haschildren`, `getattributes_dict`) this needs. So the
new lazy machinery lives in **`XmlStructLoader.jl`** instead, not `AbstractXsdTypes.jl`. Generated
modules already `import XmlStructLoader` (from the merged precompile-workload feature), so
`_init_<field>` bodies can call `XmlStructLoader.<helper>` with no circular dependency.

**XmlStructLoader.jl** (new file, e.g. `src/xml_parser/lazy_xml_node.jl`):
- `PugixmlDocumentHandle`, `LazyNode` as described above.
- Lazy parsing helpers adapted from the reference design (`_node_with_name`,
  `_parse_child_xml_node`, `_parse_xml_list`, `_init_simple_node`, attribute-dict extraction) —
  same shape, operating on `LazyNode`, matching current main's `__xml_attributes`/`__validated`
  field naming (the reference branch's renamed `xml_attributes`/`validated` was an unrelated
  refactor on that branch, out of scope here). These are entirely new, additive functions — the
  existing eager pipeline (`xml_parser.jl`, `xml_parser_in_module.jl`, `xml_parser_type_info.jl`)
  is untouched; `ReadOnAccess` never calls `construct_xml_object`/`construct_xml_root_object` at
  all, since that machinery's `AbstractTrees.PostOrderDFS` + `Dict{Symbol,Any}` bottom-up
  accumulation model only exists to support all-at-once eager construction. Lazy loading is a
  simple top-down `StructName(node)` constructor per type, same shape as the reference branch's
  `EzXML`-based one.
- **Not porting `lazy_kwdef.jl`.** The reference branch itself didn't use that macro in codegen —
  it hand-generates the outer keyword constructor directly, same as the existing non-lazy codegen
  path. Not carrying over machinery even its own author bypassed in practice.

**XsdToStruct.jl** (codegen):
- Complex types with no choice fields: emit `@lazy struct` (adds `_node::Union{Nothing,LazyNode}`),
  one `_init_<field>` function per field dispatching by field kind (scalar, vector, nested complex,
  extended type), the node-based inner constructor (stores the node, marks fields `uninit`, builds
  attributes eagerly), and the hand-rolled outer kwdef constructor.
- Choice-bearing types stay eager, unchanged.
- Extend the existing `@compile_workload` (from the merged precompile-latency work) to also run a
  `ReadOnAccess` load and touch every field once, so `_init_*` functions — including the expensive
  `ZonedDateTime` path — get the same precompile-time warmup as the eager path, so that cost
  doesn't resurface as a first-field-access latency spike instead.

**XmlStructLoader.jl**: `LoadStrategy`/`ReadAllData`/`ReadOnAccess` trait,
`load(...; load_strategy=DEFAULT_LOAD_STRATEGY())`, same shape as the reference branch.
`ReadAllData` is untouched, byte-for-byte.

**New dependency footprint — a known ripple-effect risk in this codebase.** The precompile-
latency work already hit this exact class of bug: `import_module`/`use_module`
(`xml_module_utilities.jl`) `include()` generated code directly into `XmlStructLoader.jl`'s own
module scope, so any package a generated module's code needs must resolve from *that* package's
own `Project.toml`, not the caller's environment. The generated struct submodule emits
`using LazilyInitializedFields` directly (needed for the `@lazy` macro), so — following the
placement decision above — `LazilyInitializedFields.jl` is a new runtime dependency of
**`XmlStructLoader.jl`** (not `AbstractXsdTypes.jl`). It must be checked against every place
generated code gets `include()`d (both `XmlStructLoader.jl`'s own `import_module`/`use_module` path
and the plain `Base.include(Main, ...)` path some tests use), the same way `PrecompileTools` was —
not assumed to just work because it's declared once somewhere.

## Data flow (`ReadOnAccess`)

1. `parse_file`/`parse_buffer` → raw `doc` → wrapped in `PugixmlDocumentHandle` immediately.
2. Root node wrapped as `LazyNode(root_ptr, handle)`.
3. `module_ref.__meta.root_type(lazy_root_node)` builds just the top-level struct (store node, mark
   everything else `uninit`, build attributes eagerly). Returned to caller. Total cost ≈ parse time
   (~6ms scale) + one shallow constructor call.
4. First access to a field: `LazilyInitializedFields` sees `uninit`, calls `_init_<field>`, which
   pulls the child node and either parses a scalar, constructs a nested struct (itself lazy —
   nothing recurses further until *its* fields are touched), or builds a `Vector` (all elements at
   once — **field-level granularity, not per-element**). Result is cached in the field slot;
   later reads are plain field reads.
5. Once nothing in the object graph still references a `LazyNode` from a document, GC eventually
   collects the last `PugixmlDocumentHandle` reference and frees the C++ document — or the caller
   calls `close()` for deterministic cleanup.

## Error handling

- Parse failure: unchanged, same error as today, before any lazy wrapping exists.
- `validate=true` with `ReadOnAccess()`: `ArgumentError`, checked before parsing. Silently ignoring
  an explicit validation request would be a correctness trap (validation requires the parsed
  value, which requires materializing the field — incompatible with the point of `ReadOnAccess`).
- **A real, named tradeoff:** a field access failure (malformed content, a genuinely-missing
  required element) surfaces at *first access* to that field, not at `load()` time. A
  `ReadOnAccess`-loaded document can return successfully from `load()` even if it's subtly
  non-conformant, then throw later. Documented explicitly, with its own test — the reference
  branch's tests only checked equivalence on valid documents.
- `_node = nothing` (a struct built by hand via the plain keyword constructor) never coexists with
  `uninit` fields — the kwdef constructor always supplies every field directly. No special case.
- No per-access "is this handle still open" check after `close()` — same posture as reading a
  closed `IOStream`. Documented caveat, not a defended-against error path.
- `XmlStructWriter.jl` needs no code changes — serializing already means reading every field
  recursively to emit XML, which naturally triggers lazy materialization. To be confirmed by a
  round-trip test, not assumed.

## Known behavior changes

- **`ReadAllData` (eager) empty-content complex elements now keep their attributes and honor
  `validate`.** `xml_parser_in_module.jl`'s `parse_xml_node_in_module`, in the branch for a complex
  type with no element content and no default value, used to construct the value with a bare `T()`
  — which silently fell back to that type's own kwarg defaults (`__xml_attributes=nothing`,
  `__validated=true`), regardless of the caller's actual `validate` argument or any real attributes
  present on the tag (e.g. `<TestElement3 id="x"></TestElement3>` would lose `id="x"` entirely and
  always report `__validated=true` even under `validate=false`). This plan's Task 6 changed that
  call to `T(; __xml_attributes = getattributes_dict(xml_node), __validated = validate)`, threading
  both through correctly. This is a change to `ReadAllData` behavior, not lazy-only, and was flagged
  by the final whole-branch review as contradicting this document's stated goal of leaving
  `ReadAllData` byte-for-byte unchanged. It is being kept, not reverted: it corrects a real,
  previously-silent bug rather than introducing a new one, incidentally fixed while adding lazy
  support.

## Testing

Three of the four touched packages (`AbstractXsdTypes.jl`, `XsdToStruct.jl`,
`XmlStructLoader.jl`) still run the classic `XyzTests.runtests()` pattern — only
`XmlStructPugixml.jl` has migrated to ReTestItems.jl so far. Per the established one-package-at-a-
time approach, this feature does not force a full migration of any of these three. Every **new**
test file this feature adds is written as `@testitem` blocks (ReTestItems.jl), with `ReTestItems`
added as a **test-only** dependency (`test/Project.toml` only) in each touched package. Existing
`@testset`-based suites keep running exactly as today; `runtests.jl` in each touched package
invokes both the existing custom runner and `ReTestItems.runtests(@__DIR__)` for the new files
(exact coexistence wiring is a plan-level detail, not a design-level one).

1. **Lifetime/safety** (`AbstractXsdTypes.jl`, new `@testitem` file): finalizer fires exactly once
   even when `close()` is also called explicitly; forced `GC.gc()` calls interleaved between node
   accesses don't crash or corrupt data; double-`close()` is a no-op.
2. **Codegen** (`XsdToStruct.jl`, new `@testitem` file): schemas without choice fields emit
   `@lazy struct`/`_init_*` functions; schemas with choice fields still emit the plain eager struct
   (regression guard) — reusing the existing ~14 generic-data fixtures.
3. **Equivalence** (`XmlStructLoader.jl`, new `@testitem` file, adapting the reference branch's
   `compare_tree(lazy, full)` pattern): for every generic-data and edge-case fixture, a
   fully-materialized `ReadOnAccess` load equals a `ReadAllData` load. Run against the real ISO
   20022 fixture too.
4. **Tradeoffs surfaced during design** (not covered by the reference branch's own tests):
   - `validate=true` + `ReadOnAccess()` raises `ArgumentError`.
   - A malformed-document field error surfaces at first access, not at `load()` time.
   - `XmlStructWriter.jl` round-trip of a partially-touched lazy struct matches a fully-eager
     round-trip byte-for-byte.
   - Touching one element of a repeated field materializes that whole field but leaves sibling
     fields `uninit` (field-level, not per-element, granularity).
5. **Perf sanity check** (Chairmarks, saved to `bench/results/*.json` per existing convention, not
   a strict CI gate given this project's documented benchmark-noise history): cold `load()`
   **latency** + touch-one-field, under `ReadOnAccess` vs. full `ReadAllData`, on both the 5.3MB
   synthetic fixture and the real ISO 20022 fixture. Latency is the headline number — it's the
   original motivation (large documents taking too long to traverse and parse) — with
   allocations/memory as a secondary metric. Written up as a clear before/after summary in the PR
   description (same pattern as the precompile-workload PR's benchmark table), so the measured
   gain is visible at a glance, not buried in raw JSON.
