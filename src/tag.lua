-- wengwengweng

return function(tag, attrs, children)

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

