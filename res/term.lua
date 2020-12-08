-- wengwengweng

local term = {}

local styles = {
	reset = "0",
	bold = "1",
	dim = "2",
	italic = "3",
	underline = "4",
	blink = "5",
	black = "30",
	red = "31",
	green = "32",
	yellow = "33",
	blue = "34",
	magenta = "35",
	cyan = "36",
	white = "37",
	bg_black = "40",
	bg_red = "41",
	bg_green = "42",
	bg_yellow = "44",
	bg_blue = "44",
	bg_magenta = "45",
	bg_cyan = "46",
	bg_white = "47",
}

function term.stylize(str, style)
	return "\x1b[" .. styles[style] .. "m" .. str .. "\x1b[0m"
end

return term

