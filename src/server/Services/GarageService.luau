-- Atribui uma garagem a cada jogador, mostra os carros nas vagas,
-- permite vender carros, comprar vagas e trancar a garagem.
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

-- Definido pelo StealService: chamado quando alguém tenta roubar um carro.
GarageService.OnStealRequested = nil :: ((thief: Player, owner: Player, slotIndex: number) -> ())?

local function formatTime(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- Atualiza a placa, o campo de força e o botão de trancar de uma garagem.
local function updateStatus(garage)
	local owner = garage.owner
	if not owner then
		garage.ownerLabel.Text = "Garagem livre"
		garage.barrier.Transparency = 1
		return
	end

	local now = os.clock()
	local status = ""
	if (garage.lockedUntil or 0) > now then
		status = "  🔒 " .. formatTime(garage.lockedUntil - now)
	elseif (garage.protectedUntil or 0) > now then
		status = "  🛡️ " .. formatTime(garage.protectedUntil - now)
	end
	garage.ownerLabel.Text = "Garagem de " .. owner.DisplayName .. status
	garage.barrier.Transparency = if (garage.lockedUntil or 0) > now then 0.4 else 1

	local readyAt = garage.lockReadyAt or 0
	garage.lockPrompt.ObjectText = if readyAt > now
		then "Recarrega em " .. formatTime(readyAt - now)
		else GameConfig.LockDuration .. "s"
end

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

	-- Botão de roubar, que só os outros jogadores veem
	local stealPrompt = Instance.new("ProximityPrompt")
	stealPrompt.Name = "StealPrompt"
	stealPrompt.ActionText = "Roubar"
	stealPrompt.ObjectText = car.name
	stealPrompt.HoldDuration = GameConfig.StealHoldDuration
	stealPrompt.MaxActivationDistance = 8
	stealPrompt.RequiresLineOfSight = false
	stealPrompt:SetAttribute("OthersOnly", true)
	stealPrompt:SetAttribute("OwnerUserId", player.UserId)
	stealPrompt.Parent = model.PrimaryPart

	stealPrompt.Triggered:Connect(function(thief)
		if thief ~= player and GarageService.OnStealRequested then
			GarageService.OnStealRequested(thief, player, slotIndex)
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
	free.protectedUntil = os.clock() + GameConfig.NewPlayerProtection
	free.lockedUntil = 0
	free.lockReadyAt = 0
	garageOf[player] = free
	free.model:SetAttribute("OwnerUserId", player.UserId)
	free.slotPrompt:SetAttribute("OwnerUserId", player.UserId)
	free.lockPrompt:SetAttribute("OwnerUserId", player.UserId)
	updateStatus(free)

	connections[player] = {
		free.slotPrompt.Triggered:Connect(function(who)
			if who == player then
				GarageService.BuySlot(player)
			end
		end),
		free.lockPrompt.Triggered:Connect(function(who)
			if who == player then
				GarageService.Lock(player)
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
	garage.lockedUntil = 0
	garage.lockReadyAt = 0
	garage.protectedUntil = 0
	garage.model:SetAttribute("OwnerUserId", nil)
	garage.slotPrompt:SetAttribute("OwnerUserId", nil)
	garage.lockPrompt:SetAttribute("OwnerUserId", nil)
	updateStatus(garage)
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

-- Coloca um carro numa vaga livre (de preferência a indicada).
-- Retorna a vaga usada, ou nil se a garagem estiver cheia.
function GarageService.AddCar(player: Player, carId: string, mutation: string?, preferredSlot: number?): number?
	local data = DataService.Get(player)
	if not data then
		return nil
	end
	local slotIndex = GarageService.FindFreeSlot(player)
	if preferredSlot and preferredSlot <= data.slots and not data.cars[tostring(preferredSlot)] then
		slotIndex = preferredSlot
	end
	if not slotIndex then
		return nil
	end
	data.cars[tostring(slotIndex)] = { id = carId, m = mutation }
	renderSlot(player, slotIndex)
	EconomyService.RecomputeIncome(player)
	return slotIndex
end

-- Tira um carro da garagem (usado no roubo). Retorna { id, m } ou nil.
function GarageService.TakeCar(player: Player, slotIndex: number)
	local data = DataService.Get(player)
	local owned = data and data.cars[tostring(slotIndex)]
	if not owned then
		return nil
	end
	data.cars[tostring(slotIndex)] = nil
	renderSlot(player, slotIndex)
	EconomyService.RecomputeIncome(player)
	return owned
end

-- Garagem trancada ou com proteção de iniciante não pode ser roubada.
function GarageService.IsProtected(player: Player): boolean
	local garage = garageOf[player]
	if not garage then
		return true
	end
	local now = os.clock()
	return (garage.lockedUntil or 0) > now or (garage.protectedUntil or 0) > now
end

function GarageService.Lock(player: Player)
	local garage = garageOf[player]
	if not garage then
		return
	end
	local now = os.clock()
	if (garage.lockReadyAt or 0) > now then
		notify:FireClient(player, "A trava está recarregando: " .. formatTime(garage.lockReadyAt - now), "error")
		return
	end
	garage.lockedUntil = now + GameConfig.LockDuration
	garage.lockReadyAt = now + GameConfig.LockCooldown
	updateStatus(garage)
	notify:FireClient(player, "Garagem trancada por " .. GameConfig.LockDuration .. " segundos!")
end

-- Usado pelo rebirth: limpa todos os carros e volta às vagas iniciais.
function GarageService.Reset(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	data.cars = {}
	data.slots = GameConfig.StartingSlots
	renderAll(player)
	EconomyService.RecomputeIncome(player)
end

function GarageService.Start()
	task.spawn(function()
		while true do
			task.wait(1)
			for _, garage in MapService.Garages do
				updateStatus(garage)
			end
		end
	end)
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
