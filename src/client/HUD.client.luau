-- Mostra o dinheiro, a renda por segundo e as notificações na tela.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Format = require(Shared.Format)
local Net = require(Shared.Net)

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Painel de dinheiro (canto inferior esquerdo)
local panel = Instance.new("Frame")
panel.Name = "MoneyPanel"
panel.AnchorPoint = Vector2.new(0, 1)
panel.Position = UDim2.new(0, 16, 1, -16)
panel.Size = UDim2.fromOffset(240, 80)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
panel.BackgroundTransparency = 0.25
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Name = "Money"
moneyLabel.Position = UDim2.fromOffset(14, 8)
moneyLabel.Size = UDim2.new(1, -28, 0, 40)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Font = Enum.Font.GothamBlack
moneyLabel.TextScaled = true
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.TextColor3 = Color3.fromRGB(255, 230, 90)
moneyLabel.Text = "$0"
moneyLabel.Parent = panel

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "Income"
incomeLabel.Position = UDim2.fromOffset(14, 48)
incomeLabel.Size = UDim2.new(1, -28, 0, 24)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Font = Enum.Font.GothamBold
incomeLabel.TextScaled = true
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
incomeLabel.Text = "+$0/s"
incomeLabel.Parent = panel

-- Botão de rebirth (acima do painel de dinheiro)
local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "Rebirth"
rebirthButton.AnchorPoint = Vector2.new(0, 1)
rebirthButton.Position = UDim2.new(0, 16, 1, -104)
rebirthButton.Size = UDim2.fromOffset(240, 44)
rebirthButton.BackgroundColor3 = Color3.fromRGB(120, 60, 200)
rebirthButton.AutoButtonColor = true
rebirthButton.Font = Enum.Font.GothamBold
rebirthButton.TextScaled = true
rebirthButton.TextColor3 = Color3.new(1, 1, 1)
rebirthButton.Parent = gui
Instance.new("UICorner", rebirthButton).CornerRadius = UDim.new(0, 10)
local rebirthPadding = Instance.new("UIPadding")
rebirthPadding.PaddingLeft = UDim.new(0, 8)
rebirthPadding.PaddingRight = UDim.new(0, 8)
rebirthPadding.PaddingTop = UDim.new(0, 6)
rebirthPadding.PaddingBottom = UDim.new(0, 6)
rebirthPadding.Parent = rebirthButton

local confirmUntil = 0

local function refresh()
	local money = player:GetAttribute("Money") or 0
	local rebirths = player:GetAttribute("Rebirths") or 0
	moneyLabel.Text = Format.money(money)
	incomeLabel.Text = "+" .. Format.money(player:GetAttribute("Income") or 0) .. "/s"

	local cost = GameConfig.rebirthCost(rebirths)
	local nextBonus = math.floor((GameConfig.rebirthMultiplier(rebirths + 1) - 1) * 100)
	if os.clock() < confirmUntil then
		rebirthButton.Text = "Clique de novo para confirmar"
	else
		rebirthButton.Text = "Rebirth " .. Format.money(cost) .. " → +" .. nextBonus .. "% renda"
	end
	rebirthButton.BackgroundTransparency = if money >= cost then 0 else 0.5
end
player:GetAttributeChangedSignal("Money"):Connect(refresh)
player:GetAttributeChangedSignal("Income"):Connect(refresh)
player:GetAttributeChangedSignal("Rebirths"):Connect(refresh)
refresh()

local requestRebirth = Net.event("RequestRebirth")
rebirthButton.Activated:Connect(function()
	-- Pede confirmação: o rebirth apaga os carros e o dinheiro.
	if os.clock() < confirmUntil then
		confirmUntil = 0
		requestRebirth:FireServer()
	else
		confirmUntil = os.clock() + 3
		task.delay(3.1, refresh)
	end
	refresh()
end)

-- Notificações (topo da tela)
local toasts = Instance.new("Frame")
toasts.Name = "Toasts"
toasts.AnchorPoint = Vector2.new(0.5, 0)
toasts.Position = UDim2.new(0.5, 0, 0, 12)
toasts.Size = UDim2.fromOffset(460, 300)
toasts.BackgroundTransparency = 1
toasts.Parent = gui

local list = Instance.new("UIListLayout")
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.Padding = UDim.new(0, 6)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = toasts

local KIND_COLORS = {
	info = Color3.fromRGB(30, 30, 40),
	error = Color3.fromRGB(150, 30, 40),
	rare = Color3.fromRGB(160, 90, 0),
}

local order = 0
local function showToast(text: string, kind: string?)
	order += 1
	local toast = Instance.new("TextLabel")
	toast.LayoutOrder = order
	toast.Size = UDim2.fromOffset(460, 36)
	toast.BackgroundColor3 = KIND_COLORS[kind or "info"] or KIND_COLORS.info
	toast.BackgroundTransparency = 0.15
	toast.Font = Enum.Font.GothamBold
	toast.TextSize = 18
	toast.TextWrapped = true
	toast.TextColor3 = Color3.new(1, 1, 1)
	toast.Text = text
	toast.Parent = toasts
	Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 8)

	task.delay(3.5, function()
		local fade = TweenInfo.new(0.4)
		TweenService:Create(toast, fade, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		task.wait(0.4)
		toast:Destroy()
	end)
end

Net.event("Notify").OnClientEvent:Connect(showToast)
