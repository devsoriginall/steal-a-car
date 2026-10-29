-- Esconde os botões (ProximityPrompts) marcados como "OwnerOnly" quando a
-- garagem não é sua, por exemplo "Vender" e "Comprar vaga".
-- O servidor também confere o dono; isto aqui é só visual.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local originalDistance = {} -- [ProximityPrompt] = number

local function apply(prompt: ProximityPrompt)
	local isMine = prompt:GetAttribute("OwnerUserId") == player.UserId
	prompt.MaxActivationDistance = if isMine then originalDistance[prompt] else 0
end

local function track(instance: Instance)
	if not instance:IsA("ProximityPrompt") or not instance:GetAttribute("OwnerOnly") then
		return
	end
	originalDistance[instance] = instance.MaxActivationDistance
	apply(instance)
	instance:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		apply(instance)
	end)
	instance.Destroying:Connect(function()
		originalDistance[instance] = nil
	end)
end

for _, descendant in Workspace:GetDescendants() do
	track(descendant)
end
Workspace.DescendantAdded:Connect(track)
