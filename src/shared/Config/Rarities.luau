-- Raridades dos carros. "weight" é o peso relativo de aparecer na esteira.
local Rarities = {
	{ name = "Comum", color = Color3.fromRGB(190, 190, 190), weight = 55 },
	{ name = "Incomum", color = Color3.fromRGB(85, 200, 90), weight = 25 },
	{ name = "Raro", color = Color3.fromRGB(60, 140, 255), weight = 12 },
	{ name = "Épico", color = Color3.fromRGB(170, 80, 255), weight = 6 },
	{ name = "Lendário", color = Color3.fromRGB(255, 170, 0), weight = 1.9 },
	{ name = "Secreto", color = Color3.fromRGB(255, 50, 80), weight = 0.1 },
}

local byName = {}
for order, rarity in Rarities do
	rarity.order = order
	byName[rarity.name] = rarity
end

return {
	list = Rarities,
	get = function(name: string)
		return byName[name]
	end,
}
