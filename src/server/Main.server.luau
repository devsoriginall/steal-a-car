-- Ponto de entrada do servidor: inicia os serviços e cuida da entrada/saída de jogadores.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local Services = script.Parent.Services
local DataService = require(Services.DataService)
local MapService = require(Services.MapService)
local EconomyService = require(Services.EconomyService)
local GarageService = require(Services.GarageService)
local ConveyorService = require(Services.ConveyorService)
local StealService = require(Services.StealService)
local CombatService = require(Services.CombatService)
local RebirthService = require(Services.RebirthService)
local MonetizationService = require(Services.MonetizationService)

local notify = Net.event("Notify")

DataService.Init()
MapService.Init()
ConveyorService.Init()
StealService.Init()
CombatService.Init()
RebirthService.Init()
MonetizationService.Init()

DataService.Start()
EconomyService.Start()
GarageService.Start()
ConveyorService.Start()
StealService.Start()

local function onPlayerAdded(player: Player)
	local data = DataService.Load(player)
	if not data then
		return
	end

	EconomyService.Setup(player)
	CombatService.Setup(player)
	MonetizationService.Setup(player)
	if not GarageService.Assign(player) then
		player:Kick("O servidor está cheio. Tente outro servidor!")
		return
	end

	notify:FireClient(player, "Bem-vindo ao Steal a Car! Compre carros na esteira para ganhar dinheiro.")
end

local function onPlayerRemoving(player: Player)
	StealService.OnPlayerRemoving(player)
	CombatService.Remove(player)
	GarageService.Release(player)
	EconomyService.Remove(player)
	DataService.Release(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Jogadores que entraram antes deste script rodar (comum no Studio).
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
