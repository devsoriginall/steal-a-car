-- Roubo de carros: o ladrão pega um carro de outra garagem, carrega uma
-- miniatura acima da cabeça e precisa chegar à própria garagem.
-- Se apanhar com o taco, morrer ou sair do jogo, o carro volta para o dono.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cars = require(Shared.Config.Cars)
local GameConfig = require(Shared.Config.GameConfig)
local Net = require(Shared.Net)

local CarFactory = require(script.Parent.Parent.Modules.CarFactory)
local GarageService = require(script.Parent.GarageService)
local MapService = require(script.Parent.MapService)

local StealService = {}

local notify = Net.event("Notify")

local CARRY_SCALE = 0.35

-- [ladrão] = { owner, ownerSlot, record = { id, m }, model, connections }
local carrying = {}

local function carName(record): string
	local car = Cars.get(record.id)
	local name = car and car.name or record.id
	return record.m and (record.m .. " " .. name) or name
end

local function setWalkSpeed(player: Player, speed: number)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = speed
	end
end

-- Cria a miniatura do carro presa acima da cabeça do ladrão.
local function attachCarModel(player: Player, record): Model?
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return nil
	end

	local model = CarFactory.build(record.id, record.m, false)
	model.Name = "CarriedCar"
	model:ScaleTo(CARRY_SCALE)
	model:PivotTo(head.CFrame * CFrame.new(0, 2, 0))

	local body = model.PrimaryPart
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.Massless = true
			part.CanCollide = false
			part.CanQuery = false
			if part ~= body then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = body
				weld.Part1 = part
				weld.Parent = part
			end
		end
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = body
	weld.Parent = body

	model.Parent = character
	return model
end

local function finish(thief: Player)
	local entry = carrying[thief]
	if not entry then
		return nil
	end
	carrying[thief] = nil
	for _, connection in entry.connections do
		connection:Disconnect()
	end
	if entry.model then
		entry.model:Destroy()
	end
	thief:SetAttribute("Carrying", nil)
	setWalkSpeed(thief, GameConfig.NormalWalkSpeed)
	return entry
end

-- Devolve o carro ao dono (roubo falhou).
function StealService.Drop(thief: Player, reason: string?)
	local entry = finish(thief)
	if not entry then
		return
	end
	local name = carName(entry.record)
	local owner = entry.owner
	if owner.Parent and GarageService.GetGarage(owner) then
		GarageService.AddCar(owner, entry.record.id, entry.record.m, entry.ownerSlot)
		notify:FireClient(owner, "Seu " .. name .. " foi recuperado!")
	end
	if thief.Parent then
		notify:FireClient(thief, reason or ("Você perdeu o " .. name .. "!"), "error")
	end
end

function StealService.IsCarrying(player: Player): boolean
	return carrying[player] ~= nil
end

local function deliver(thief: Player)
	local entry = carrying[thief]
	if not entry then
		return
	end
	if not GarageService.FindFreeSlot(thief) then
		-- Garagem encheu durante o roubo: o carro volta para o dono.
		StealService.Drop(thief, "Sua garagem está cheia! O carro voltou para o dono.")
		return
	end
	finish(thief)
	GarageService.AddCar(thief, entry.record.id, entry.record.m)
	local name = carName(entry.record)
	notify:FireClient(thief, "Você roubou o " .. name .. "!")
	if entry.owner.Parent then
		notify:FireClient(entry.owner, thief.DisplayName .. " roubou seu " .. name .. "!", "error")
	end
end

local function tryStart(thief: Player, owner: Player, slotIndex: number)
	if carrying[thief] or thief == owner then
		return
	end
	if not GarageService.GetGarage(thief) then
		return
	end
	if GarageService.IsProtected(owner) then
		notify:FireClient(thief, "Essa garagem está protegida agora!", "error")
		return
	end
	if not GarageService.FindFreeSlot(thief) then
		notify:FireClient(thief, "Sua garagem está cheia! Venda um carro ou compre uma vaga.", "error")
		return
	end

	local humanoid = thief.Character and thief.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local record = GarageService.TakeCar(owner, slotIndex)
	if not record then
		return
	end

	local entry = {
		owner = owner,
		ownerSlot = slotIndex,
		record = record,
		model = attachCarModel(thief, record),
		connections = {},
	}
	carrying[thief] = entry
	thief:SetAttribute("Carrying", record.id)
	setWalkSpeed(thief, GameConfig.CarryWalkSpeed)

	table.insert(entry.connections, humanoid.Died:Connect(function()
		StealService.Drop(thief)
	end))

	local name = carName(record)
	notify:FireClient(thief, "Leve o " .. name .. " até a sua garagem!", "rare")
	notify:FireClient(owner, thief.DisplayName .. " está roubando seu " .. name .. "! Use o taco!", "error")
end

function StealService.Init()
	GarageService.OnStealRequested = tryStart
end

function StealService.Start()
	-- Confere várias vezes por segundo se o ladrão chegou à própria garagem.
	task.spawn(function()
		while true do
			task.wait(0.2)
			for thief in carrying do
				local garage = GarageService.GetGarage(thief)
				local root = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
				if garage and root and MapService.IsInsideGarage(garage, root.Position) then
					deliver(thief)
				end
			end
		end
	end)
end

-- Chamado pelo Main quando um jogador sai.
function StealService.OnPlayerRemoving(player: Player)
	-- Ladrão saiu: devolve o carro.
	StealService.Drop(player)
	-- Dono saiu: quem estava roubando dele fica com o carro se conseguir entregar,
	-- mas se falhar o carro some (não há para onde devolver).
end

return StealService
