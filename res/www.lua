-- wengwengweng

local www = {}

local mimes = {
	["aac"] = "audio/aac",
	["mp3"] = "audio/mpeg",
	["wav"] = "audio/wav",
	["mid"] = "audio/midi",
	["midi"] = "audio/midi",
	["otf"] = "font/otf",
	["ttf"] = "font/ttf",
	["woff"] = "font/woff",
	["woff2"] = "font/woff2",
	["mp4"] = "video/mp4",
	["bmp"] = "image/bmp",
	["png"] = "image/png",
	["jpg"] = "image/jpeg",
	["jpeg"] = "image/jpeg",
	["webp"] = "image/webp",
	["gif"] = "image/gif",
	["css"] = "text/css",
	["htm"] = "text/html",
	["html"] = "text/html",
	["txt"] = "text/plain",
	["csv"] = "text/csv",
	["js"] = "text/javascript",
	["xml"] = "text/xml",
	["php"] = "text/php",
	["json"] = "application/json",
	["pdf"] = "application/pdf",
	["zip"] = "application/zip",
	["rtf"] = "application/rtf",
	["gz"] = "application/gzip",
}

function www.printreq(req)
	print(req.method .. " " .. req.target)
	for k, v in pairs(req.headers) do
		print(k .. ": " .. v)
	end
end

function www.dir(path)

	if (fs.is_dir(path)) then

		local list = fs.read_dir(path)
		local t = www.tag

		return www.html(t("html", {}, {
			t("head", {}, {
				t("title", {}, path),
				t("meta", { charset = "utf-8", }),
				t("style", {}, www.style({
					["*"] = {
						["font-family"] = "Monospace",
					},
					["li"] = {
						["list-style"] = "none",
					},
					["a"] = {
						["color"] = "blue",
					},
					["a:hover"] = {
						["color"] = "white",
						["background"] = "blue",
					},
				}))
			}),
			t("body", {}, table.map(list, function(item)
				return t("li", {}, {
					t("a", { href = string.format("%s/%s", path, item), }, item),
				})
			end)),
		}))

	end

end

function www.file(path)

	if (fs.is_file(path)) then

		local ext = fs.extname(path)
		local t = mimes[ext]
		local headers = {}

		if (t) then
			headers["Content-Type"] = t
		end

		return {
			status = 200,
			body = fs.read_bytes(path),
			headers = headers,
		}

	end

end

function www.redirect(link)
	return {
		status = 307,
		headers = {
			["Location"] = link,
		},
	}
end

function www.html(t)
	return {
		status = 200,
		body = "<!DOCTYPE html>" .. t .. "\n",
		headers = {
			["Content-Type"] = "text/html",
		},
	}
end

function www.base64(file)
	-- ...
end

function www.tag(tag, attrs, children)

	local text = ""

	text = "<" .. tag

	for k, v in pairs(attrs) do
		if (type(v) == "string") then
			v = "\"" .. v .. "\""
		end
		text = text .. " " .. k .. "=" .. v
	end

	text = text .. ">"

	if (type(children) == "string") then
		text = text .. children
	elseif (type(children) == "table") then
		for _, v in ipairs(children) do
			text = text .. v
		end
	end

	if (children ~= nil) then
		text = text .. "</" .. tag .. ">"
	end

	return text

end

function www.style(list)

	local text = ""

	for sel, sheet in pairs(list) do
		local post = ""
		text = text .. sel .. "{"
		for key, val in pairs(sheet) do
			if key == "@media" then
				for cond, msheet in pairs(val) do
					post = post .. "@media " .. cond .. "{" .. sel .. "{"
					for mkey, mval in pairs(msheet) do
						post = post .. mkey .. ":" .. mval .. ";"
					end
					post = post .. "}}"
				end
			elseif key:sub(1, 1) == ":" then
				post = post .. sel .. key .. "{"
				for mkey, mval in pairs(val) do
					post = post .. mkey .. ":" .. mval .. ";"
				end
				post = post .. "}"
			else
				text = text .. key .. ":" .. val .. ";"
			end
		end
		text = text .. "}" .. post
	end

	return text

end

return www

