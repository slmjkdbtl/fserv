# wengwengweng

CC := cc

C_FLAGS += -Wall
C_FLAGS += -Wpedantic
C_FLAGS += -std=c99
C_FLAGS += -I ext
C_FLAGS += -shared
C_FLAGS += -fPIC

ifeq ($(MODE),release)
C_FLAGS += -O3
endif

LD_FLAGS += -l lua

.PHONY: all
all: build/fs.so build/http.so build/httph.lua build/json.lua

build/%.so: src/%.c
	@mkdir -p build
	$(CC) $(C_FLAGS) $(LD_FLAGS) -o $@ $^

build/%.lua: src/%.lua
	@mkdir -p build
	cp $^ $@

.PHONY: run
run:
	lua demo.lua

.PHONY: clean
clean:
	rm -rf build

.PHONY: install
install: all
ifndef LUA_PATH
	$(error LUA_PATH undefined)
endif
ifndef LUA_CPATH
	$(error LUA_CPATH undefined)
endif
	cp build/*.lua $(subst ?.lua,,$(LUA_PATH))
	cp build/*.so $(subst ?.so,,$(LUA_CPATH))

