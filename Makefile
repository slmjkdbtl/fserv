# wengwengweng

CC := cc

CFLAGS += -Wall
CFLAGS += -Wpedantic
CFLAGS += -std=c99
CFLAGS += -Iext

ifdef RELEASE
CFLAGS += -O3
endif

LDLIBS += -llua
LDLIBS += -lm

BIN := build/fserv
SRC_FILES := $(wildcard src/*.c)
PREFIX := /usr/local

$(BIN): $(SRC_FILES) res
	@mkdir -p build
	$(CC) $(CFLAGS) $(LDFLAGS) $(LDLIBS) -o $(BIN) $(SRC_FILES)

.PHONY: run
run: $(BIN)
	$(BIN)

.PHONY: run-lua
run-lua: $(BIN)
	$(BIN) demo.lua

.PHONY: res
res:
	rm -rf src/res
	sh scripts/cres.sh res src/res

.PHONY: clean
clean:
	rm -rf build

.PHONY: install
install: $(BIN)
	install -m 0755 $(BIN) $(PREFIX)/bin

