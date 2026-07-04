//! Minimal C ABI shim over quick-xml, for benchmarking against LightXML/EzXML
//! from Julia. Not a production wrapper: parses a whole file into an
//! in-memory element tree (arena of nodes, parent points at children by
//! index), then exposes read-only accessors as `extern "C" fn`s.
//!
//! Scope (per bench spec): elements + attributes + direct leaf text only.
//! Comments/PIs/CDATA/mixed content are not modeled. See README.md for the
//! full function list and lifetime rules.

use quick_xml::events::{BytesStart, Event};
use quick_xml::reader::Reader;
use std::ffi::{c_char, CStr, CString};
use std::ptr;

/// One element node. `children` holds indices of *element* children only —
/// text events never get their own node, they fold into `text` on the
/// current leaf.
struct QxNode {
    tag: CString,
    attrs: Vec<(CString, CString)>,
    text: Option<CString>,
    children: Vec<i32>,
}

/// The parsed document: an arena of nodes plus the root index. Handed to
/// Julia as an opaque `*mut QxDocument` (Box::into_raw). All CStrings here
/// are owned by this struct, so every pointer returned to the caller is
/// valid exactly as long as this Document hasn't been freed.
pub struct QxDocument {
    nodes: Vec<QxNode>,
    root: i32,
}

// ---- build-time-only staging types (owned Strings, converted to CString once at the end) ----

struct BuildNode {
    tag: String,
    attrs: Vec<(String, String)>,
    text: Option<String>,
    children: Vec<i32>,
}

/// Replace embedded NULs (illegal in a C string) so CString::new can't fail
/// on attacker- or generator-controlled input.
fn safe_cstring(s: &str) -> CString {
    if s.as_bytes().contains(&0) {
        CString::new(s.replace('\0', "")).unwrap_or_default()
    } else {
        // SAFETY: just checked there is no interior NUL byte.
        CString::new(s).unwrap()
    }
}

fn push_node(nodes: &mut Vec<BuildNode>, start: &BytesStart) -> i32 {
    let tag = String::from_utf8_lossy(start.name().as_ref()).into_owned();
    let mut attrs = Vec::new();
    for attr in start.attributes().flatten() {
        let key = String::from_utf8_lossy(attr.key.as_ref()).into_owned();
        let val = attr
            .unescape_value()
            .map(|c| c.into_owned())
            .unwrap_or_default();
        attrs.push((key, val));
    }
    nodes.push(BuildNode {
        tag,
        attrs,
        text: None,
        children: Vec::new(),
    });
    (nodes.len() - 1) as i32
}

/// Parse `path` into a tree. Returns null on any I/O/parse error.
///
/// # Safety (C ABI)
/// `path` must be a valid null-terminated UTF-8 C string.
#[unsafe(no_mangle)]
pub extern "C" fn quickxml_parse_file(path: *const c_char) -> *mut QxDocument {
    if path.is_null() {
        return ptr::null_mut();
    }
    // SAFETY: caller-provided C string; validated non-null above and
    // to_str() below rejects anything not valid UTF-8/not null-terminated.
    let path_str = match unsafe { CStr::from_ptr(path) }.to_str() {
        Ok(s) => s,
        Err(_) => return ptr::null_mut(),
    };

    let mut reader = match Reader::from_file(path_str) {
        Ok(r) => r,
        Err(_) => return ptr::null_mut(),
    };
    // ponytail: default whitespace handling is fine — insignificant
    // whitespace-only text is dropped by the trim-on-append below, no
    // reader config tweaks needed.

    let mut nodes: Vec<BuildNode> = Vec::new();
    let mut stack: Vec<i32> = Vec::new();
    let mut buf: Vec<u8> = Vec::new();
    let mut root: i32 = -1;

    loop {
        let event = match reader.read_event_into(&mut buf) {
            Ok(e) => e,
            Err(_) => return ptr::null_mut(), // malformed XML: bail, nothing handed out yet
        };
        match event {
            Event::Eof => break,
            Event::Start(e) => {
                let idx = push_node(&mut nodes, &e);
                if let Some(&parent) = stack.last() {
                    nodes[parent as usize].children.push(idx);
                } else if root == -1 {
                    root = idx;
                }
                stack.push(idx);
            }
            Event::Empty(e) => {
                let idx = push_node(&mut nodes, &e);
                if let Some(&parent) = stack.last() {
                    nodes[parent as usize].children.push(idx);
                } else if root == -1 {
                    root = idx;
                }
                // no stack push: <e/> has no children and no text
            }
            Event::End(_) => {
                stack.pop();
            }
            Event::Text(e) => {
                if let Some(&top) = stack.last() {
                    if let Ok(txt) = e.unescape() {
                        let trimmed = txt.trim();
                        if !trimmed.is_empty() {
                            let node = &mut nodes[top as usize];
                            match &mut node.text {
                                Some(existing) => {
                                    existing.push(' ');
                                    existing.push_str(trimmed);
                                }
                                None => node.text = Some(trimmed.to_string()),
                            }
                        }
                    }
                }
            }
            // Comment/PI/Decl/CData/DocType: out of scope for this shim.
            _ => {}
        }
        buf.clear();
    }

    if root == -1 {
        return ptr::null_mut(); // no root element found (empty/invalid doc)
    }

    let final_nodes: Vec<QxNode> = nodes
        .into_iter()
        .map(|n| QxNode {
            tag: safe_cstring(&n.tag),
            attrs: n
                .attrs
                .into_iter()
                .map(|(k, v)| (safe_cstring(&k), safe_cstring(&v)))
                .collect(),
            text: n.text.map(|t| safe_cstring(&t)),
            children: n.children,
        })
        .collect();

    Box::into_raw(Box::new(QxDocument {
        nodes: final_nodes,
        root,
    }))
}

/// Free a document returned by `quickxml_parse_file`. Passing null is a
/// no-op. Double-free / use-after-free is on the caller, same as `free(3)`.
///
/// # Safety (C ABI)
/// `doc` must be either null or a still-valid pointer previously returned by
/// `quickxml_parse_file` that hasn't already been freed.
#[unsafe(no_mangle)]
pub extern "C" fn quickxml_free(doc: *mut QxDocument) {
    if doc.is_null() {
        return;
    }
    // SAFETY: reconstructs the Box from a pointer we handed out via
    // Box::into_raw; dropping it here is the one and only free.
    unsafe {
        drop(Box::from_raw(doc));
    }
}

/// Borrow the document. None on null pointer.
///
/// # Safety
/// `doc` must be null or a live pointer from `quickxml_parse_file`.
unsafe fn doc_ref<'a>(doc: *const QxDocument) -> Option<&'a QxDocument> {
    if doc.is_null() {
        None
    } else {
        // SAFETY: non-null, and caller of this unsafe fn guarantees it's a
        // live pointer from quickxml_parse_file.
        Some(unsafe { &*doc })
    }
}

fn node_ref(doc: &QxDocument, node: i32) -> Option<&QxNode> {
    if node < 0 {
        return None;
    }
    doc.nodes.get(node as usize)
}

/// Root element's node index, or -1 if `doc` is null.
#[unsafe(no_mangle)]
pub extern "C" fn quickxml_root(doc: *const QxDocument) -> i32 {
    match unsafe { doc_ref(doc) } {
        Some(d) => d.root,
        None => -1,
    }
}

/// Number of element children of `node` (0 if node/doc invalid).
#[unsafe(no_mangle)]
pub extern "C" fn quickxml_child_count(doc: *const QxDocument, node: i32) -> i32 {
    let Some(d) = (unsafe { doc_ref(doc) }) else {
        return 0;
    };
    match node_ref(d, node) {
        Some(n) => n.children.len() as i32,
        None => 0,
    }
}

/// The `idx`-th element child of `node` (0-based). -1 if out of range.
#[unsafe(no_mangle)]
pub extern "C" fn quickxml_child_at(doc: *const QxDocument, node: i32, idx: i32) -> i32 {
    let Some(d) = (unsafe { doc_ref(doc) }) else {
        return -1;
    };
    let Some(n) = node_ref(d, node) else {
        return -1;
    };
    if idx < 0 {
        return -1;
    }
    n.children.get(idx as usize).copied().unwrap_or(-1)
}

/// Tag/element name of `node`, e.g. `"Foo"` for `<Foo>`. Null if node/doc
/// invalid. Valid only until `doc` is freed (owned by the arena, never
/// copied out).
#[unsafe(no_mangle)]
pub extern "C" fn quickxml_tag_name(doc: *const QxDocument, node: i32) -> *const c_char {
    let Some(d) = (unsafe { doc_ref(doc) }) else {
        return ptr::null();
    };
    match node_ref(d, node) {
        Some(n) => n.tag.as_ptr(),
        None => ptr::null(),
    }
}

/// Number of attributes on `node`.
#[unsafe(no_mangle)]
pub extern "C" fn quickxml_attr_count(doc: *const QxDocument, node: i32) -> i32 {
    let Some(d) = (unsafe { doc_ref(doc) }) else {
        return 0;
    };
    match node_ref(d, node) {
        Some(n) => n.attrs.len() as i32,
        None => 0,
    }
}

/// Name of the `idx`-th attribute (0-based). Null if out of range. Same
/// lifetime rule as `quickxml_tag_name`.
#[unsafe(no_mangle)]
pub extern "C" fn quickxml_attr_name(doc: *const QxDocument, node: i32, idx: i32) -> *const c_char {
    let Some(d) = (unsafe { doc_ref(doc) }) else {
        return ptr::null();
    };
    let Some(n) = node_ref(d, node) else {
        return ptr::null();
    };
    if idx < 0 {
        return ptr::null();
    }
    match n.attrs.get(idx as usize) {
        Some((k, _)) => k.as_ptr(),
        None => ptr::null(),
    }
}

/// Value of the `idx`-th attribute (0-based). Null if out of range. Same
/// lifetime rule as `quickxml_tag_name`.
#[unsafe(no_mangle)]
pub extern "C" fn quickxml_attr_value(doc: *const QxDocument, node: i32, idx: i32) -> *const c_char {
    let Some(d) = (unsafe { doc_ref(doc) }) else {
        return ptr::null();
    };
    let Some(n) = node_ref(d, node) else {
        return ptr::null();
    };
    if idx < 0 {
        return ptr::null();
    }
    match n.attrs.get(idx as usize) {
        Some((_, v)) => v.as_ptr(),
        None => ptr::null(),
    }
}

/// Direct text content of `node` (e.g. `<Foo>bar</Foo>` -> "bar"). Null if
/// the node has no text (e.g. it only has element children, or is empty).
/// Same lifetime rule as `quickxml_tag_name`.
#[unsafe(no_mangle)]
pub extern "C" fn quickxml_text(doc: *const QxDocument, node: i32) -> *const c_char {
    let Some(d) = (unsafe { doc_ref(doc) }) else {
        return ptr::null();
    };
    match node_ref(d, node).and_then(|n| n.text.as_ref()) {
        Some(t) => t.as_ptr(),
        None => ptr::null(),
    }
}

/// 1 if `node` has at least one element child, 0 otherwise (also 0 for
/// invalid node/doc).
#[unsafe(no_mangle)]
pub extern "C" fn quickxml_has_element_children(doc: *const QxDocument, node: i32) -> i32 {
    let Some(d) = (unsafe { doc_ref(doc) }) else {
        return 0;
    };
    match node_ref(d, node) {
        Some(n) if !n.children.is_empty() => 1,
        _ => 0,
    }
}
