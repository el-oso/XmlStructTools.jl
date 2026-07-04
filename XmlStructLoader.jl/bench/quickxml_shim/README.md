# quickxml_shim

Benchmark-only C ABI shim over the Rust `quick-xml` crate (0.36, pull-parser
API with the classic single-event `.unescape()` — deliberately not the
0.41 API, which splits entity references into a separate `GeneralRef`
event and would add real complexity for no benefit at this file's scope).

Not a production wrapper. It parses a whole file into an in-memory element
tree (a `Vec`-backed arena of nodes with parent→children indices) and exposes
read-only accessors as `extern "C" fn`s so a later step can `ccall` into it
from Julia. Elements + attributes + direct leaf text only — comments, PIs,
CDATA, and mixed content are out of scope.

## Build

```sh
cargo build --release   # -> target/release/libquickxml_shim.so
cargo test --release -- --nocapture   # runs tests/smoke.rs against the real fixtures
```

`crate-type = ["cdylib", "rlib"]`: cdylib is the `.so` for `ccall`; rlib lets
`tests/smoke.rs` call the same `extern "C" fn`s in-process (as raw pointers,
same as a C/Julia caller would) for verification without needing a header
file or a separate C test harness.

`profile.release.panic = "abort"`: unwinding a Rust panic across an FFI
boundary into Julia is undefined behavior. `panic = "abort"` turns any bug
that would otherwise panic into a hard process abort instead — blunt, but
safe. None of the functions below are expected to panic on valid input
(bounds/null checks are explicit, not `unwrap`-and-hope), but this is the
backstop.

## Function signatures

All node/doc arguments are validated defensively: null `doc`, negative
indices, or out-of-range indices return a null pointer / `-1` / `0` rather
than panicking or reading out of bounds.

```c
// 1. Parse a file into an in-memory tree. Returns an opaque document handle,
//    or NULL on any I/O or XML parse error. `path` must be a null-terminated
//    UTF-8 C string.
QxDocument* quickxml_parse_file(const char* path);

// 2. Free a document returned by quickxml_parse_file. NULL is a no-op.
//    Invalidates every pointer previously returned for this doc.
void quickxml_free(QxDocument* doc);

// 3. Root element's node index (>= 0), or -1 if doc is NULL.
int32_t quickxml_root(const QxDocument* doc);

// 4. Iterate ELEMENT children only (no text nodes in the tree at all).
int32_t quickxml_child_count(const QxDocument* doc, int32_t node);
int32_t quickxml_child_at(const QxDocument* doc, int32_t node, int32_t idx); // -1 if idx out of range

// 5. Tag/element name, e.g. "Foo" for <Foo>. NULL if node/doc invalid.
const char* quickxml_tag_name(const QxDocument* doc, int32_t node);

// 6. Attributes: count + indexed (name, value) accessors.
int32_t quickxml_attr_count(const QxDocument* doc, int32_t node);
const char* quickxml_attr_name(const QxDocument* doc, int32_t node, int32_t idx);  // NULL if idx out of range
const char* quickxml_attr_value(const QxDocument* doc, int32_t node, int32_t idx); // NULL if idx out of range

// 7. Direct text content of a leaf element, e.g. <Foo>bar</Foo> -> "bar".
//    NULL if the node has no direct text (e.g. it only has element children).
const char* quickxml_text(const QxDocument* doc, int32_t node);

// 8. Whether a node has at least one element child. 1 or 0 (also 0 if
//    node/doc invalid — never a bare C `bool`, to keep the ABI unambiguous
//    across languages).
int32_t quickxml_has_element_children(const QxDocument* doc, int32_t node);
```

`QxDocument*` is an opaque pointer (`*mut QxDocument` in Rust) — treat it as
`Ptr{Cvoid}` on the Julia side. `int32_t` node handles are arena indices, not
pointers; `-1` is the "no such node" sentinel everywhere one is needed.

## Lifetime / safety notes for the `ccall` caller

- **All `const char*` return values (`quickxml_tag_name`, `quickxml_attr_name`,
  `quickxml_attr_value`, `quickxml_text`) are owned by the `QxDocument` arena.
  They are valid only as long as that specific `doc` handle has not yet been
  passed to `quickxml_free`.** Copy the bytes out (e.g. `unsafe_string` in
  Julia) before freeing the document if you need them afterward — do not
  hold onto the pointer past `quickxml_free`.
- Every one of those string pointers is guaranteed non-dangling even though
  the underlying `Vec<QxNode>` may reallocate internally during parsing:
  each string is stored as an owned `CString`, and moving a `CString`'s
  struct (pointer+len) does not move or invalidate its heap-allocated
  buffer. Only the *outer* `Vec<Node>`/`Vec<(CString,CString)>` containers
  move; the string bytes they point at do not.
- **Call `quickxml_free` exactly once per handle returned by
  `quickxml_parse_file`.** Double-free is UB (same contract as C `free`);
  this shim does not guard against it. `quickxml_free(NULL)` is a safe no-op.
- `quickxml_parse_file` returns `NULL` on any error (bad path, non-UTF-8
  path, malformed XML, empty document with no root element) — always check
  for `NULL` before using the handle.
- Node handles (`int32_t`) are meaningless once their `doc` has been freed;
  don't cache them across a free/reparse.
- Not thread-safe for concurrent *writers* to the same handle, but a single
  parsed `QxDocument` is read-only after `quickxml_parse_file` returns, so
  concurrent reads from multiple threads against the same still-live handle
  are fine (no interior mutability anywhere in the arena).

## Verified against

- `test/test_data/generic_cases/basic_types.xml` — real fixture with a
  namespaced root, nested elements, attributes, and multiple leaf elements.
  `tests/smoke.rs::parses_basic_types_and_walks_tree` walks the whole tree
  and asserts exact tag names, attribute name/value pairs, and leaf text.
- `bench/fixtures/large_synthetic.xml` (20,000 records, ~5MB) —
  `tests/smoke.rs::survives_large_synthetic_file` parses it, confirms
  20,000 top-level `<Entry>` children, and walks all ~140,001 nodes
  depth-first without crashing.
- `valgrind --leak-check=full` on the large-file test: 0 bytes definitely or
  indirectly lost (the one "possibly lost" 48-byte block is the Rust test
  harness's own thread-local setup, not shim code — alloc/free counts are
  balanced modulo that harness overhead).

Run `cargo test --release -- --nocapture` to see this output yourself.
