-- Taco: todo jogador recebe um. Acertar quem está carregando um carro
-- faz o carro voltar para o dono. Também empurra o alvo para trás.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local StealService = require(script.Parent.StealService)

local CombatService = {}

local TOOL_NAME = "Taco"

local lastSwing = {} -- [Player] = os.clock()

local function buildTool(): Tool
	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.ToolTip = "Bata em quem está roubando seus carros!"
	tool.CanBeDropped = false
	tool.GripPos = Vector3.new(0, -1.2, 0)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 3.5, 0.4)
	handle.Color = Color3.fromRGB(140, 90, 40)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	return tool
end

local function swing(player: Player)
	local now = os.clock()
	if now - (lastSwing[player] or 0) < GameConfig.BatCooldown then
		return
	end
	lastSwing[player] = now

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	-- Acerta o jogador mais próximo à frente, dentro do alcance.
	local bestTarget, bestDistance = nil, GameConfig.BatRange
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local otherRoot = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				local offset = otherRoot.Position - root.Position
				local distance = offset.Magnitude
				local inFront = distance < 3 or root.CFrame.LookVector:Dot(offset.Unit) > 0.3
				if distance < bestDistance and inFront then
					bestTarget, bestDistance = other, distance
				end
			end
		end
	end
	if not bestTarget then
		return
	end

	local targetRoot = bestTarget.Character.HumanoidRootPart
	local push = (targetRoot.Position - root.Position) * Vector3.new(1, 0, 1)
	if push.Magnitude > 0 then
		targetRoot.AssemblyLinearVelocity = push.Unit * GameConfig.BatKnockback + Vector3.new(0, 20, 0)
	end

	if StealService.IsCarrying(bestTarget) then
		StealService.Drop(bestTarget, player.DisplayName .. " te acertou! O carro voltou para o dono.")
	end
end

-- Conecta o Activated de cada taco que aparece na mochila do jogador.
local function watchTools(player: Player)
	local function hook(instance: Instance)
		if instance:IsA("Tool") and instance.Name == TOOL_NAME and not instance:GetAttribute("Hooked") then
			instance:SetAttribute("Hooked", true)
			instance.Activated:Connect(function()
				swing(player)
			end)
		end
	end

	local function watch(container: Instance)
		for _, child in container:GetChildren() do
			hook(child)
		end
		container.ChildAdded:Connect(hook)
	end

	watch(player:WaitForChild("Backpack"))
	player.CharacterAdded:Connect(function(character)
		watch(character)
		-- A mochila é recriada a cada respawn.
		watch(player:WaitForChild("Backpack"))
	end)
	if player.Character then
		watch(player.Character)
	end
end

function CombatService.Init()
	buildTool().Parent = StarterPack
end

function CombatService.Setup(player: Player)
	task.spawn(watchTools, player)
end

function CombatService.Remove(player: Player)
	lastSwing[player] = nil
end

return CombatService
