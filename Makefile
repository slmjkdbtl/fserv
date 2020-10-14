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

%: src/%.c
	$(CC) $(C_FLAGS) $(LD_FLAGS) -o $@.so $^

.PHONY: run
run:
	lua demo.lua

.PHONY: clean
clean:
	rm *.so

