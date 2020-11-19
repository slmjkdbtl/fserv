-- wengwengweng

http.serve(8000, function(req)
	return {
		status = 200,
		body = "hi",
	}
end)

