-- wengwengweng

local port = os.getenv("PORT") or 8000
local t = www.tag

print("http://localhost:" .. port)

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
			t("a", { href = "https://github.com/slmjkdbtl/fserv", }, "code"),
		}),
	}),
})

local goodstuff = t("html", {}, {
	t("head", {}, {
		t("title", {}, "good stuff"),
		t("style", {}, www.styles(styles)),
	}),
	t("body", {}, {
		t("img", { id = "goodstuff", src = www.base64("103Exeggutor-Alola.png"), }),
		t("p", {  }, "hi"),
	}),
})

function no()
	return {
		status = 404,
		body = "no",
	}
end

http.serve(port, function(req)

	if (req.target == "/") then
		return www.html(main)
	end

	if (req.target == "/goodstuff") then
		return www.html(goodstuff)
	end

	return no()

end)

