-- Mutações multiplicam a renda de um carro. "chance" é a probabilidade de um
-- carro da esteira nascer com ela (testadas da mais rara para a mais comum).
local Mutations = {
	{ name = "Neon", mult = 10, chance = 0.005, color = nil, material = Enum.Material.Neon },
	{ name = "Diamante", mult = 5, chance = 0.015, color = Color3.fromRGB(120, 230, 255), material = Enum.Material.Glass },
	{ name = "Dourado", mult = 2, chance = 0.05, color = Color3.fromRGB(255, 200, 40), material = Enum.Material.Metal },
}

local byName = {}
for _, mutation in Mutations do
	byName[mutation.name] = mutation
end

return {
	list = Mutations,
	get = function(name: string?)
		return name and byName[name] or nil
	end,
	multiplier = function(name: string?): number
		local mutation = name and byName[name]
		return mutation and mutation.mult or 1
	end,
}
