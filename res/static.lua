-- wengwengweng

local port = os.getenv("PORT") or 80

print("http://localhost:" .. port)

http.serve(port, function(req)

	local path = www.path(req.target)

	if (fs.is_dir(path)) then
		return www.dir(path)
	elseif (fs.is_file(path)) then
		return www.file(path)
	end

	return {
		status = 404,
		body = "no\n",
	}

end)

