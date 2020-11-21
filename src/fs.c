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

static int l_write_text(lua_State *L) {

	const char *path = luaL_checkstring(L, 1);
	const char *text = luaL_checkstring(L, 2);
	FILE *file = fopen(path, "w");

	if (!file) {
		return 0;
	}

	size_t size = strlen(text);

	fwrite(text, 1, size, file);
	fclose(file);

	return 0;

}

static int l_read_text(lua_State *L) {

	const char *path = luaL_checkstring(L, 1);
	FILE *file = fopen(path, "r");

	if (!file) {
		return 0;
	}

	fseek(file, 0, SEEK_END);
	size_t size = ftell(file);
	fseek(file, 0, SEEK_SET);

	char *text = malloc(size + 1);
	fread(text, 1, size, file);

	text[size] = '\0';

	fclose(file);

	lua_pushstring(L, text);
	free(text);

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

static char base64_table[] = {
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
	'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
	'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
	'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
	'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
	'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
	'w', 'x', 'y', 'z', '0', '1', '2', '3',
	'4', '5', '6', '7', '8', '9', '+', '/',
};

static int mod_table[] = { 0, 2, 1, };

static char *base64_encode(const char *input, size_t isize, size_t *osize) {

	*osize = 4 * ((isize + 2) / 3);

	char *output = malloc(*osize);
	if (output == NULL) return NULL;

	for (int i = 0, j = 0; i < isize;) {

		uint32_t octet_a = i < isize ? (unsigned char)input[i++] : 0;
		uint32_t octet_b = i < isize ? (unsigned char)input[i++] : 0;
		uint32_t octet_c = i < isize ? (unsigned char)input[i++] : 0;

		uint32_t triple = (octet_a << 0x10) + (octet_b << 0x08) + octet_c;

		output[j++] = base64_table[(triple >> 3 * 6) & 0x3F];
		output[j++] = base64_table[(triple >> 2 * 6) & 0x3F];
		output[j++] = base64_table[(triple >> 1 * 6) & 0x3F];
		output[j++] = base64_table[(triple >> 0 * 6) & 0x3F];
	}

	for (int i = 0; i < mod_table[isize % 3]; i++) {
		output[*osize - 1 - i] = '=';
	}

	*osize = *osize -2 + mod_table[isize % 3];
	output[*osize] = 0;

	return output;

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

	unsigned char *bytes = malloc(size);
	fread(bytes, 1, size, file);
	fclose(file);

	size_t osize;
	char *data = base64_encode(bytes, size, &osize);

	lua_pushstring(L, data);
	free(data);
	free(bytes);

	return 1;

}

static const luaL_Reg funcs[] = {
	{ "write_text", l_write_text, },
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

