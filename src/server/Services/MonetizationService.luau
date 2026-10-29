-- Game passes e produtos de desenvolvedor (Robux).
-- Os efeitos dos passes ficam em atributos do Player ("Pass_<key>"), que os
-- outros serviços e o cliente leem.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cars = require(Shared.Config.Cars)
local Products = require(Shared.Config.Products)
local Format = require(Shared.Format)
local Net = require(Shared.Net)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local GarageService = require(script.Parent.GarageService)

local MonetizationService = {}

local notify = Net.event("Notify")

local MAX_SAVED_RECEIPTS = 50

local function applyPass(player: Player, item)
	if player:GetAttribute("Pass_" .. item.key) then
		return
	end
	player:SetAttribute("Pass_" .. item.key, true)
	EconomyService.RecomputeIncome(player)
	GarageService.Refresh(player)
end

-- Confere quais passes o jogador já tem (chamado quando ele entra).
function MonetizationService.Setup(player: Player)
	for _, item in Products.Passes do
		if item.id ~= 0 then
			task.spawn(function()
				local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, item.id)
				if ok and owns and player.Parent then
					applyPass(player, item)
				end
			end)
		end
	end
end

local function grantProduct(player: Player, item): boolean
	if item.key == "SmallCash" or item.key == "BigCash" then
		local income = player:GetAttribute("Income") or 0
		local amount = math.max(item.minimum, math.floor(income * item.incomeSeconds))
		EconomyService.Add(player, amount)
		notify:FireClient(player, "Você recebeu " .. Format.money(amount) .. "!", "rare")
		return true
	elseif item.key == "LegendaryCar" then
		local options = Cars.ofRarity("Lendário")
		local car = options[math.random(1, #options)]
		if GarageService.AddCar(player, car.id, nil) then
			notify:FireClient(player, "Você ganhou um " .. car.name .. "!", "rare")
		else
			-- Garagem cheia: entrega o valor do carro em dinheiro.
			EconomyService.Add(player, car.price)
			notify:FireClient(player, "Garagem cheia! Você recebeu " .. Format.money(car.price) .. " no lugar do " .. car.name .. ".", "rare")
		end
		return true
	elseif item.key == "Shield" then
		GarageService.AddProtection(player, item.shieldSeconds)
		notify:FireClient(player, "Escudo ativado por " .. math.floor(item.shieldSeconds / 60) .. " minutos!", "rare")
		return true
	end
	return false
end

-- O Roblox chama isto a cada compra de produto (e repete até recebermos
-- PurchaseGranted). Guardamos os recibos no save para nunca entregar duas vezes.
local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local data = player and DataService.Get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	data.receipts = data.receipts or {}
	if table.find(data.receipts, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local item = Products.byProductId(receipt.ProductId)
	if not item then
		warn("[Monetization] Produto desconhecido:", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, granted = pcall(grantProduct, player, item)
	if not (ok and granted) then
		warn("[Monetization] Falha ao entregar", item.key, granted)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	table.insert(data.receipts, receipt.PurchaseId)
	while #data.receipts > MAX_SAVED_RECEIPTS do
		table.remove(data.receipts, 1)
	end
	DataService.Save(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function onPurchaseRequested(player: Player, key: string)
	local item = typeof(key) == "string" and Products.get(key)
	if not item or item.id == 0 then
		return
	end
	if item.kind == "pass" then
		if not player:GetAttribute("Pass_" .. item.key) then
			MarketplaceService:PromptGamePassPurchase(player, item.id)
		end
	else
		MarketplaceService:PromptProductPurchase(player, item.id)
	end
end

function MonetizationService.Init()
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local item = Products.byPassId(passId)
		if purchased and item then
			applyPass(player, item)
			notify:FireClient(player, "Você comprou " .. item.name .. "! Obrigado!", "rare")
		end
	end)
	Net.event("RequestPurchase").OnServerEvent:Connect(onPurchaseRequested)
end

return MonetizationService
