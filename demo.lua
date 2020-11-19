-- wengwengweng

local port = 8000

print("http://localhost:" .. port)

http.serve(port, function(req)
	return {
		status = 200,
		body = "hi",
	}
end)

