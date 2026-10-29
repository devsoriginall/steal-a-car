-- Itens vendidos por Robux. Os IDs vêm do site do Roblox
-- (create.roblox.com → seu jogo → Monetização). Item com id = 0 aparece
-- na loja como "Em breve" e não pode ser comprado.
-- "robux" é só o preço mostrado na loja: o preço real é o definido no site.
local Products = {}

-- Game passes: compra única, valem para sempre.
Products.Passes = {
	{ key = "DoubleMoney", id = 0, name = "Dinheiro x2", description = "Toda a sua renda em dobro, para sempre.", robux = 199 },
	{ key = "VipSlots", id = 0, name = "Vagas VIP", description = "+4 vagas grátis na garagem.", robux = 149 },
	{ key = "TurboLock", id = 0, name = "Trava Turbo", description = "Sua trava dura 120s em vez de 60s.", robux = 99 },
	{ key = "FastEscape", id = 0, name = "Fuga Rápida", description = "Corre na velocidade normal carregando um carro roubado.", robux = 149 },
}

-- Produtos de desenvolvedor: podem ser comprados várias vezes.
-- Os pacotes de dinheiro valem X segundos da sua renda atual (com um mínimo).
Products.DevProducts = {
	{ key = "SmallCash", id = 0, name = "Pacote Pequeno", description = "5 minutos da sua renda.", robux = 25, incomeSeconds = 300, minimum = 1000 },
	{ key = "BigCash", id = 0, name = "Pacote Grande", description = "30 minutos da sua renda.", robux = 99, incomeSeconds = 1800, minimum = 10000 },
	{ key = "LegendaryCar", id = 0, name = "Carro Lendário", description = "Um carro Lendário aleatório na sua garagem.", robux = 299 },
	{ key = "Shield", id = 0, name = "Escudo 15 min", description = "Ninguém rouba sua garagem por 15 minutos.", robux = 49, shieldSeconds = 900 },
}

local byKey = {}
for _, item in Products.Passes do
	item.kind = "pass"
	byKey[item.key] = item
end
for _, item in Products.DevProducts do
	item.kind = "product"
	byKey[item.key] = item
end

function Products.get(key: string)
	return byKey[key]
end

function Products.byProductId(productId: number)
	for _, item in Products.DevProducts do
		if item.id ~= 0 and item.id == productId then
			return item
		end
	end
	return nil
end

function Products.byPassId(passId: number)
	for _, item in Products.Passes do
		if item.id ~= 0 and item.id == passId then
			return item
		end
	end
	return nil
end

return Products
