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

function www.dir(path)

	if (fs.is_dir(path)) then

		local list = fs.read_dir(path)
		local t = www.tag

		return www.html(t("html", {}, {
			t("head", {}, {
				t("title", {}, path),
				t("meta", { charset = "utf-8", }),
				t("style", {}, www.styles({
					["*"] = {
						["font-family"] = "Monospace",
					},
					["li"] = {
						["list-style"] = "none",
					},
					["a"] = {
						["color"] = "blue",
						[":hover"] = {
							["color"] = "white",
							["background"] = "blue",
						},
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
		local mime = mimes[ext]
		local headers = {}

		if (mime) then
			headers["Content-Type"] = mime
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

local assets = {}

function www.load(file)
	assets[file] = www.base64(file)
end

function www.get(file)
	return assets[file]
end

function www.base64(file)
	local ext = fs.extname(file)
	local mime = mimes[ext]
	if (mime) then
		return "data:" .. mime .. ";base64," .. fs.base64(file)
	end
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

	if (children ~= nil) then
		text = text .. "\n"
	end

	if (type(children) == "string") then
		text = text .. children
	elseif (type(children) == "table") then
		for _, v in ipairs(children) do
			text = text .. v
		end
	end

	if (children ~= nil) then
		text = text .. "\n</" .. tag .. ">\n"
	end

	return text

end

function www.styles(list)

	local text = ""

	function handle_sheet(s)
		local t = "{\n"
		for k, v in pairs(s) do
			t = t .. k .. ":" .. v .. ";\n"
		end
		t = t .. "}\n"
		return t
	end

	function handle_sheet_ex(sel, sheet)
		local t = sel .. " {\n"
		local post = ""
		for key, val in pairs(sheet) do
			-- media
			if key == "@media" then
				for cond, msheet in pairs(val) do
					post = post .. "@media " .. cond .. "{\n" .. sel .. handle_sheet(msheet) .. "}\n"
				end
			-- pseudo class
			elseif key:sub(1, 1) == ":" then
				post = post .. handle_sheet_ex(sel .. key, val)
			-- self
			elseif key:sub(1, 1) == "&" then
				post = post .. handle_sheet_ex(sel .. key:sub(2, #key), val)
			-- nesting child
			elseif type(val) == "table" then
				post = post .. handle_sheet_ex(sel .. " " .. key, val)
			else
				t = t .. key .. ":" .. val .. ";\n"
			end
		end
		t = t .. "}\n" .. post
		return t
	end

	for sel, sheet in pairs(list) do
		if (sel == "@keyframes") then
			for name, map in pairs(sheet) do
				text = text .. "@keyframes " .. name .. "{\n"
				for time, fsheet in pairs(map) do
					text = text .. time .. handle_sheet(fsheet)
				end
				text = text .. "}\n"
			end
		else
			text = text .. handle_sheet_ex(sel, sheet)
		end
	end

	return text

end

function www.log(file, req, err)

	local msg = ""
	local date = os.date("%Y/%m/%d %H:%M:%S")

	msg = msg .. "== " .. date .. "\n"
	msg = msg .. req.method .. " " .. req.target .. "\n"

	for k, v in pairs(req.headers) do
		msg = msg .. k .. ": " .. v .. "\n"
	end

	msg = msg .. err .. "\n"

	fs.append_text(file, msg)

end

return www

