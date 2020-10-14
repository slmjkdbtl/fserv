// wengwengweng

#include <lua/lua.h>
#include <lua/lualib.h>
#include <lua/lauxlib.h>

#define HTTPSERVER_IMPL
#include <httpserver.h>

lua_State *lua;
int handler_ref;

void handler(http_request_t *req) {

	lua_settop(lua, 0);
	lua_rawgeti(lua, LUA_REGISTRYINDEX, handler_ref);

	if (lua_isfunction(lua, -1)) {

		http_string_t target = http_request_target(req);
		char url[256] = "";

		strncpy(url, target.buf, target.len);

		lua_newtable(lua);
		lua_pushstring(lua, url);
		lua_setfield(lua, -2, "url");

		if (lua_pcall(lua, 1, 1, 0) != LUA_OK) {
			fprintf(stderr, "%s\n", lua_tostring(lua, -1));
		}

		if (lua_type(lua, -1) == LUA_TTABLE) {

			http_response_t *res = http_response_init();

			int status_t = lua_getfield(lua, -1, "status");

			if (status_t == LUA_TNUMBER) {
				int status = luaL_checknumber(lua, -1);
				http_response_status(res, status);
			}

			lua_pop(lua, 1);

			int body_t = lua_getfield(lua, -1, "body");

			if (body_t == LUA_TSTRING) {
				const char *body = luaL_checkstring(lua, -1);
				http_response_body(res, body, strlen(body));
			} else if (body_t == LUA_TUSERDATA) {
				void *data = lua_touserdata(lua, -1);
				int size = lua_rawlen(lua, -1);
				http_response_body(res, data, size);
			}

			lua_pop(lua, 1);

			int headers_t = lua_getfield(lua, -1, "headers");

			if (headers_t == LUA_TTABLE) {
				lua_pushnil(lua);
				while (lua_next(lua, -2) != 0) {
					const char *k = luaL_checkstring(lua, -2);
					const char *v = luaL_checkstring(lua, -1);
					lua_pop(lua, 1);
					http_response_header(res, k, v);
				}
			}

			lua_pop(lua, 1);

			http_respond(req, res);

		}

		lua_pop(lua, 1);

	}

}

static int l_listen(lua_State *L) {
	lua = L;
	int port = luaL_checkinteger(L, 1);
	handler_ref = luaL_ref(L, LUA_REGISTRYINDEX);
	http_server_t* server = http_server_init(port, handler);
	http_server_listen(server);
	return 0;
}

static const luaL_Reg funcs[] = {
	{ "listen", l_listen, },
	{ NULL, NULL, }
};

int luaopen_http(lua_State *L) {
	luaL_newlib(L, funcs);
	return 1;
}

