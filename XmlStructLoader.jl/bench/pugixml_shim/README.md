# pugixml_shim

Minimal C ABI shim over pugixml's C++ DOM, for using pugixml as
XmlStructLoader.jl/XmlStructWriter.jl's XML backend (replacing
LightXML/EzXML) from Julia via `ccall`. Covers parsing a file, walking
element children, reading attributes and leaf text content, and (for
writing) building a fresh document, appending elements/attributes/text, and
serializing it to a file.

## Building

```sh
make            # builds libpugixml_shim.so
make test       # builds and runs test_shim against the fixtures below
```

Built against **`pugixml_jll`** (the Yggdrasil/BinaryBuilder artifact for
pugixml, already published in the General registry): it ships both the
compiled `libpugixml.so` and the headers (`pugixml.hpp`/`pugiconfig.hpp`)
needed to compile against it, so there's no vendored source and no need for
a system `libpugixml-dev` package.

The Makefile resolves the artifact path by shelling out to Julia:

```make
PUGIXML_ARTIFACT_ROOT := $(shell julia --project=. -e 'using pugixml_jll; print(dirname(dirname(pugixml_jll.libpugixml_path)))')
```

against the **dedicated Julia environment** defined by `Project.toml`/
`Manifest.toml` in this directory (`julia --project=.`), not the ambient/
default Julia environment.

### Why a dedicated Julia environment instead of the ambient one

Two options were considered:

1. Shell out against whatever Julia environment happens to be active
   (`julia -e '...'` with no `--project`).
2. Shell out against a small dedicated environment pinned right next to the
   Makefile (this directory's `Project.toml` + `Manifest.toml`).

Went with (2): the build shouldn't depend on whether `pugixml_jll` happens
to be installed -- or which version -- in whichever global/shared
environment a given developer's or CI machine's default Julia depot has
active. `Project.toml`/`Manifest.toml` here pin an exact, reproducible
`pugixml_jll` version that travels with the repo, same as any other
dependency manifest. The only cost is one extra `Pkg.add` the first time
(`julia --project=. -e 'using Pkg; Pkg.add("pugixml_jll")'`, already done --
both files are checked in), and the Makefile works from a fresh checkout
with no ambient-environment assumptions.

### Eventual `deps/build.jl` translation

This Makefile is a stand-in for what should eventually be a
`Pkg.build()`-time step in the real Julia package. The translation is
mechanical -- same two things the Makefile does, just from Julia instead of
`make`:

```julia
# deps/build.jl (sketch)
using pugixml_jll  # already a declared dependency of the package itself,
                    # so Pkg.build() has it resolved -- no separate env needed
artifact_root = dirname(dirname(pugixml_jll.libpugixml_path))
inc = joinpath(artifact_root, "include")
lib = joinpath(artifact_root, "lib")

cxx = get(ENV, "CXX", "g++")
run(`$cxx -O2 -std=c++14 -fPIC -shared -o $(@__DIR__)/libpugixml_shim.so
     $(@__DIR__)/../shim.cpp -I$inc -L$lib -lpugixml -Wl,-rpath,$lib`)
```

The dedicated-environment question above goes away at that point: once
`pugixml_jll` is a real `[deps]` entry of the Julia package (not just this
shim's throwaway `Project.toml`), `Pkg.build()` runs with the package's own
resolved environment automatically -- there's no "ambient vs. dedicated"
ambiguity to resolve, Julia's package manager already guarantees it.

## Handle model

- `pugishim_parse_file` and `pugishim_new_doc` both return an **owning**
  `xml_document*` handle. Call `pugishim_free_doc` exactly once on it when
  done, whichever way it was created -- pugixml doesn't distinguish
  "parsed" from "freshly constructed" at the type level (`xml_document` is
  the same C++ type either way).
- Document handles (`xml_document*`) and node handles
  (`xml_node_struct*`, see below) are **not interchangeable**, even though
  `xml_document` publicly inherits `xml_node` in pugixml's C++ class
  hierarchy. `pugishim_doc_as_node` is the bridge from one to the other (see
  its own entry in the function table).
- Every node/attribute handle is pugixml's own internal pointer
  (`xml_node_struct*` / `xml_attribute_struct*`), obtained through pugixml's
  public `internal_object()` accessor / `xml_node(xml_node_struct*)`
  constructor round-trip. These are lightweight views into the document's
  internal memory pool: they do **not** need to be freed individually, and
  they become dangling once the owning document is freed.
- `nullptr` (`C_NULL` from Julia) means "no such node/attribute" -- empty
  document, end of child/sibling/attribute iteration, or a failed parse.
- All `const char*` returns point into memory owned by the document; they
  are valid only until `pugishim_free_doc` is called on that document. Copy
  them (e.g. `unsafe_string` in Julia) before freeing.
- Element/attribute name and text comparisons are byte-for-byte against the
  source XML: pugixml does not split a name like `TestComplexAndSimple:document`
  into namespace + local part unless you use its separate namespace-processing
  helpers, which this shim does not use.
- `pugishim_node_text` is pugixml's `child_value()`: the value of the node's
  first text/CDATA child only, not text concatenated across all descendant
  elements. Verified against source (`pugixml.cpp`, `xml_node::child_value`)
  and against `basic_types.xml`.

## Function signatures

All functions are `extern "C"`, exported from `libpugixml_shim.so`. For
Julia `ccall`, handles are `Ptr{Cvoid}` and strings are `Cstring`/`Ptr{Cchar}`.

| Function | Args | Returns | Notes |
|---|---|---|---|
| `pugishim_parse_file` | `const char* path` | `void*` (doc handle) | `nullptr` on parse failure (bad path or malformed XML) |
| `pugishim_free_doc` | `void* doc` | `void` | frees the document; invalidates all handles obtained from it |
| `pugishim_root` | `void* doc` | `void*` (node handle) | the document's root element; `nullptr` if none |
| `pugishim_node_name` | `void* node` | `const char*` | tag name, e.g. `"TestElement1"`; never null, `""` if node has no name |
| `pugishim_node_text` | `void* node` | `const char*` | direct text content (`child_value()`); never null, `""` if none |
| `pugishim_first_child_element` | `void* node` | `void*` (node handle) | first **element** child (text/comment/PI nodes skipped); `nullptr` if none |
| `pugishim_next_sibling_element` | `void* node` | `void*` (node handle) | next **element** sibling (text/comment/PI nodes skipped); `nullptr` if none |
| `pugishim_has_element_children` | `void* node` | `int` | `1` if node has at least one element child, else `0` |
| `pugishim_first_attribute` | `void* node` | `void*` (attr handle) | first attribute of node; `nullptr` if none |
| `pugishim_next_attribute` | `void* attr` | `void*` (attr handle) | next attribute after `attr`; `nullptr` if none |
| `pugishim_attribute_name` | `void* attr` | `const char*` | attribute name; never null |
| `pugishim_attribute_value` | `void* attr` | `const char*` | attribute value; never null |

### Writing

| Function | Args | Returns | Notes |
|---|---|---|---|
| `pugishim_new_doc` | (none) | `void*` (doc handle) | new empty document; free with `pugishim_free_doc` exactly like a parsed one |
| `pugishim_doc_as_node` | `void* doc` | `void*` (node handle) | views a document handle as a node handle, so it can be passed to `pugishim_append_child_element` to create the **root** element; do not free this handle separately |
| `pugishim_append_child_element` | `void* node`, `const char* name` | `void*` (node handle) | appends a new child element named `name`; `node` may be an element handle or a `pugishim_doc_as_node` result; `nullptr` on failure |
| `pugishim_set_node_text` | `void* node`, `const char* text` | `int` | sets the node's direct text content (`xml_text::set`); `1` on success, `0` on failure |
| `pugishim_append_attribute` | `void* node`, `const char* name`, `const char* value` | `void*` (attr handle) | appends one attribute; call once per name/value pair; `nullptr` on failure |
| `pugishim_save_file` | `void* doc`, `const char* path` | `int` | serializes `doc` to `path`; `1` on success, `0` on failure (bad path, permissions, ...) |

### Typical traversal from Julia

```julia
doc = ccall((:pugishim_parse_file, lib), Ptr{Cvoid}, (Cstring,), path)
doc == C_NULL && error("parse failed")
root = ccall((:pugishim_root, lib), Ptr{Cvoid}, (Ptr{Cvoid},), doc)

child = ccall((:pugishim_first_child_element, lib), Ptr{Cvoid}, (Ptr{Cvoid},), root)
while child != C_NULL
    name = unsafe_string(ccall((:pugishim_node_name, lib), Cstring, (Ptr{Cvoid},), child))
    # ... use name ...
    child = ccall((:pugishim_next_sibling_element, lib), Ptr{Cvoid}, (Ptr{Cvoid},), child)
end

ccall((:pugishim_free_doc, lib), Cvoid, (Ptr{Cvoid},), doc)
```

### Typical writing from Julia

Mirrors LightXML's `XMLDocument()` / `new_element` / `set_root` / `add_child`
/ `set_content` / `set_attributes` / `save_file` shape used by
XmlStructWriter.jl -- except here there's no separate "unattached element"
step: `pugishim_append_child_element` both creates and attaches in one call
(pugixml has no detached-node API to speak of), so the doc's root is created
by appending directly onto `pugishim_doc_as_node(doc)`.

```julia
doc = ccall((:pugishim_new_doc, lib), Ptr{Cvoid}, ())
doc_node = ccall((:pugishim_doc_as_node, lib), Ptr{Cvoid}, (Ptr{Cvoid},), doc)

root = ccall((:pugishim_append_child_element, lib), Ptr{Cvoid},
             (Ptr{Cvoid}, Cstring), doc_node, "TestNamespace:document")
ccall((:pugishim_append_attribute, lib), Ptr{Cvoid},
      (Ptr{Cvoid}, Cstring, Cstring), root, "xmlns:xsi",
      "http://www.w3.org/2001/XMLSchema-instance")

child = ccall((:pugishim_append_child_element, lib), Ptr{Cvoid},
              (Ptr{Cvoid}, Cstring), root, "TestElement2")
ccall((:pugishim_set_node_text, lib), Cint, (Ptr{Cvoid}, Cstring), child, "99A9")

ok = ccall((:pugishim_save_file, lib), Cint, (Ptr{Cvoid}, Cstring), doc, path)
ok == 1 || error("save failed")
ccall((:pugishim_free_doc, lib), Cvoid, (Ptr{Cvoid},), doc)
```

## Verification

`test_shim.cpp` links only against the compiled `libpugixml_shim.so` (it does
not include any pugixml headers itself -- it only declares the `extern "C"`
prototypes above, exactly as a Julia `ccall` consumer would see them). It:

- parses `test/test_data/generic_cases/basic_types.xml`, prints the root tag
  name and its attributes, walks the 3 root element children, confirms leaf
  (`TestElement2`) vs. branch (`TestElement1`/`TestElement3`) detection, and
  checks exact text/attribute values;
- parses `bench/fixtures/large_synthetic.xml` (~5MB, 20,000 records) and
  walks every entry and every field of every entry, confirming no crash and
  the expected entry count;
- (write side) builds a small document from scratch with the write
  functions -- namespace-prefixed root tag, `xmlns:xsi`/`xsi:schemaLocation`
  root attributes, a leaf child with text + an attribute, and a second child
  with its own nested child, matching `basic_types.xml`'s shape -- saves it
  to a temp file, then **reads that file back with the read-side
  functions** and asserts every tag name, attribute name/value, and text
  value round-tripped correctly. This is the real correctness check for the
  write API, not just "didn't crash".

Run with `make test` (fixture paths are wired into the Makefile's `test`
target). Also verified leak-free under `valgrind --leak-check=full` (exit
code 0, no errors reported, "All heap blocks were freed -- no leaks are
possible") across all three: basic_types.xml, large_synthetic.xml, and the
write+readback roundtrip, in one process.
