-- wengwengweng

local httph = {}

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

function httph.file(path)

	return function(req)

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

end

function httph.route(method, pat, handler)
	return function(req)
		if (req.target == pat and req.method == method) then
			return handler(req)
		end
	end
end

function httph.static(path)
	return function(req)
		local path = path .. req.target
		if (req.method == "GET") then
			return httph.file(path)(req)
		end
	end
end

function httph.html(t)
	return function(req)
		return {
			status = 200,
			body = "<!DOCTYPE html>" .. t .. "\n",
			headers = {
				["Content-Type"] = "text/html",
			},
		}
	end
end

function httph.handlers(handlers)
	return function(req)
		for _, f in ipairs(handlers) do
			local res = f(req)
			if (res) then
				return res
			end
		end
	end
end

function httph.tag(tag, attrs, children)

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

return httph

