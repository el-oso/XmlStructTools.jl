// Standalone test/verification program for libpugixml_shim.so.
//
// Deliberately does NOT include vendor/pugixml.hpp or shim.cpp -- it only
// declares the extern "C" prototypes, exactly as a Julia ccall() consumer
// would see them, and links against the built shared library. This is the
// end-to-end check that the shim's C ABI actually works from outside its
// own translation unit.

#include <cstdio>
#include <cstdlib>
#include <cstring>

extern "C" {
    void* pugishim_parse_file(const char* path);
    void  pugishim_free_doc(void* doc);
    void* pugishim_root(void* doc);
    const char* pugishim_node_name(void* node);
    const char* pugishim_node_text(void* node);
    void* pugishim_first_child_element(void* node);
    void* pugishim_next_sibling_element(void* node);
    int   pugishim_has_element_children(void* node);
    void* pugishim_first_attribute(void* node);
    void* pugishim_next_attribute(void* attr);
    const char* pugishim_attribute_name(void* attr);
    const char* pugishim_attribute_value(void* attr);
}

static int failures = 0;

#define CHECK(cond, msg) do { \
    if (!(cond)) { std::fprintf(stderr, "FAIL: %s (%s:%d)\n", msg, __FILE__, __LINE__); failures++; } \
} while (0)

static void print_attributes(void* node, const char* label) {
    std::printf("  attributes of %s:\n", label);
    int n = 0;
    for (void* a = pugishim_first_attribute(node); a; a = pugishim_next_attribute(a)) {
        std::printf("    %s = \"%s\"\n", pugishim_attribute_name(a), pugishim_attribute_value(a));
        n++;
    }
    if (n == 0) std::printf("    (none)\n");
}

int main(int argc, char** argv) {
    if (argc < 3) {
        std::fprintf(stderr, "usage: %s <basic_types.xml> <large_synthetic.xml>\n", argv[0]);
        return 1;
    }
    const char* basic_path = argv[1];
    const char* large_path = argv[2];

    // --- basic_types.xml: structural + content checks -----------------
    void* doc = pugishim_parse_file(basic_path);
    CHECK(doc != nullptr, "parse basic_types.xml");

    void* root = pugishim_root(doc);
    CHECK(root != nullptr, "root element present");

    const char* root_name = pugishim_node_name(root);
    std::printf("root tag: %s\n", root_name);
    CHECK(std::strcmp(root_name, "TestComplexAndSimple:document") == 0, "root tag name matches");

    print_attributes(root, "root");

    std::printf("root's element children:\n");
    int child_count = 0;
    void* te1 = nullptr;
    void* te2 = nullptr;
    for (void* c = pugishim_first_child_element(root); c; c = pugishim_next_sibling_element(c)) {
        const char* name = pugishim_node_name(c);
        std::printf("  - %s (has_element_children=%d)\n", name, pugishim_has_element_children(c));
        if (std::strcmp(name, "TestElement1") == 0) te1 = c;
        if (std::strcmp(name, "TestElement2") == 0) te2 = c;
        child_count++;
    }
    CHECK(child_count == 3, "root has 3 element children");
    CHECK(te1 != nullptr, "found TestElement1");
    CHECK(te2 != nullptr, "found TestElement2");

    // TestElement2 is a leaf with text content "99A9"
    CHECK(pugishim_has_element_children(te2) == 0, "TestElement2 is a leaf");
    const char* te2_text = pugishim_node_text(te2);
    std::printf("TestElement2 text: \"%s\"\n", te2_text);
    CHECK(std::strcmp(te2_text, "99A9") == 0, "TestElement2 text matches");

    // TestElement1 has element children; walk to Element_string leaf
    CHECK(pugishim_has_element_children(te1) == 1, "TestElement1 has element children");
    void* first_leaf = pugishim_first_child_element(te1);
    const char* leaf_name = pugishim_node_name(first_leaf);
    const char* leaf_text = pugishim_node_text(first_leaf);
    std::printf("TestElement1's first child: %s = \"%s\"\n", leaf_name, leaf_text);
    print_attributes(first_leaf, leaf_name);
    CHECK(std::strcmp(leaf_name, "Element_string") == 0, "first leaf name matches");
    CHECK(std::strcmp(leaf_text, "aaaa") == 0, "first leaf text matches");

    pugishim_free_doc(doc);

    // --- large_synthetic.xml: parses without crashing, walk every entry --
    void* big_doc = pugishim_parse_file(large_path);
    CHECK(big_doc != nullptr, "parse large_synthetic.xml");
    void* big_root = pugishim_root(big_doc);
    CHECK(big_root != nullptr, "large_synthetic.xml has root element");

    long entry_count = 0;
    for (void* c = pugishim_first_child_element(big_root); c; c = pugishim_next_sibling_element(c)) {
        entry_count++;
        // touch every field of every entry to exercise the whole API on real data
        for (void* f = pugishim_first_child_element(c); f; f = pugishim_next_sibling_element(f)) {
            (void)pugishim_node_name(f);
            (void)pugishim_node_text(f);
        }
    }
    std::printf("large_synthetic.xml: %ld top-level entries\n", entry_count);
    CHECK(entry_count == 20000, "large_synthetic.xml has 20000 entries");

    pugishim_free_doc(big_doc);

    if (failures == 0) {
        std::printf("\nALL CHECKS PASSED\n");
        return 0;
    } else {
        std::printf("\n%d CHECK(S) FAILED\n", failures);
        return 1;
    }
}
