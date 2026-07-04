# pugixml_shim

Minimal C ABI shim over pugixml's C++ DOM, for benchmarking pugixml against
LightXML/EzXML from Julia via `ccall`. Not a production wrapper -- just
enough surface to parse a file, walk element children, read attributes, and
read leaf text content.

## Building

```sh
make            # builds libpugixml_shim.so
make test       # builds and runs test_shim against the two fixtures below
```

`vendor/` contains pugixml 1.14 source (`pugixml.hpp`/`pugixml.cpp`/
`pugiconfig.hpp`, fetched from https://github.com/zeux/pugixml/releases/tag/v1.14,
matching the version of `libpugixml1v5` already installed on this system,
though the version match is incidental -- see "Why vendored" below).
`pugixml.cpp` is compiled directly into `libpugixml_shim.so`, so the shared
library is self-contained and does not link against any system
`libpugixml.so` at runtime.

### Why vendored instead of the system package

The system has the pugixml *runtime* package (`libpugixml1v5`, 1.14) but not
`libpugixml-dev` (no headers), and installing it requires `sudo` which was
not available non-interactively in this environment. Vendoring the small
(~350KB) single-`.cpp` source directly from GitHub sidesteps both the
missing headers and any header/ABI version-skew risk against the system
`.so`. If this backend is picked in the bake-off, Phase 3 packaging should
almost certainly switch to `pugixml_jll` (the Yggdrasil/BinaryBuilder
artifact) instead of this vendored copy -- vendoring here was purely to
unblock the benchmark.

## Handle model

- `pugishim_parse_file` returns an **owning** `xml_document*` handle. Call
  `pugishim_free_doc` exactly once on it when done.
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
  the expected entry count.

Run with `make test`. Also verified leak-free under
`valgrind --leak-check=full` (exit code 0, no errors reported) for both
fixtures in one process (parse basic_types.xml, free it, parse
large_synthetic.xml, free it).
