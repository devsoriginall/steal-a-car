-- Atribui uma garagem a cada jogador, mostra os carros nas vagas,
-- permite vender carros e comprar vagas novas.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cars = require(Shared.Config.Cars)
local GameConfig = require(Shared.Config.GameConfig)
local Format = require(Shared.Format)
local Net = require(Shared.Net)

local CarFactory = require(script.Parent.Parent.Modules.CarFactory)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local MapService = require(script.Parent.MapService)

local GarageService = {}

local notify = Net.event("Notify")

local garageOf = {} -- [Player] = garage (de MapService.Garages)
local connections = {} -- [Player] = { RBXScriptConnection }

local function updateSlotPrompt(player: Player)
	local garage = garageOf[player]
	local data = DataService.Get(player)
	if not (garage and data) then
		return
	end
	if data.slots >= GameConfig.MaxSlots then
		garage.slotPrompt.ActionText = "Garagem completa"
		garage.slotPrompt.ObjectText = ""
		garage.slotPrompt.Enabled = false
	else
		garage.slotPrompt.ActionText = "Comprar vaga (" .. data.slots + 1 .. "/" .. GameConfig.MaxSlots .. ")"
		garage.slotPrompt.ObjectText = Format.money(GameConfig.slotPrice(data.slots))
		garage.slotPrompt.Enabled = true
	end
end

-- Mostra só as marcações das vagas já liberadas.
local function setSlotMarkers(garage, unlocked: number)
	for slotIndex = 1, GameConfig.MaxSlots do
		local marker = garage.model.Slots:FindFirstChild("Slot" .. slotIndex)
		if marker then
			marker.Transparency = if slotIndex <= unlocked then 0.8 else 1
		end
	end
end

local function updateSlotMarkers(player: Player)
	local garage = garageOf[player]
	local data = DataService.Get(player)
	if garage and data then
		setSlotMarkers(garage, data.slots)
	end
end

local function renderSlot(player: Player, slotIndex: number)
	local garage = garageOf[player]
	local data = DataService.Get(player)
	if not (garage and data) then
		return
	end

	local existing = garage.carsFolder:FindFirstChild("Slot" .. slotIndex)
	if existing then
		existing:Destroy()
	end

	local owned = data.cars[tostring(slotIndex)]
	if not owned or not Cars.get(owned.id) then
		return
	end

	local model = CarFactory.build(owned.id, owned.m, false)
	model.Name = "Slot" .. slotIndex
	model:SetAttribute("SlotIndex", slotIndex)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:PivotTo(garage.slots[slotIndex])

	local car = Cars.get(owned.id)
	local sellPrompt = Instance.new("ProximityPrompt")
	sellPrompt.Name = "SellPrompt"
	sellPrompt.ActionText = "Vender"
	sellPrompt.ObjectText = Format.money(math.floor(car.price * GameConfig.SellRefund))
	sellPrompt.KeyboardKeyCode = Enum.KeyCode.F
	sellPrompt.HoldDuration = 1
	sellPrompt.MaxActivationDistance = 8
	sellPrompt.RequiresLineOfSight = false
	sellPrompt:SetAttribute("OwnerOnly", true)
	sellPrompt:SetAttribute("OwnerUserId", player.UserId)
	sellPrompt.Parent = model.PrimaryPart

	sellPrompt.Triggered:Connect(function(who)
		if who == player then
			GarageService.SellCar(player, slotIndex)
		end
	end)

	model.Parent = garage.carsFolder
end

local function renderAll(player: Player)
	for slotIndex = 1, GameConfig.MaxSlots do
		renderSlot(player, slotIndex)
	end
	updateSlotMarkers(player)
	updateSlotPrompt(player)
end

local function teleportHome(player: Player, character: Model)
	local garage = garageOf[player]
	if not garage then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if root then
		-- Espera um quadro para o Roblox terminar de posicionar o personagem.
		task.wait()
		character:PivotTo(garage.spawnCFrame)
	end
end

function GarageService.GetGarage(player: Player)
	return garageOf[player]
end

function GarageService.Assign(player: Player): boolean
	local free
	for _, garage in MapService.Garages do
		if not garage.owner then
			free = garage
			break
		end
	end
	if not free then
		return false
	end

	free.owner = player
	garageOf[player] = free
	free.model:SetAttribute("OwnerUserId", player.UserId)
	free.slotPrompt:SetAttribute("OwnerUserId", player.UserId)
	free.ownerLabel.Text = "Garagem de " .. player.DisplayName

	connections[player] = {
		free.slotPrompt.Triggered:Connect(function(who)
			if who == player then
				GarageService.BuySlot(player)
			end
		end),
		player.CharacterAdded:Connect(function(character)
			teleportHome(player, character)
		end),
	}
	if player.Character then
		task.spawn(teleportHome, player, player.Character)
	end

	renderAll(player)
	return true
end

function GarageService.Release(player: Player)
	local garage = garageOf[player]
	for _, connection in connections[player] or {} do
		connection:Disconnect()
	end
	connections[player] = nil
	garageOf[player] = nil
	if not garage then
		return
	end

	garage.owner = nil
	garage.model:SetAttribute("OwnerUserId", nil)
	garage.slotPrompt:SetAttribute("OwnerUserId", nil)
	garage.ownerLabel.Text = "Garagem livre"
	garage.carsFolder:ClearAllChildren()
	setSlotMarkers(garage, GameConfig.StartingSlots)
end

function GarageService.FindFreeSlot(player: Player): number?
	local data = DataService.Get(player)
	if not data then
		return nil
	end
	for slotIndex = 1, data.slots do
		if not data.cars[tostring(slotIndex)] then
			return slotIndex
		end
	end
	return nil
end

-- Coloca um carro na primeira vaga livre. Retorna a vaga, ou nil se estiver cheio.
function GarageService.AddCar(player: Player, carId: string, mutation: string?): number?
	local data = DataService.Get(player)
	local slotIndex = GarageService.FindFreeSlot(player)
	if not (data and slotIndex) then
		return nil
	end
	data.cars[tostring(slotIndex)] = { id = carId, m = mutation }
	renderSlot(player, slotIndex)
	EconomyService.RecomputeIncome(player)
	return slotIndex
end

function GarageService.SellCar(player: Player, slotIndex: number)
	local data = DataService.Get(player)
	local owned = data and data.cars[tostring(slotIndex)]
	local car = owned and Cars.get(owned.id)
	if not car then
		return
	end
	local refund = math.floor(car.price * GameConfig.SellRefund)
	data.cars[tostring(slotIndex)] = nil
	renderSlot(player, slotIndex)
	EconomyService.Add(player, refund)
	EconomyService.RecomputeIncome(player)
	notify:FireClient(player, "Vendeu " .. car.name .. " por " .. Format.money(refund))
end

function GarageService.BuySlot(player: Player)
	local data = DataService.Get(player)
	if not data or data.slots >= GameConfig.MaxSlots then
		return
	end
	local price = GameConfig.slotPrice(data.slots)
	if not EconomyService.TrySpend(player, price) then
		notify:FireClient(player, "Você precisa de " .. Format.money(price) .. " para uma nova vaga", "error")
		return
	end
	data.slots += 1
	updateSlotMarkers(player)
	updateSlotPrompt(player)
	notify:FireClient(player, "Nova vaga liberada! (" .. data.slots .. "/" .. GameConfig.MaxSlots .. ")")
end

return GarageService
