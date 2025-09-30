# Simple Makefile for pwgen-cpp
# Builds a single binary from src/main.cpp with strong optimizations

# Compiler and flags
CXX ?= g++
CXXFLAGS ?= -std=c++17 -O3 -march=native -mtune=native -flto -DNDEBUG -pipe -Wall -Wextra
LDFLAGS ?= -flto
STATIC_LDFLAGS ?= -flto -static

# Paths and names
BIN := pwgen-cpp
BIN_STATIC := pwgen-cpp-static
SRC := src/main.cpp
OBJDIR := build
OBJ := $(OBJDIR)/main.o
OBJ_STATIC := $(OBJDIR)/main_static.o
GEN_HDR := src/generated_wordlists_data.hpp

WORDLISTS := wordlist_en.txt wordlist_fr.txt wordlist_de.txt

.PHONY: all clean static

all: $(BIN)

static: $(BIN_STATIC)

$(BIN): $(OBJ)
	$(CXX) $(LDFLAGS) -o $@ $^

$(BIN_STATIC): $(OBJ_STATIC)
	$(CXX) $(STATIC_LDFLAGS) -o $@ $^

# Ensure the generated header exists before compiling
$(OBJ): $(GEN_HDR)
$(OBJ_STATIC): $(GEN_HDR)

$(OBJDIR)/%.o: src/%.cpp
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(OBJDIR)/%_static.o: src/%.cpp
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Generate a header that embeds all wordlists into the binary
$(GEN_HDR): $(WORDLISTS)
	@mkdir -p $(@D)
	@echo '/* Auto-generated. Do not edit. */' > $@
	@echo '#pragma once' >> $@
	@echo 'static const char WORDS_EN[] = R"WL_EN(' >> $@
	@cat wordlist_en.txt >> $@
	@echo ')WL_EN";' >> $@
	@echo 'static const char WORDS_FR[] = R"WL_FR(' >> $@
	@cat wordlist_fr.txt >> $@
	@echo ')WL_FR";' >> $@
	@echo 'static const char WORDS_DE[] = R"WL_DE(' >> $@
	@cat wordlist_de.txt >> $@
	@echo ')WL_DE";' >> $@

clean:
	rm -rf $(OBJDIR) $(BIN) $(BIN_STATIC) $(GEN_HDR)
