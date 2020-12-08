// wengwengweng

#include <stdbool.h>
#include <stdio.h>
#include <strings.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include <lua/lua.h>
#include <lua/lualib.h>
#include <lua/lauxlib.h>

#define BUF_SIZE 1024
#define POLL_SIZE 32

char const * status_text[] = {
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",

	//100s
	"Continue", "Switching Protocols", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",

	//200s
	"OK", "Created", "Accepted", "Non-Authoritative Information", "No Content",
	"Reset Content", "Partial Content", "", "", "",

	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",

	//300s
	"Multiple Choices", "Moved Permanently", "Found", "See Other", "Not Modified",
	"Use Proxy", "", "Temporary Redirect", "", "",

	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",

	//400s
	"Bad Request", "Unauthorized", "Payment Required", "Forbidden", "Not Found",
	"Method Not Allowed", "Not Acceptable", "Proxy Authentication Required",
	"Request Timeout", "Conflict",

	"Gone", "Length Required", "", "Payload Too Large", "", "", "", "", "", "",

	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",

	//500s
	"Internal Server Error", "Not Implemented", "Bad Gateway", "Service Unavailable",
	"Gateway Timeout", "", "", "", "", ""

	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "",
};

void print_stack(lua_State *L) {
	for (int i = 1; i <= lua_gettop(L); i++) {
		printf("%d: %s\n", i, lua_typename(L, lua_type(L, i)));
	}
}

void push_req(lua_State *L, char *msg) {

	lua_newtable(L);

	char *cursor = msg;

	// method
	char *method_start = cursor;
	cursor = strchr(cursor, ' ');
	lua_pushlstring(L, method_start, cursor - method_start);
	lua_setfield(L, -2, "method");
	cursor++;

	// target
	char *target_start = cursor;
	cursor = strchr(cursor, ' ');
	lua_pushlstring(L, target_start, cursor - target_start);
	lua_setfield(L, -2, "target");
	cursor++;

	// version
	char *version_start = cursor;
	cursor = strchr(cursor, '\r');
	lua_pushlstring(L, version_start, cursor - version_start);
	lua_setfield(L, -2, "version");
	cursor++;
	cursor++;

	lua_newtable(L);

	// TODO: deal with empty header
	while (1) {

		// key
		char *key_start = cursor;
		cursor = strchr(cursor, ':');
		lua_pushlstring(L, key_start, cursor - key_start);
		cursor++;
		cursor++;

		// val
		char *val_start = cursor;
		cursor = strchr(cursor, '\r');
		lua_pushlstring(L, val_start, cursor - val_start);
		cursor++;
		cursor++;

		lua_settable(L, -3);

		if (cursor[0] == '\r') {
			cursor++;
			cursor++;
			break;
		}

	}

	lua_setfield(L, -2, "headers");

	// TODO: body

}

char *parse_res(lua_State *L) {

	char *msg = calloc(BUF_SIZE, 1);
	int cursor = 0;

	lua_getfield(L, -1, "status");
	int status = luaL_checknumber(L, -1);
	lua_pop(L, 1);

	cursor += sprintf(msg + cursor, "HTTP/1.1 %d %s\r\n", status, status_text[status]);

	int headers_t = lua_getfield(L, -1, "headers");
	if (headers_t == LUA_TTABLE) {
		lua_pushnil(L);
		while (lua_next(L, -2) != 0) {
			const char *k = luaL_checkstring(L, -2);
			const char *v = luaL_checkstring(L, -1);
			cursor += sprintf(msg + cursor, "%s: %s\r\n", k, v);
			lua_pop(L, 1);
		}
	}
	lua_pop(L, 1);

	cursor += sprintf(msg + cursor, "\r\n");

	int body_t = lua_getfield(L, -1, "body");
	if (body_t == LUA_TSTRING) {
		const char *body = luaL_checkstring(L, -1);
// 		int size = strlen(body);
		cursor += sprintf(msg + cursor, "%s", body);
	} else if (body_t == LUA_TUSERDATA) {
		const char *data = lua_touserdata(L, -1);
// 		int size = lua_rawlen(L, -1);
 		// TODO: deal with binary data
		cursor += sprintf(msg + cursor, "%s\r\n", data);
	}
	lua_pop(L, 1);

	lua_pop(L, 1);

	return msg;

}

static int l_serve(lua_State *L) {

	int port = luaL_checkinteger(L, 1);

	int sock_fd = socket(AF_INET, SOCK_STREAM, 0);

	if (sock_fd == -1) {
		fprintf(stderr, "failed to create socket\n");
		exit(EXIT_FAILURE);
	}

	setsockopt(sock_fd, SOL_SOCKET, SO_REUSEPORT, (int[]){1}, sizeof(int));
	fcntl(sock_fd, F_SETFL, fcntl(sock_fd, F_GETFL, 0) | O_NONBLOCK);

	struct sockaddr_in server_addr = {
		.sin_family = AF_INET,
		.sin_addr = {
			.s_addr = INADDR_ANY,
		},
		.sin_port = htons(port),
	};

	if (bind(sock_fd, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
		switch (errno) {
			case EACCES:
				fprintf(stderr, "port %d is in protected\n", port);
				break;
			case EADDRINUSE:
				fprintf(stderr, "port %d is in use\n", port);
				break;
			default:
				fprintf(stderr, "failed to bind socket\n");
				break;
		}
		exit(EXIT_FAILURE);
	}

	listen(sock_fd, 64);

	struct pollfd poll_fds[POLL_SIZE] = {0};
	int num_fds = 0;

	poll_fds[0].fd = sock_fd;
	poll_fds[0].events = POLLIN;
	num_fds++;

	while (1) {

		if (poll(poll_fds, num_fds, -1) == -1) {
			fprintf(stderr, "failed to poll\n");
			continue;
		}

		for (int i = 0; i < num_fds; i++) {

			if (poll_fds[i].revents & POLLIN) {

				if (poll_fds[i].fd == sock_fd) {

					while (1) {

						int conn_fd = accept(sock_fd, NULL, NULL);

						if (conn_fd < 0) {
							break;
						}

						poll_fds[num_fds].fd = conn_fd;
						poll_fds[num_fds].events = POLLIN;
						num_fds++;

					}

				} else {

					char *req_msg = malloc(BUF_SIZE);
					int conn_fd = poll_fds[i].fd;
					int times = 0;

					while (read(conn_fd, req_msg + times * BUF_SIZE, BUF_SIZE) >= BUF_SIZE) {
						times++;
						req_msg = realloc(req_msg, (times + 1) * BUF_SIZE);
					}

					printf("%s\n---\n", req_msg);

					const char *res_msg = "HTTP/1.1 200 OK\r\n\r\nhi\n";
					write(conn_fd, res_msg, strlen(res_msg));
					free(req_msg);
					close(conn_fd);
					poll_fds[i] = poll_fds[num_fds - 1];
					i--;
					num_fds--;

				}

			}

		}

// 		int conn_fd = accept(sock_fd, NULL, NULL);

// 		char *req_msg = malloc(BUF_SIZE);
// 		int times = 0;

// 		while (read(conn_fd, req_msg + times * BUF_SIZE, BUF_SIZE) >= BUF_SIZE) {
// 			times++;
// 			req_msg = realloc(req_msg, (times + 1) * BUF_SIZE);
// 		}

// 		lua_pushvalue(L, 2);
// 		push_req(L, req_msg);
// 		lua_call(L, 1, 1);
// 		char *res_msg = parse_res(L);
// 		write(conn_fd, res_msg, strlen(res_msg));
// 		free(req_msg);
// 		free(res_msg);
// 		close(conn_fd);

	}

	close(sock_fd);

	return 0;

}

static const luaL_Reg funcs[] = {
	{ "serve", l_serve, },
	{ NULL, NULL, }
};

int luaopen_http2(lua_State *L) {
	luaL_newlib(L, funcs);
	return 1;
}

