-- wengwengweng

function table.join(t1, t2)
	local l = {}
	if t1[1] or t2[1] then
		for i, v in ipairs(t1) do
			l[i] = v
		end
		for i, v in ipairs(t2) do
			l[#t1 + i] = v
		end
	else
		for k, v in pairs(t1) do
			l[k] = v
		end
		for k, v in pairs(t2) do
			l[k] = v
		end
	end
	return l
end

function table.map(t, f)
	local l = {}
	for i, v in ipairs(t) do
		l[i] = f(v)
	end
	return l
end

function table.keys(t)
	local l = {}
	local i = 1
	for k, _ in pairs(t) do
		l[i] = k
		i = i + 1
	end
	return l
end

function table.values(t)
	local l = {}
	local i = 1
	for _, v in pairs(t) do
		l[i] = v
		i = i + 1
	end
	return l
end

function table.search(t, val)
	for i = 1, #t do
		if t[i] == val then
			return i
		end
	end
	return nil
end

function table.filter(t, f)
	local l = {}
	for i = 1, #t do
		if f(t[i]) then
			l[#l + 1] = t[i]
		end
	end
	return l
end

function string.split(str, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(str, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

