// wengwengweng

#include <sys/stat.h>
#include <unistd.h>
#include <dirent.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>

#include <lua/lua.h>
#include <lua/lualib.h>
#include <lua/lauxlib.h>

static int l_read_text(lua_State *L) {

	const char *path = luaL_checkstring(L, 1);
	FILE *file = fopen(path, "r");

	fseek(file, 0, SEEK_END);
	size_t size = ftell(file);
	fseek(file, 0, SEEK_SET);

	char *buffer = malloc(size + 1);
	size_t r_size = fread(buffer, 1, size, file);

	buffer[size] = '\0';

	fclose(file);

	lua_pushstring(L, buffer);

	return 1;

}

static int l_read_bytes(lua_State *L) {

	const char *path = luaL_checkstring(L, 1);
	FILE *file = fopen(path, "rb");

	fseek(file, 0, SEEK_END);
	size_t size = ftell(file);
	fseek(file, 0, SEEK_SET);

	void *buf = lua_newuserdata(L, size);
	size_t r_size = fread(buf, 1, size, file);

	fclose(file);

	return 1;

}

static int l_read_dir(lua_State *L) {

	const char *path = luaL_checkstring(L, 1);
	struct dirent *dp;
	int count = 0;

	DIR *dir = opendir(path);

	lua_newtable(L);

	while (dir) {
		if ((dp = readdir(dir)) != NULL) {
			if (strcmp(dp->d_name, ".") != 0 && strcmp(dp->d_name, "..") != 0) {
				lua_pushnumber(L, count + 1);
				lua_pushstring(L, dp->d_name);
				lua_settable(L, -3);
				count += 1;
			}
		} else {
			closedir(dir);
			dir = NULL;
		}
	}

	return 1;

}

int l_is_file(lua_State *L) {
	const char *path = luaL_checkstring(L, 1);
	struct stat sb;
	bool is = stat(path, &sb) == 0 && S_ISREG(sb.st_mode);
	lua_pushboolean(L, is);
	return 1;
}

int l_is_dir(lua_State *L) {
	const char *path = luaL_checkstring(L, 1);
	struct stat sb;
	bool is = stat(path, &sb) == 0 && S_ISDIR(sb.st_mode);
	lua_pushboolean(L, is);
	return 1;
}

int l_extname(lua_State *L) {
	const char *path = luaL_checkstring(L, 1);
	const char *dot = strrchr(path, '.');
	lua_pushstring(L, dot + 1);
	return 1;
}

static const luaL_Reg funcs[] = {
	{ "read_text", l_read_text, },
	{ "read_bytes", l_read_bytes, },
	{ "read_dir", l_read_dir, },
	{ "is_file", l_is_file, },
	{ "is_dir", l_is_dir, },
	{ "extname", l_extname, },
	{ NULL, NULL, }
};

int luaopen_fs(lua_State *L) {
	luaL_newlib(L, funcs);
	return 1;
}

