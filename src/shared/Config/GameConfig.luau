local GameConfig = {
	StartingMoney = 50,

	-- Garagens
	GarageCount = 8,
	StartingSlots = 6,
	MaxSlots = 18,
	SlotBasePrice = 500,
	SlotPriceGrowth = 2.2,

	-- Esteira
	ConveyorLength = 130,
	ConveyorSpeed = 8, -- studs por segundo
	ConveyorSpawnInterval = 2.5, -- segundos entre carros

	-- Venda devolve esta fração do preço
	SellRefund = 0.5,

	-- Save
	DataStoreName = "PlayerData_v1",
	AutosaveInterval = 60,
}

function GameConfig.slotPrice(currentSlots: number): number
	return math.floor(GameConfig.SlotBasePrice * GameConfig.SlotPriceGrowth ^ (currentSlots - GameConfig.StartingSlots))
end

return GameConfig
