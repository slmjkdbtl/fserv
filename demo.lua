-- wengwengweng

local port = os.getenv("PORT") or 80
local t = www.tag

print("http://localhost:" .. port)

-- stylesheet
local styles = {
	["*"] = {
		["margin"] = "0",
		["padding"] = "0",
		["font-size"] = "16px",
		["font-family"] = "monospace",
		["white-space"] = "pre",
	},
	["body"] = {
		["padding"] = "24px",
	},
	["li"] = {
		["list-style"] = "none",
	},
	["a"] = {
		["color"] = "blue",
		-- supports sass-like nesting
		[":hover"] = {
			["background"] = "blue",
			["color"] = "white",
		},
	},
	["#title"] = {
		["font-size"] = "24px",
	},
	["#desc"] = {
		["margin-top"] = "12px",
	},
	["#links"] = {
		["margin-top"] = "16px",
	},
	["#goodstuff"] = {
		["width"] = "240px",
	},
}

-- simple html templating
local main = t("html", {}, {
	t("head", {}, {
		t("title", {}, "oh hi"),
		t("style", {}, www.styles(styles)),
	}),
	t("body", {}, {
		t("h1", { id = "title", }, "fserv"),
		t("p", { id = "desc", }, "minimal lua http runtime, with a focus on"),
		t("br", {}),
		t("li", {}, " - simplicity"),
		t("li", {}, " - server side rendering"),
		t("li", {}, " - archivability"),
		t("div", { id = "links", }, {
			t("a", { href = "/code", }, "code"),
		}),
	}),
})

local goodstuff = t("html", {}, {
	t("head", {}, {
		t("title", {}, "good stuff"),
		t("style", {}, www.styles(styles)),
	}),
	t("body", {}, {
		-- embed images as base64
		t("img", { id = "goodstuff", src = www.base64("103Exeggutor-Alola.png"), }),
		t("p", {}, "hi"),
	}),
})

-- http2.serve(port, function(req)
-- 	print(req.method)
-- 	print(req.target)
-- 	print(req.version)
-- 	for k, v in pairs(req.headers) do
-- 		print(k .. ": " .. v)
-- 	end
-- 	return {
-- 		status = 200,
-- 		body = "hi",
-- 		headers = {
-- 			["Content-Type"] = "text/plain",
-- 		},
-- 	}
-- 	return "HTTP/1.1 200 OK\r\n\r\nhi\n"
-- end)

-- takes a function, use the return value as response
http.serve(port, function(req)

	-- request info
	print(req.method .. " " .. req.target)

	for k, v in pairs(req.headers) do
		print(k .. ": " .. v)
	end

	print("---")

	-- serve html
	if (req.target == "/") then
		return www.html(main)
	end

	if (req.target == "/goodstuff") then
		return www.html(goodstuff)
	end

	-- redirecting
	if (req.target == "/code") then
		return www.redirect("https://github.com/slmjkdbtl/fserv")
	end

	-- serve static dir & files
	local path = www.path(req.target)

	if (fs.is_dir(path)) then
		-- serves an html page with dir listing
		return www.dir(path)
	elseif (fs.is_file(path)) then
		-- respond with file content and the assumed mime type
		return www.file(path)
	end

	-- fallback to 404, custom response
	return {
		status = 404,
		headers = {
			["Content-Type"] = "text/plain",
		},
		body = "no",
	}

end)

