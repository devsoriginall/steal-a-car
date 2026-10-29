local GameConfig = {
	StartingMoney = 50,

	-- Garagens
	GarageCount = 8,
	StartingSlots = 6,
	MaxSlots = 18,
	VipSlotBonus = 4, -- vagas grátis do game pass Vagas VIP
	SlotBasePrice = 500,
	SlotPriceGrowth = 2.2,

	-- Esteira
	ConveyorLength = 130,
	ConveyorSpeed = 8, -- studs por segundo
	ConveyorSpawnInterval = 2.5, -- segundos entre carros

	-- Venda devolve esta fração do preço
	SellRefund = 0.5,

	-- Roubo
	StealHoldDuration = 1.5, -- segundos segurando E para pegar o carro
	CarryWalkSpeed = 12, -- velocidade de quem está carregando um carro
	FastEscapeWalkSpeed = 16, -- com o game pass Fuga Rápida
	NormalWalkSpeed = 16,
	NewPlayerProtection = 300, -- segundos de garagem imune ao entrar

	-- Trava da garagem
	LockDuration = 60,
	TurboLockDuration = 120, -- com o game pass Trava Turbo
	LockCooldown = 180,

	-- Taco
	BatRange = 8,
	BatCooldown = 0.8,
	BatKnockback = 40,

	-- Rebirth: zera dinheiro, carros e vagas em troca de renda extra permanente
	RebirthBaseCost = 1000000,
	RebirthCostGrowth = 4,
	RebirthBonus = 0.5, -- +50% de renda por rebirth

	-- Save
	DataStoreName = "PlayerData_v1",
	AutosaveInterval = 60,
}

function GameConfig.slotPrice(currentSlots: number): number
	return math.floor(GameConfig.SlotBasePrice * GameConfig.SlotPriceGrowth ^ (currentSlots - GameConfig.StartingSlots))
end

function GameConfig.rebirthCost(rebirths: number): number
	return math.floor(GameConfig.RebirthBaseCost * GameConfig.RebirthCostGrowth ^ rebirths)
end

function GameConfig.rebirthMultiplier(rebirths: number): number
	return 1 + rebirths * GameConfig.RebirthBonus
end

return GameConfig
