# wengwengweng

CC := clang

C_FLAGS += -Wall
C_FLAGS += -Wpedantic
C_FLAGS += -std=c99
C_FLAGS += -I ext/inc

ifdef RELEASE
C_FLAGS += -O3
endif

LD_FLAGS += -L ext/lib
LD_FLAGS += -l lua
LD_FLAGS += -l m

BIN_TARGET := build/fserv

SRC_FILES := $(wildcard src/*.c)

INSTALL_TOP := /usr/local
INSTALL_BIN := $(INSTALL_TOP)/bin
INSTALL_INC := $(INSTALL_TOP)/include
INSTALL_LIB := $(INSTALL_TOP)/lib

$(BIN_TARGET): $(SRC_FILES) res
	@mkdir -p build
	$(CC) $(C_FLAGS) $(LD_FLAGS) -o $(BIN_TARGET) $(SRC_FILES)

.PHONY: run
run: $(BIN_TARGET)
	$(BIN_TARGET) demo.lua

.PHONY: res
res:
	rm -rf src/res
	sh scripts/cres.sh res src/res

.PHONY: clean
clean:
	rm -rf build

.PHONY: install
install: $(BIN_TARGET)
	install $(BIN_TARGET) $(INSTALL_BIN)

