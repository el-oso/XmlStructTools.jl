# Builds libpugixml_shim.so (vendored pugixml 1.14 statically folded in, so
# there's no runtime dependency on any system libpugixml.so version) plus a
# standalone test program that exercises the shim end to end.

CXX      ?= g++
CXXFLAGS ?= -O2 -std=c++14 -fPIC -Wall -Wextra
SONAME   := libpugixml_shim.so

.PHONY: all test clean

all: $(SONAME)

$(SONAME): shim.cpp vendor/pugixml.cpp vendor/pugixml.hpp vendor/pugiconfig.hpp
	$(CXX) $(CXXFLAGS) -shared -o $(SONAME) shim.cpp vendor/pugixml.cpp

test_shim: test_shim.cpp $(SONAME)
	$(CXX) $(CXXFLAGS) -o test_shim test_shim.cpp -L. -lpugixml_shim -Wl,-rpath,'$$ORIGIN'

test: test_shim
	./test_shim

clean:
	rm -f $(SONAME) test_shim
