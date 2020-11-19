-- wengwengweng

local port = os.getenv("PORT") or 80

print("http://localhost:" .. port)

http.serve(port, function(req)

	local path = req.target:sub(2, #req.target)

	if path == "" then
		path = "."
	end

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

