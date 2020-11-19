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

	if (!file) {
		return 0;
	}

	fseek(file, 0, SEEK_END);
	size_t size = ftell(file);
	fseek(file, 0, SEEK_SET);

	char *buffer = malloc(size + 1);
	fread(buffer, 1, size, file);

	buffer[size] = '\0';

	fclose(file);

	lua_pushstring(L, buffer);

	return 1;

}

static int l_read_bytes(lua_State *L) {

	const char *path = luaL_checkstring(L, 1);
	FILE *file = fopen(path, "rb");

	if (!file) {
		return 0;
	}

	fseek(file, 0, SEEK_END);
	size_t size = ftell(file);
	fseek(file, 0, SEEK_SET);

	void *buf = lua_newuserdata(L, size);
	fread(buf, 1, size, file);

	fclose(file);

	return 1;

}

static int l_read_dir(lua_State *L) {

	const char *path = luaL_checkstring(L, 1);
	struct dirent *dp;
	int count = 0;

	DIR *dir = opendir(path);

	if (!dir) {
		return 0;
	}

	lua_newtable(L);

	while (dir) {
		if ((dp = readdir(dir)) != NULL) {
			if (dp->d_name[0] != '.') {
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

static int l_is_file(lua_State *L) {
	const char *path = luaL_checkstring(L, 1);
	struct stat sb;
	bool is = stat(path, &sb) == 0 && S_ISREG(sb.st_mode);
	lua_pushboolean(L, is);
	return 1;
}

static int l_is_dir(lua_State *L) {
	const char *path = luaL_checkstring(L, 1);
	struct stat sb;
	bool is = stat(path, &sb) == 0 && S_ISDIR(sb.st_mode);
	lua_pushboolean(L, is);
	return 1;
}

static int l_extname(lua_State *L) {
	const char *path = luaL_checkstring(L, 1);
	const char *dot = strrchr(path, '.');
	if (!dot) {
		return 0;
	}
	lua_pushstring(L, dot + 1);
	return 1;
}

static int l_base64(lua_State *L) {

	const char *path = luaL_checkstring(L, 1);
	FILE *file = fopen(path, "rb");

	if (!file) {
		return 0;
	}

	fseek(file, 0, SEEK_END);
	size_t size = ftell(file);
	fseek(file, 0, SEEK_SET);

// 	unsigned char *buf = malloc(size);
// 	fread(buf, 1, size, file);

	// TODO: using base64 cmd for now, ugly don't look

	fclose(file);

	char cmd_buf[1024];
	sprintf(cmd_buf, "base64 %s", path);
	char *buf = malloc(size * 1.5);
	FILE *pf;

	if ((pf = popen(cmd_buf, "r")) == NULL) {
		return 0;
	}

	while (fgets(buf, size * 1.5, pf) != NULL);

	if (pclose(pf)) {
		return 0;
	}

	lua_pushstring(L, buf);

	return 1;

}

static const luaL_Reg funcs[] = {
	{ "read_text", l_read_text, },
	{ "read_bytes", l_read_bytes, },
	{ "read_dir", l_read_dir, },
	{ "is_file", l_is_file, },
	{ "is_dir", l_is_dir, },
	{ "extname", l_extname, },
	{ "base64", l_base64, },
	{ NULL, NULL, }
};

int luaopen_fs(lua_State *L) {
	luaL_newlib(L, funcs);
	return 1;
}

