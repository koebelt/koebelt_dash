# Host tests for the platform-independent core.
CXXFLAGS ?= -std=c++17 -Wall -Wextra -Wno-unused-parameter -g
SRC = ../src/KoebeltLink.cpp ../src/KoebeltLink_platform.cpp host_test.cpp guide_snippets.cpp

run: host_test
	./host_test

host_test: $(SRC) ../src/*.h shim/*.h
	$(CXX) $(CXXFLAGS) -Ishim -I../src $(SRC) -o $@

clean:
	rm -f host_test
.PHONY: run clean
