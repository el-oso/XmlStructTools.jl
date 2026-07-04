# Builds libpugixml_shim.so against pugixml_jll (the Yggdrasil/BinaryBuilder
# artifact for pugixml, already in the General registry) plus a standalone
# test program that exercises the shim end to end.
#
# pugixml_jll is resolved from the dedicated Julia environment defined by
# Project.toml/Manifest.toml in this directory (not the ambient/global Julia
# environment) -- that way the artifact version is pinned and the build
# doesn't depend on whatever happens to be installed in whoever's default
# environment. See README.md ("Why a dedicated Julia environment") for the
# alternative considered and why this one was picked.

CXX      ?= g++
CXXFLAGS ?= -O2 -std=c++14 -fPIC -Wall -Wextra
SONAME   := libpugixml_shim.so

PUGIXML_ARTIFACT_ROOT := $(shell julia --project=. -e 'using pugixml_jll; print(dirname(dirname(pugixml_jll.libpugixml_path)))')
PUGIXML_INC := $(PUGIXML_ARTIFACT_ROOT)/include
PUGIXML_LIB := $(PUGIXML_ARTIFACT_ROOT)/lib

.PHONY: all test clean

all: $(SONAME)

$(SONAME): shim.cpp
	$(CXX) $(CXXFLAGS) -I$(PUGIXML_INC) -shared -o $(SONAME) shim.cpp \
		-L$(PUGIXML_LIB) -lpugixml -Wl,-rpath,$(PUGIXML_LIB)

test_shim: test_shim.cpp $(SONAME)
	$(CXX) $(CXXFLAGS) -o test_shim test_shim.cpp -L. -lpugixml_shim -Wl,-rpath,'$$ORIGIN'

BASIC_FIXTURE := ../../test/test_data/generic_cases/basic_types.xml
LARGE_FIXTURE := ../fixtures/large_synthetic.xml

test: test_shim
	./test_shim $(BASIC_FIXTURE) $(LARGE_FIXTURE)

clean:
	rm -f $(SONAME) test_shim
