-- Dinheiro dos jogadores: renda por segundo, gastos e o placar.
-- Os valores atuais ficam em atributos do Player ("Money" e "Income"),
-- que o HUD do cliente lê.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cars = require(Shared.Config.Cars)
local GameConfig = require(Shared.Config.GameConfig)
local Mutations = require(Shared.Config.Mutations)
local Format = require(Shared.Format)

local DataService = require(script.Parent.DataService)

local EconomyService = {}

local tracked = {} -- [Player] = { income = number, leaderstat = StringValue }

local function publish(player: Player)
	local data = DataService.Get(player)
	local entry = tracked[player]
	if not (data and entry) then
		return
	end
	player:SetAttribute("Money", data.money)
	player:SetAttribute("Income", entry.income)
	player:SetAttribute("Rebirths", data.rebirths)
	entry.leaderstat.Value = Format.money(data.money)
end

-- Soma a renda de todos os carros na garagem do jogador.
function EconomyService.RecomputeIncome(player: Player)
	local data = DataService.Get(player)
	local entry = tracked[player]
	if not (data and entry) then
		return
	end
	local total = 0
	for _, owned in data.cars do
		local car = Cars.get(owned.id)
		if car then
			total += car.income * Mutations.multiplier(owned.m)
		end
	end
	entry.income = math.floor(total * GameConfig.rebirthMultiplier(data.rebirths))
	publish(player)
end

function EconomyService.Setup(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local money = Instance.new("StringValue")
	money.Name = "Dinheiro"
	money.Parent = leaderstats
	leaderstats.Parent = player

	tracked[player] = { income = 0, leaderstat = money }
	EconomyService.RecomputeIncome(player)
end

function EconomyService.Remove(player: Player)
	tracked[player] = nil
end

function EconomyService.GetMoney(player: Player): number
	local data = DataService.Get(player)
	return data and data.money or 0
end

function EconomyService.Add(player: Player, amount: number)
	local data = DataService.Get(player)
	if not data then
		return
	end
	data.money += amount
	publish(player)
end

-- Desconta o valor se o jogador tiver dinheiro suficiente. Retorna se conseguiu.
function EconomyService.TrySpend(player: Player, amount: number): boolean
	local data = DataService.Get(player)
	if not data or data.money < amount then
		return false
	end
	data.money -= amount
	publish(player)
	return true
end

function EconomyService.Start()
	task.spawn(function()
		while true do
			task.wait(1)
			for player, entry in tracked do
				if entry.income > 0 then
					EconomyService.Add(player, entry.income)
				end
			end
		end
	end)
end

return EconomyService
