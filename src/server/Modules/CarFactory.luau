-- Monta o modelo 3D provisório de um carro a partir da configuração.
-- Quando tivermos modelos de verdade, basta trocar esta função por um clone
-- de ServerStorage.CarModels[carId].
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cars = require(Shared.Config.Cars)
local Rarities = require(Shared.Config.Rarities)
local Mutations = require(Shared.Config.Mutations)
local Format = require(Shared.Format)

local CarFactory = {}

CarFactory.Length = 11
CarFactory.Width = 5.5

local function makePart(model: Model, name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

local function makeLabel(parent: Instance, order: number, text: string, color: Color3, height: number)
	local label = Instance.new("TextLabel")
	label.LayoutOrder = order
	label.Size = UDim2.new(1, 0, height, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = parent
	return label
end

-- Retorna um Model com o pivô no chão, centralizado, com a frente para +X.
function CarFactory.build(carId: string, mutationName: string?, showPrice: boolean?): Model
	local car = Cars.get(carId)
	assert(car, "Carro desconhecido: " .. tostring(carId))

	local rarity = Rarities.get(car.rarity)
	local mutation = Mutations.get(mutationName)

	local model = Instance.new("Model")
	model.Name = car.name

	local bodyColor = (mutation and mutation.color) or car.color
	local body = makePart(model, "Body", Vector3.new(CarFactory.Length, 2.5, CarFactory.Width), CFrame.new(0, 2.25, 0), bodyColor)
	if mutation then
		body.Material = mutation.material
	end

	local cabin = makePart(model, "Cabin", Vector3.new(6, 2, 5), CFrame.new(-0.5, 4.5, 0), Color3.fromRGB(40, 60, 80))
	cabin.Material = Enum.Material.Glass
	cabin.Transparency = 0.3

	local wheelRotation = CFrame.Angles(0, math.rad(90), 0)
	for _, x in { -3.5, 3.5 } do
		for _, z in { -2.9, 2.9 } do
			local wheel = makePart(model, "Wheel", Vector3.new(1, 2, 2), CFrame.new(x, 1, z) * wheelRotation, Color3.fromRGB(25, 25, 25))
			wheel.Shape = Enum.PartType.Cylinder
		end
	end

	model.PrimaryPart = body
	model.WorldPivot = CFrame.new()

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Info"
	billboard.Size = UDim2.fromOffset(200, showPrice and 90 or 70)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
	billboard.MaxDistance = 90
	billboard.Adornee = body
	billboard.Parent = body

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = billboard

	local rows = showPrice and 4 or 3
	local title = mutation and (mutation.name .. " " .. car.name) or car.name
	makeLabel(billboard, 1, title, Color3.new(1, 1, 1), 1 / rows)
	makeLabel(billboard, 2, car.rarity, rarity.color, 1 / rows)
	local income = car.income * Mutations.multiplier(mutationName)
	makeLabel(billboard, 3, Format.money(income) .. "/s", Color3.fromRGB(120, 255, 120), 1 / rows)
	if showPrice then
		makeLabel(billboard, 4, Format.money(car.price), Color3.fromRGB(255, 230, 90), 1 / rows)
	end

	model:SetAttribute("CarId", carId)
	model:SetAttribute("Mutation", mutationName)

	return model
end

return CarFactory
