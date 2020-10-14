-- wengwengweng

local http = require("http")
local fs = require("fs")

-- local bytes = fs.read_bytes("hi.png")

local entries = fs.read_dir(".")

for i, v in ipairs(entries) do
	print(i, v)
end

function t(tag, attrs, children)

	local str = ""

	str = "<" .. tag

	for k, v in pairs(attrs) do
		if (type(v) == "string") then
			v = "\"" .. v .. "\""
		end
		str = str .. " " .. k .. "=" .. v
	end

	str = str .. ">"

	if (type(children) == "string") then
		str = str .. children
	elseif (type(children) == "table") then
		for _, v in ipairs(children) do
			str = str .. v
		end
	end

	if (children ~= nil) then
		str = str .. "</" .. tag .. ">"
	end

	return str

end

local page = t("html", {}, {
	t("head", {}, {}),
	t("body", {}, {
		t("p", {}, "tga"),
		t("a", { href = "https://enemyspy.xyz", }, "here"),
	}),
})

http.listen(8000, function(req)
	print(req.url)
	return {
		status = 200,
		body = page,
		headers = {
			["Content-Type"] = "text/html",
			["Test"] = req.url,
		},
	}
end)

