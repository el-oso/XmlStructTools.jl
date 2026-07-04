//! Exercises every extern "C" function against real fixtures, exactly the
//! way a Julia ccall caller would (raw pointers, manual free). Run with:
//!   cargo test --release -- --nocapture
use quickxml_shim::*;
use std::ffi::{CStr, CString};
use std::path::PathBuf;

fn fixture(rel: &str) -> CString {
    let mut p = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    p.push(rel);
    CString::new(p.to_str().unwrap()).unwrap()
}

unsafe fn cstr(p: *const std::os::raw::c_char) -> String {
    assert!(!p.is_null(), "unexpected null string pointer");
    unsafe { CStr::from_ptr(p) }.to_str().unwrap().to_string()
}

#[test]
fn parses_basic_types_and_walks_tree() {
    let path = fixture("../../test/test_data/generic_cases/basic_types.xml");
    let doc = quickxml_parse_file(path.as_ptr());
    assert!(!doc.is_null(), "parse_file returned null for basic_types.xml");

    let root = quickxml_root(doc);
    assert!(root >= 0);
    let root_tag = unsafe { cstr(quickxml_tag_name(doc, root)) };
    println!("root tag: {root_tag}");
    assert_eq!(root_tag, "TestComplexAndSimple:document");

    // root has 2 attrs (xsi:schemaLocation, xmlns:TestComplexAndSimple) --
    // xmlns:xsi itself is also reported as a regular attribute by quick-xml.
    let attr_count = quickxml_attr_count(doc, root);
    println!("root attr count: {attr_count}");
    for i in 0..attr_count {
        let name = unsafe { cstr(quickxml_attr_name(doc, root, i)) };
        let value = unsafe { cstr(quickxml_attr_value(doc, root, i)) };
        println!("  attr[{i}]: {name} = {value}");
    }
    assert!(attr_count >= 2);

    assert_eq!(quickxml_has_element_children(doc, root), 1);
    let child_count = quickxml_child_count(doc, root);
    println!("root child count: {child_count}");
    assert_eq!(child_count, 3); // TestElement1, TestElement2, TestElement3

    let mut child_tags = Vec::new();
    for i in 0..child_count {
        let child = quickxml_child_at(doc, root, i);
        assert!(child >= 0);
        child_tags.push(unsafe { cstr(quickxml_tag_name(doc, child)) });
    }
    println!("root children: {child_tags:?}");
    assert_eq!(child_tags, vec!["TestElement1", "TestElement2", "TestElement3"]);

    // TestElement2 is a leaf with direct text "99A9".
    let elem2 = quickxml_child_at(doc, root, 1);
    assert_eq!(quickxml_has_element_children(doc, elem2), 0);
    let elem2_text = unsafe { cstr(quickxml_text(doc, elem2)) };
    println!("TestElement2 text: {elem2_text}");
    assert_eq!(elem2_text, "99A9");

    // TestElement1 has element children, and its first child (Element_string)
    // is a leaf with text "aaaa" and no attributes.
    let elem1 = quickxml_child_at(doc, root, 0);
    assert_eq!(quickxml_has_element_children(doc, elem1), 1);
    let elem1_child0 = quickxml_child_at(doc, elem1, 0);
    let elem1_child0_tag = unsafe { cstr(quickxml_tag_name(doc, elem1_child0)) };
    let elem1_child0_text = unsafe { cstr(quickxml_text(doc, elem1_child0)) };
    println!("TestElement1/{elem1_child0_tag} text: {elem1_child0_text}");
    assert_eq!(elem1_child0_tag, "Element_string");
    assert_eq!(elem1_child0_text, "aaaa");
    assert_eq!(quickxml_attr_count(doc, elem1_child0), 0);
    assert!(quickxml_text(doc, elem1_child0) != std::ptr::null()); // sanity

    // A pure-container node (elem1) should have no direct text.
    assert!(quickxml_text(doc, elem1).is_null());

    quickxml_free(doc);
}

#[test]
fn survives_large_synthetic_file() {
    let path = fixture("../fixtures/large_synthetic.xml");
    let doc = quickxml_parse_file(path.as_ptr());
    assert!(!doc.is_null(), "parse_file returned null for large_synthetic.xml");

    let root = quickxml_root(doc);
    let root_tag = unsafe { cstr(quickxml_tag_name(doc, root)) };
    let child_count = quickxml_child_count(doc, root);
    println!("large_synthetic.xml root: {root_tag}, {child_count} top-level children");
    assert!(child_count > 0);

    // Walk the whole tree once (depth-first) to make sure nothing crashes
    // or dangles across ~20k records worth of nodes.
    let mut visited: u64 = 0;
    let mut stack = vec![root];
    while let Some(n) = stack.pop() {
        visited += 1;
        let _ = unsafe { cstr(quickxml_tag_name(doc, n)) };
        let cc = quickxml_child_count(doc, n);
        for i in 0..cc {
            stack.push(quickxml_child_at(doc, n, i));
        }
    }
    println!("visited {visited} nodes total");
    assert!(visited > 20_000);

    quickxml_free(doc);
}

#[test]
fn null_and_out_of_range_inputs_are_handled_defensively() {
    let bad = -1i32;
    assert!(quickxml_tag_name(std::ptr::null(), 0).is_null());
    assert_eq!(quickxml_child_count(std::ptr::null(), 0), 0);
    assert_eq!(quickxml_root(std::ptr::null()), -1);

    let path = fixture("../../test/test_data/generic_cases/basic_types.xml");
    let doc = quickxml_parse_file(path.as_ptr());
    assert!(!doc.is_null());
    assert!(quickxml_tag_name(doc, bad).is_null());
    assert!(quickxml_tag_name(doc, 99999).is_null());
    assert_eq!(quickxml_child_at(doc, bad, 0), -1);
    quickxml_free(doc);

    // Freeing null must be a safe no-op.
    quickxml_free(std::ptr::null_mut());
}
