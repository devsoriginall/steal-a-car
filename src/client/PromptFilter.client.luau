-- Esconde os botões (ProximityPrompts) conforme o dono da garagem:
-- "OwnerOnly" (Vender, Comprar vaga, Trancar) só aparece para o dono, e
-- "OthersOnly" (Roubar) só aparece para os outros jogadores.
-- O servidor também confere tudo; isto aqui é só visual.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local originalDistance = {} -- [ProximityPrompt] = number

local function apply(prompt: ProximityPrompt)
	local isMine = prompt:GetAttribute("OwnerUserId") == player.UserId
	local visible = if prompt:GetAttribute("OwnerOnly") then isMine else not isMine
	prompt.MaxActivationDistance = if visible then originalDistance[prompt] else 0
end

local function track(instance: Instance)
	if not instance:IsA("ProximityPrompt") then
		return
	end
	if not (instance:GetAttribute("OwnerOnly") or instance:GetAttribute("OthersOnly")) then
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
