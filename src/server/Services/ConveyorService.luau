-- Faz carros aparecerem na esteira central e deixa os jogadores comprarem.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cars = require(Shared.Config.Cars)
local GameConfig = require(Shared.Config.GameConfig)
local Mutations = require(Shared.Config.Mutations)
local Rarities = require(Shared.Config.Rarities)
local Format = require(Shared.Format)
local Net = require(Shared.Net)

local CarFactory = require(script.Parent.Parent.Modules.CarFactory)
local EconomyService = require(script.Parent.EconomyService)
local GarageService = require(script.Parent.GarageService)
local MapService = require(script.Parent.MapService)

local ConveyorService = {}

local notify = Net.event("Notify")
local random = Random.new()

local folder: Folder
local active = {} -- lista de { model, carId, mutation, distance, sold }

local function pickRarity()
	local total = 0
	for _, rarity in Rarities.list do
		total += rarity.weight
	end
	local roll = random:NextNumber(0, total)
	for _, rarity in Rarities.list do
		roll -= rarity.weight
		if roll <= 0 then
			return rarity
		end
	end
	return Rarities.list[1]
end

local function pickMutation(): string?
	for _, mutation in Mutations.list do
		if random:NextNumber() < mutation.chance then
			return mutation.name
		end
	end
	return nil
end

local function pickCar()
	local options = Cars.ofRarity(pickRarity().name)
	if #options == 0 then
		options = Cars.ofRarity("Comum")
	end
	return options[random:NextInteger(1, #options)]
end

local function tryBuy(entry, player: Player)
	if entry.sold then
		return
	end
	local car = Cars.get(entry.carId)
	if not GarageService.GetGarage(player) then
		return
	end
	if not GarageService.FindFreeSlot(player) then
		notify:FireClient(player, "Sua garagem está cheia! Venda um carro ou compre uma vaga.", "error")
		return
	end
	if not EconomyService.TrySpend(player, car.price) then
		notify:FireClient(player, "Você precisa de " .. Format.money(car.price), "error")
		return
	end

	entry.sold = true
	entry.model:Destroy()
	GarageService.AddCar(player, entry.carId, entry.mutation)

	local name = entry.mutation and (entry.mutation .. " " .. car.name) or car.name
	notify:FireClient(player, "Você comprou " .. name .. "!")
end

local function spawnCar()
	local car = pickCar()
	local mutation = pickMutation()

	local model = CarFactory.build(car.id, mutation, true)
	model:PivotTo(MapService.ConveyorStart)

	local entry = { model = model, carId = car.id, mutation = mutation, distance = 0, sold = false }

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Comprar"
	prompt.ObjectText = car.name .. " - " .. Format.money(car.price)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		tryBuy(entry, player)
	end)

	model.Parent = folder
	table.insert(active, entry)

	local rarity = Rarities.get(car.rarity)
	if rarity.order >= 5 or mutation then
		-- Lendários, secretos e mutações avisam o servidor inteiro.
		local name = mutation and (mutation .. " " .. car.name) or car.name
		notify:FireAllClients(name .. " (" .. car.rarity .. ") apareceu na esteira!", "rare")
	end
end

-- Vitrine com todos os carros (só no Studio), em duas fileiras ao lado da esteira.
local function buildShowroom()
	local showroom = Instance.new("Folder")
	showroom.Name = "StudioShowroom"
	showroom.Parent = Workspace
	local perRow = 10
	for index, car in Cars.list do
		local row = if index <= perRow then 1 else -1
		local column = (index - 1) % perRow
		local model = CarFactory.build(car.id, nil, true)
		model:PivotTo(CFrame.new(-58.5 + column * 13, 0, row * 30))
		model.Parent = showroom
	end
end

function ConveyorService.Init()
	folder = Instance.new("Folder")
	folder.Name = "ConveyorCars"
	folder.Parent = Workspace

	if RunService:IsStudio() and GameConfig.StudioShowroom then
		buildShowroom()
	end
end

function ConveyorService.Start()
	task.spawn(function()
		while true do
			spawnCar()
			task.wait(GameConfig.ConveyorSpawnInterval)
		end
	end)

	local length = GameConfig.ConveyorLength
	RunService.Heartbeat:Connect(function(dt)
		for index = #active, 1, -1 do
			local entry = active[index]
			if entry.sold then
				table.remove(active, index)
			else
				entry.distance += GameConfig.ConveyorSpeed * dt
				if entry.distance >= length then
					entry.sold = true
					entry.model:Destroy()
					table.remove(active, index)
				else
					entry.model:PivotTo(MapService.ConveyorStart * CFrame.new(entry.distance, 0, 0))
				end
			end
		end
	end)
end

return ConveyorService
