-- Formata números grandes: 1500 -> "1.5K", 2300000 -> "2.3M"
local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

function Format.money(value: number): string
	local negative = value < 0
	value = math.abs(value)

	local index = 1
	while value >= 1000 and index < #SUFFIXES do
		value /= 1000
		index += 1
	end

	local text
	if index == 1 then
		text = tostring(math.floor(value))
	else
		text = string.format("%.1f", value):gsub("%.0$", "") .. SUFFIXES[index]
	end

	return (negative and "-$" or "$") .. text
end

return Format
