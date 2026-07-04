// Minimal C ABI shim over pugixml's C++ DOM, for benchmarking from Julia via ccall.
// Not a production wrapper: just enough surface to parse a file, walk element
// children, read attributes, and read leaf text content.
//
// Handle model:
//   - pugishim_parse_file returns an owning pugi::xml_document* (caller must
//     call pugishim_free_doc exactly once on it).
//   - All node/attribute handles are pugixml's own internal pointers
//     (xml_node_struct*/xml_attribute_struct*), obtained via xml_node's public
//     internal_object()/xml_node(xml_node_struct*) round-trip. They are views
//     into the document's memory pool: they do NOT need to be freed, and they
//     become invalid once the owning document is freed.
//   - nullptr means "no such node/attribute" (empty/end-of-iteration/failure).

#include "vendor/pugixml.hpp"
#include <cstring>

extern "C" {

// --- Document lifecycle ------------------------------------------------

// Parse the file at `path`. Returns an opaque xml_document* handle, or
// nullptr if the file could not be parsed (bad path, malformed XML, ...).
void* pugishim_parse_file(const char* path) {
    pugi::xml_document* doc = new pugi::xml_document();
    pugi::xml_parse_result result = doc->load_file(path);
    if (!result) {
        delete doc;
        return nullptr;
    }
    return doc;
}

// Free a document handle returned by pugishim_parse_file. Invalidates every
// node/attribute handle obtained from it.
void pugishim_free_doc(void* doc) {
    delete static_cast<pugi::xml_document*>(doc);
}

// --- Node access ---------------------------------------------------------

// The document's root element (e.g. <document> in <?xml?><document>...),
// or nullptr if the document has no root element.
void* pugishim_root(void* doc) {
    pugi::xml_node root = static_cast<pugi::xml_document*>(doc)->document_element();
    return root.internal_object();
}

// Tag/element name, e.g. "TestElement1". Owned by the document; valid until
// the document is freed. Never null (empty string if the node has no name).
const char* pugishim_node_name(void* node) {
    return pugi::xml_node(static_cast<pugi::xml_node_struct*>(node)).name();
}

// Direct text content of a node (pugixml's child_value(): the value of the
// first text/CDATA child, NOT concatenated across all descendants). Owned by
// the document; valid until the document is freed. Never null ("" if none).
const char* pugishim_node_text(void* node) {
    return pugi::xml_node(static_cast<pugi::xml_node_struct*>(node)).child_value();
}

// First ELEMENT child of `node` (skips text/comment/PI/declaration nodes),
// or nullptr if it has none.
void* pugishim_first_child_element(void* node) {
    pugi::xml_node n = pugi::xml_node(static_cast<pugi::xml_node_struct*>(node)).first_child();
    while (n && n.type() != pugi::node_element) {
        n = n.next_sibling();
    }
    return n.internal_object();
}

// Next ELEMENT sibling after `node` (skips text/comment/PI/declaration
// nodes), or nullptr if there is none.
void* pugishim_next_sibling_element(void* node) {
    pugi::xml_node n = pugi::xml_node(static_cast<pugi::xml_node_struct*>(node)).next_sibling();
    while (n && n.type() != pugi::node_element) {
        n = n.next_sibling();
    }
    return n.internal_object();
}

// 1 if `node` has at least one element child, 0 otherwise (i.e. it is a leaf).
int pugishim_has_element_children(void* node) {
    return pugishim_first_child_element(node) != nullptr ? 1 : 0;
}

// --- Attribute access ------------------------------------------------------

// First attribute of `node`, or nullptr if it has none.
void* pugishim_first_attribute(void* node) {
    pugi::xml_attribute a = pugi::xml_node(static_cast<pugi::xml_node_struct*>(node)).first_attribute();
    return a.internal_object();
}

// Next attribute after `attr`, or nullptr if there is none.
void* pugishim_next_attribute(void* attr) {
    pugi::xml_attribute a = pugi::xml_attribute(static_cast<pugi::xml_attribute_struct*>(attr)).next_attribute();
    return a.internal_object();
}

// Attribute name, e.g. "xsi:schemaLocation". Owned by the document; valid
// until the document is freed. Never null.
const char* pugishim_attribute_name(void* attr) {
    return pugi::xml_attribute(static_cast<pugi::xml_attribute_struct*>(attr)).name();
}

// Attribute value. Owned by the document; valid until the document is freed.
// Never null.
const char* pugishim_attribute_value(void* attr) {
    return pugi::xml_attribute(static_cast<pugi::xml_attribute_struct*>(attr)).value();
}

} // extern "C"
