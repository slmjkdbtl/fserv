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
	["wasm"] = "application/wasm",
}

function www.read_dir(path)

	local dirs = {}
	local files = {}
	local entries = fs.read_dir(path)

	for _, name in ipairs(entries) do

		local entry = path .. "/" .. name
		local list

		if fs.is_dir(entry) then
			list = dirs
		elseif fs.is_file(entry) then
			list = files
		end

		if list then
			for i, item in ipairs(list) do
				if name < item then
					table.insert(list, i, name)
					goto continue
				end
			end
			list[#list + 1] = name
		end

		::continue::

	end

	return table.join(dirs, files)

end

function www.dir(path)

	if (path:sub(1, 1) == "/") then
		return {
			status = 400,
			body = "bad request\n",
		}
	end

	if (not fs.is_dir(path)) then
		return {
			status = 404,
			body = "not found\n",
		}
	end

	local list = www.read_dir(path)
	local t = www.tag

	return www.html(t("html", {}, {

		t("head", {}, {
			t("title", {}, path),
			t("meta", { charset = "utf-8", }),
			t("style", {}, www.styles({
				["*"] = {
					["font-family"] = "Monospace",
					["font-size"] = "16px",
					["text-decoration"] = "none",
				},
				["body"] = {
					["padding"] = "6px",
				},
				["li"] = {
					["list-style"] = "none",
				},
				["a"] = {
					["color"] = "blue",
					["outline"] = "none",
					[":hover"] = {
						["color"] = "white",
						["background"] = "blue",
					},
				},
			}))
		}),

		t("body", {}, table.map(list, function(item)

			local url = item

			if path ~= "." then
				url = path .. "/" .. url
			end

			if fs.is_dir(url) then
				item = item .. "/"
			end

			return t("li", {}, {
				t("a", { href = "/" .. url, }, item),
			})

		end)),

	}))

end

function www.file(path)

	if (path:sub(1, 1) == "/") then
		return {
			status = 400,
			body = "bad request\n",
		}
	end

	if (not fs.is_file(path)) then
		return {
			status = 404,
			body = "not found\n",
		}
	end

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

function www.redirect(link)
	return {
		status = 307,
		headers = {
			["Location"] = link,
		},
	}
end

local assets = {}

function www.load(file)
	if (fs.is_dir(path)) then
		local list = fs.read_dir(path)
		for _, item in ipairs(list) do
			www.load(path .. "/" .. item)
		end
	elseif (fs.is_file(path)) then
		assets[path] = www.base64(path)
	end
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

function www.tag2(tag, attrs, children)
	return {
		tag = tag,
		attrs = attrs,
		children = children,
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

function www.html2(t)

	local text = ""

	text = "<" .. t.tag

	for k, v in pairs(t.attrs) do
		if (type(v) == "string") then
			v = "\"" .. v .. "\""
		end
		text = text .. " " .. k .. "=" .. v
	end

	text = text .. ">"

	if (type(t.children) == "string") then
		text = text .. t.children
	elseif (type(t.children) == "table") then
		for _, c in ipairs(t.children) do
			text = text .. www.html2(c)
		end
	end

	if (t.children ~= nil) then
		text = text .. "</" .. t.tag .. ">"
	end

	if t.tag == "html" then
		text = "<!DOCTYPE html>" .. text .. "\n"
	end

	return text

end

function www.styles(list)

	local text = ""

	function handle_sheet(s)
		local t = "{"
		for k, v in pairs(s) do
			t = t .. k .. ":" .. v .. ";"
		end
		t = t .. "}"
		return t
	end

	function handle_sheet_ex(sel, sheet)
		local t = sel .. " {"
		local post = ""
		for key, val in pairs(sheet) do
			-- media
			if key == "@media" then
				for cond, msheet in pairs(val) do
					post = post .. "@media " .. cond .. "{" .. sel .. handle_sheet(msheet) .. "}"
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
				t = t .. key .. ":" .. val .. ";"
			end
		end
		t = t .. "}" .. post
		return t
	end

	for sel, sheet in pairs(list) do
		if (sel == "@keyframes") then
			for name, map in pairs(sheet) do
				text = text .. "@keyframes " .. name .. "{"
				for time, fsheet in pairs(map) do
					text = text .. time .. handle_sheet(fsheet)
				end
				text = text .. "}"
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

	fs.append(file, msg)

end

function www.static(target, dir)
	-- ...
end

function www.path(target)

	local path = target:gsub("^/", ""):gsub("/$", "")

	if path == "" then
		path = "."
	end

	return path

end

return www

