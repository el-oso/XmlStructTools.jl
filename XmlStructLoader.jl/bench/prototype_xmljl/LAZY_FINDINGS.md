# XML.jl `LazyNode` investigation

Question: does XML.jl's lazy parsing mode help XmlStructLoader, given a possible future
redesign toward lazy (on-demand) field materialization? Investigated post-bake-off,
2026-07-04, alongside a check of whether pugixml/quick-xml have equivalent lazy modes.

## `LazyNode` is genuinely lazy — for selective access

Confirmed empirically:
- Constructing a `LazyNode` root over the 5MB, 20,000-record `large_synthetic.xml` costs
  ~1.2ms / 5MB allocated (just reading the raw file into a string) vs ~50-600ms / 61-152MB for
  eagerly parsing the same file into a `Node` tree.
- Accessing one specific leaf field costs ~2-8µs (dominated by JIT warmup on the very first
  call; steady-state is ~2µs) **regardless of that field's position in the document** — touching
  entry #1's `EntryId` and entry #20000's `EntryId` cost the same, and touching 100 vs 16,000
  *distinct* entries (without repeats) shows no growth in per-entry cost. This is real,
  position-independent, on-demand parsing — not a benchmarking artifact.

## But: using `LazyNode` as a `Dict`/`IdDict` key is catastrophically slow

`XmlStructLoader`'s current algorithm (`construct_xml_node_child_objects`,
`xml_parser_in_module.jl:47,75`) keys a `Dict{typeof(xml_node), Dict{Symbol,Any}}` accumulator
by the **raw node itself** — every parent gets its children's constructed values accumulated
into a dict keyed by that parent's raw node object. My compatibility layer needed the same
pattern for its own raw-node → raw-parent map.

Measured directly: `LazyNode` is not an `isbits` type (its fields are `data::String,
token::XML.XMLTokenizer.Token, nodetype::NodeType`), and `IdDict` insert/lookup keyed by a
`LazyNode` costs **~700-1000µs per operation** — roughly 500-1000x slower than a normal
dict op on a cheap key (a pointer, an int, or an `isbits` struct like `Ptr{Cvoid}` or the
`(doc, idx)` pair the quick-xml prototype uses). This is what actually produced the
apparent-quadratic full-walk slowdown observed initially (250→2000 entries: 1.9s→4.3s, with
each doubling of N roughly quadrupling the per-step cost) — not `LazyNode`'s own traversal,
which is flat, but the dict-keying pattern the *algorithm* requires, applied ~140,000 times
over the full document.

Extrapolated: at this per-op cost, a full 20,000-entry walk (~140,001 dict operations) would
take on the order of minutes, not milliseconds — confirmed by killing an actual full-walk run
after 3+ minutes still in progress, consistent with the ~7-minute extrapolation from the
smaller-N measurements.

## Verdict

- **For `XmlStructLoader`'s current, fully-eager design** (every field of every node gets
  visited and materialized on every `load()` call): `LazyNode` is a severe regression, not an
  improvement. Laziness only pays off when something is left unvisited, and today nothing is.
  The eager `Node`-backed prototype (in `loader_xmljl.jl`, the one that went into the bake-off)
  remains the right XML.jl comparison point for that design.
- **For a future lazy-redesigned `XmlStructLoader`** (materializing fields on access, e.g. a
  caller reading `doc.Header.Amount` without ever touching `doc.Entries`): `LazyNode`'s
  position-independent, on-demand access is exactly the right primitive — genuinely fast,
  genuinely lazy. But such a redesign would need to **avoid dict-keying by raw backend nodes**
  (the specific pattern that's pathological here) — e.g. track parent/position via a cheap
  `isbits` handle (an index, a pointer, or a small tuple) rather than the node object itself,
  the same lesson the eager prototypes' `_raw_parent_map` already leans on for pugixml
  (`Ptr{Cvoid}`, cheap) and quick-xml (`(doc, idx)`, cheap) but LazyNode breaks.

## Other backends: no equivalent lazy mode found

- **pugixml**: DOM-only by design — confirmed via its own header (`vendor/pugixml.hpp`), no
  lazy/deferred parsing mode exists. It always eagerly builds its internal tree at parse time.
- **quick-xml**: the underlying Rust crate *is* inherently a pull/streaming parser (that's its
  whole design point, unlike pugixml) — but `quickxml_shim` as built wraps it in an eager
  in-memory arena (`Vec`-backed, built fully at parse time) rather than exposing on-demand pull
  access. A genuinely lazy quick-xml shim is possible in principle (expose a cursor/pull-based
  C API instead of pre-building the arena) but would be new work, not yet built or measured.
