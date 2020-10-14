-- wengwengweng

local http = require("http")
local httph = require("httph")
local fs = require("fs")
local t = httph.tag

local page = t("html", {}, {
	t("head", {}, {}),
	t("body", {}, {
		t("p", {}, "tga"),
		t("a", { href = "https://enemyspy.xyz", }, "here"),
	}),
})

http.serve(8000, function(req)
	return {
		status = 200,
		body = "no",
	}
end)

