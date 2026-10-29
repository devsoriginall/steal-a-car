-- Rebirth: o jogador troca dinheiro, carros e vagas por um bônus
-- permanente de renda.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Format = require(Shared.Format)
local Net = require(Shared.Net)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local GarageService = require(script.Parent.GarageService)
local StealService = require(script.Parent.StealService)

local RebirthService = {}

local notify = Net.event("Notify")

local function tryRebirth(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	if StealService.IsCarrying(player) then
		notify:FireClient(player, "Entregue o carro antes de fazer rebirth.", "error")
		return
	end
	local cost = GameConfig.rebirthCost(data.rebirths)
	if data.money < cost then
		notify:FireClient(player, "Você precisa de " .. Format.money(cost) .. " para fazer rebirth.", "error")
		return
	end

	data.rebirths += 1
	data.money = GameConfig.StartingMoney
	GarageService.Reset(player)
	EconomyService.RecomputeIncome(player)

	local bonus = math.floor((GameConfig.rebirthMultiplier(data.rebirths) - 1) * 100)
	notify:FireClient(player, "Rebirth " .. data.rebirths .. "! Agora você ganha +" .. bonus .. "% de renda.", "rare")
end

function RebirthService.Init()
	Net.event("RequestRebirth").OnServerEvent:Connect(tryRebirth)
end

return RebirthService
