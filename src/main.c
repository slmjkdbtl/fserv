// wengwengweng

#include <stdbool.h>
#include <string.h>
#include <limits.h>
#include <unistd.h>
#include <stdlib.h>

#include <lua/lua.h>
#include <lua/lualib.h>
#include <lua/lauxlib.h>

#include "res/httph.lua.h"
#include "res/json.lua.h"
#include "res/std.lua.h"

int luaopen_fs(lua_State *L);
int luaopen_http(lua_State *L);

int luaopen_json(lua_State *L) {
	json_lua[json_lua_len] = '\0';
	luaL_dostring(L, json_lua);
	return 1;
}

int luaopen_httph(lua_State *L) {
	httph_lua[httph_lua_len] = '\0';
	luaL_dostring(L, httph_lua);
	return 1;
}

void run(const char *path) {

	lua_State *L = luaL_newstate();
	luaL_openlibs(L);

	luaL_requiref(L, "fs", luaopen_fs, true);
	luaL_requiref(L, "http", luaopen_http, true);
	luaL_requiref(L, "json", luaopen_json, true);
	luaL_requiref(L, "httph", luaopen_httph, true);

	std_lua[std_lua_len] = '\0';
	luaL_dostring(L, std_lua);

	if (luaL_dofile(L, path) != LUA_OK) {
		fprintf(stderr, "%s\n", lua_tostring(L, -1));
	}

	lua_close(L);

}

int main(int argc, char **argv) {
	if (argc >= 2) {
		run(argv[1]);
	}
}

