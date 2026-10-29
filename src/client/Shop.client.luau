-- Loja de Robux: botão no canto direito que abre a lista de game passes e
-- produtos. A compra em si é pedida ao servidor, que abre a janela do Roblox.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Products = require(Shared.Config.Products)
local Net = require(Shared.Net)

local player = Players.LocalPlayer
local requestPurchase = Net.event("RequestPurchase")

local gui = Instance.new("ScreenGui")
gui.Name = "Shop"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local openButton = Instance.new("TextButton")
openButton.Name = "OpenShop"
openButton.AnchorPoint = Vector2.new(1, 0.5)
openButton.Position = UDim2.new(1, -16, 0.5, 0)
openButton.Size = UDim2.fromOffset(110, 50)
openButton.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
openButton.Font = Enum.Font.GothamBlack
openButton.TextScaled = true
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.Text = "🛒 Loja"
openButton.Parent = gui
Instance.new("UICorner", openButton).CornerRadius = UDim.new(0, 12)

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(520, 440)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(520, 440)
constraint.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 44)
title.Position = UDim2.fromOffset(16, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "Loja"
title.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -10, 0, 10)
closeButton.Size = UDim2.fromOffset(40, 40)
closeButton.BackgroundColor3 = Color3.fromRGB(150, 30, 40)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextScaled = true
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Text = "X"
closeButton.Parent = panel
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 8)

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(12, 60)
list.Size = UDim2.new(1, -24, 1, -72)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local buyButtons = {} -- [item] = TextButton

local function refreshButton(item)
	local button = buyButtons[item]
	if item.id == 0 then
		button.Text = "Em breve"
		button.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
	elseif item.kind == "pass" and player:GetAttribute("Pass_" .. item.key) then
		button.Text = "Comprado"
		button.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
	else
		button.Text = "R$ " .. item.robux
		button.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
	end
end

local function addSection(order: number, text: string)
	local label = Instance.new("TextLabel")
	label.LayoutOrder = order
	label.Size = UDim2.new(1, -8, 0, 28)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 20
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(255, 230, 90)
	label.Text = text
	label.Parent = list
end

local function addItem(order: number, item)
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -8, 0, 64)
	row.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	row.Parent = list
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

	local name = Instance.new("TextLabel")
	name.Position = UDim2.fromOffset(12, 6)
	name.Size = UDim2.new(1, -150, 0, 26)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextSize = 20
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextColor3 = Color3.new(1, 1, 1)
	name.Text = item.name
	name.Parent = row

	local description = Instance.new("TextLabel")
	description.Position = UDim2.fromOffset(12, 32)
	description.Size = UDim2.new(1, -150, 0, 24)
	description.BackgroundTransparency = 1
	description.Font = Enum.Font.Gotham
	description.TextSize = 15
	description.TextWrapped = true
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextColor3 = Color3.fromRGB(200, 200, 210)
	description.Text = item.description
	description.Parent = row

	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -10, 0.5, 0)
	button.Size = UDim2.fromOffset(120, 42)
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 18
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = row
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
	buyButtons[item] = button
	refreshButton(item)

	button.Activated:Connect(function()
		if item.id ~= 0 then
			requestPurchase:FireServer(item.key)
		end
	end)

	if item.kind == "pass" then
		player:GetAttributeChangedSignal("Pass_" .. item.key):Connect(function()
			refreshButton(item)
		end)
	end
end

local order = 0
local function nextOrder()
	order += 1
	return order
end

addSection(nextOrder(), "Game passes (para sempre)")
for _, item in Products.Passes do
	addItem(nextOrder(), item)
end
addSection(nextOrder(), "Itens")
for _, item in Products.DevProducts do
	addItem(nextOrder(), item)
end

openButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)
closeButton.Activated:Connect(function()
	panel.Visible = false
end)
