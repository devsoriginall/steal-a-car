-- Todos os carros do jogo. Para adicionar um carro, basta incluir uma linha aqui.
-- price: custo na esteira | income: dinheiro por segundo na garagem
local Cars = {
	-- Comum
	{ id = "fuscao", name = "Fuscão", rarity = "Comum", price = 10, income = 1, color = Color3.fromRGB(70, 130, 180) },
	{ id = "kombi", name = "Kombi", rarity = "Comum", price = 40, income = 2, color = Color3.fromRGB(235, 235, 220) },
	{ id = "hatch", name = "Hatch Popular", rarity = "Comum", price = 80, income = 4, color = Color3.fromRGB(200, 40, 40) },
	{ id = "taxi", name = "Táxi", rarity = "Comum", price = 140, income = 6, color = Color3.fromRGB(245, 200, 30) },
	{ id = "picape", name = "Picape", rarity = "Comum", price = 200, income = 8, color = Color3.fromRGB(110, 80, 50) },

	-- Incomum
	{ id = "seda", name = "Sedã Executivo", rarity = "Incomum", price = 500, income = 15, color = Color3.fromRGB(30, 30, 35) },
	{ id = "jipe", name = "Jipe", rarity = "Incomum", price = 1000, income = 25, color = Color3.fromRGB(85, 110, 60) },
	{ id = "van", name = "Van de Entrega", rarity = "Incomum", price = 1800, income = 40, color = Color3.fromRGB(240, 240, 240) },
	{ id = "compacto", name = "Esportivo Compacto", rarity = "Incomum", price = 3000, income = 60, color = Color3.fromRGB(255, 120, 0) },

	-- Raro
	{ id = "muscle", name = "Muscle Car", rarity = "Raro", price = 10000, income = 150, color = Color3.fromRGB(150, 0, 20) },
	{ id = "rally", name = "Carro de Rally", rarity = "Raro", price = 20000, income = 250, color = Color3.fromRGB(0, 90, 200) },
	{ id = "limo", name = "Limousine", rarity = "Raro", price = 35000, income = 400, color = Color3.fromRGB(15, 15, 15) },
	{ id = "monstro", name = "Caminhonete Monstro", rarity = "Raro", price = 60000, income = 600, color = Color3.fromRGB(0, 170, 80) },

	-- Épico
	{ id = "supercarro", name = "Supercarro", rarity = "Épico", price = 200000, income = 2000, color = Color3.fromRGB(255, 220, 0) },
	{ id = "hotrod", name = "Hot Rod", rarity = "Épico", price = 500000, income = 4500, color = Color3.fromRGB(200, 60, 0) },
	{ id = "gt", name = "Carro de Corrida GT", rarity = "Épico", price = 1000000, income = 8000, color = Color3.fromRGB(240, 240, 255) },

	-- Lendário
	{ id = "formula", name = "Fórmula 1", rarity = "Lendário", price = 5000000, income = 40000, color = Color3.fromRGB(220, 0, 0) },
	{ id = "hipercarro", name = "Hipercarro", rarity = "Lendário", price = 12000000, income = 80000, color = Color3.fromRGB(120, 0, 200) },
	{ id = "foguete", name = "Carro Foguete", rarity = "Lendário", price = 25000000, income = 150000, color = Color3.fromRGB(180, 180, 200) },

	-- Secreto
	{ id = "voador", name = "Carro Voador", rarity = "Secreto", price = 100000000, income = 1000000, color = Color3.fromRGB(0, 255, 230) },
}

local byId = {}
local byRarity = {}
for _, car in Cars do
	byId[car.id] = car
	byRarity[car.rarity] = byRarity[car.rarity] or {}
	table.insert(byRarity[car.rarity], car)
end

return {
	list = Cars,
	get = function(id: string)
		return byId[id]
	end,
	ofRarity = function(rarityName: string)
		return byRarity[rarityName] or {}
	end,
}
