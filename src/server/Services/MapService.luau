-- Gera o mapa provisório: chão, esteira no centro e garagens em círculo.
-- Assim o jogo funciona sem precisar montar nada no Studio. Quando o mapa
-- de verdade estiver pronto, ele pode substituir este gerador.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local MapService = {}

local GARAGE_RADIUS = 110
local GARAGE_WIDTH = 44
local GARAGE_DEPTH = 50
local WALL_HEIGHT = 12
local SLOT_COLUMNS = 3
local SLOT_SPACING_X = 13
local SLOT_SPACING_Z = 7

MapService.Garages = {} -- lista de { index, cframe, model, slots = { [n] = CFrame } }
MapService.ConveyorStart = nil :: CFrame?
MapService.ConveyorEnd = nil :: CFrame?

local function makePart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Posição local de uma vaga: 3 colunas, fileiras da frente para o fundo.
local function slotOffset(slotIndex: number): CFrame
	local column = (slotIndex - 1) % SLOT_COLUMNS
	local row = math.floor((slotIndex - 1) / SLOT_COLUMNS)
	local x = (column - 1) * SLOT_SPACING_X
	local z = -GARAGE_DEPTH / 2 + 8 + row * SLOT_SPACING_Z
	return CFrame.new(x, 1, z)
end

local function buildGarage(mapFolder: Folder, index: number)
	local angle = (index - 1) / GameConfig.GarageCount * math.pi * 2
	local position = Vector3.new(math.cos(angle) * GARAGE_RADIUS, 0, math.sin(angle) * GARAGE_RADIUS)
	-- A frente aberta da garagem (-Z local) aponta para a esteira no centro.
	local cframe = CFrame.lookAt(position, Vector3.new(0, 0, 0))

	local model = Instance.new("Model")
	model.Name = "Garage" .. index
	model:SetAttribute("GarageIndex", index)

	local floorColor = Color3.fromRGB(90, 90, 100)
	local wallColor = Color3.fromRGB(150, 150, 160)
	makePart(model, "Floor", Vector3.new(GARAGE_WIDTH, 1, GARAGE_DEPTH), cframe * CFrame.new(0, 0.5, 0), floorColor, Enum.Material.Concrete)
	makePart(model, "BackWall", Vector3.new(GARAGE_WIDTH, WALL_HEIGHT, 1), cframe * CFrame.new(0, WALL_HEIGHT / 2 + 1, GARAGE_DEPTH / 2), wallColor)
	makePart(model, "LeftWall", Vector3.new(1, WALL_HEIGHT, GARAGE_DEPTH), cframe * CFrame.new(-GARAGE_WIDTH / 2, WALL_HEIGHT / 2 + 1, 0), wallColor)
	makePart(model, "RightWall", Vector3.new(1, WALL_HEIGHT, GARAGE_DEPTH), cframe * CFrame.new(GARAGE_WIDTH / 2, WALL_HEIGHT / 2 + 1, 0), wallColor)

	-- Placa com o nome do dono
	local sign = makePart(model, "Sign", Vector3.new(1, 1, 1), cframe * CFrame.new(0, WALL_HEIGHT + 4, -GARAGE_DEPTH / 2), Color3.new(), nil)
	sign.Transparency = 1
	sign.CanCollide = false
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OwnerSign"
	billboard.Size = UDim2.fromOffset(300, 50)
	billboard.MaxDistance = 250
	billboard.Parent = sign
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Text = "Garagem livre"
	label.Parent = billboard

	-- Botão de comprar vaga, no canto do fundo
	local button = makePart(model, "SlotButton", Vector3.new(2, 3, 2), cframe * CFrame.new(-GARAGE_WIDTH / 2 + 2, 2.5, GARAGE_DEPTH / 2 - 2), Color3.fromRGB(0, 200, 120), Enum.Material.Neon)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuySlotPrompt"
	prompt.ActionText = "Comprar vaga"
	prompt.ObjectText = ""
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("OwnerOnly", true)
	prompt.Parent = button

	-- Marcações das vagas no chão
	local slots = {}
	local slotsFolder = Instance.new("Folder")
	slotsFolder.Name = "Slots"
	slotsFolder.Parent = model
	for slotIndex = 1, GameConfig.MaxSlots do
		local slotCFrame = cframe * slotOffset(slotIndex)
		slots[slotIndex] = slotCFrame
		local marker = makePart(slotsFolder, "Slot" .. slotIndex, Vector3.new(12, 0.1, 6), slotCFrame * CFrame.new(0, 0.05, 0), Color3.fromRGB(255, 255, 255))
		marker.Transparency = 0.8
		marker.CanCollide = false
	end

	local carsFolder = Instance.new("Folder")
	carsFolder.Name = "Cars"
	carsFolder.Parent = model

	model.Parent = mapFolder

	table.insert(MapService.Garages, {
		index = index,
		cframe = cframe,
		model = model,
		slots = slots,
		carsFolder = carsFolder,
		ownerLabel = label,
		slotPrompt = prompt,
		spawnCFrame = cframe * CFrame.new(0, 4, -GARAGE_DEPTH / 2 + 3) * CFrame.Angles(0, math.pi, 0),
	})
end

function MapService.Init()
	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	mapFolder.Parent = Workspace

	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end
	makePart(mapFolder, "Ground", Vector3.new(400, 2, 400), CFrame.new(0, -1, 0), Color3.fromRGB(70, 140, 70), Enum.Material.Grass)

	-- Esteira ao longo do eixo X, no centro do mapa
	local length = GameConfig.ConveyorLength
	makePart(mapFolder, "Conveyor", Vector3.new(length, 1, 10), CFrame.new(0, 0.5, 0), Color3.fromRGB(35, 35, 40), Enum.Material.DiamondPlate)
	MapService.ConveyorStart = CFrame.new(-length / 2, 1, 0)
	MapService.ConveyorEnd = CFrame.new(length / 2, 1, 0)

	for index = 1, GameConfig.GarageCount do
		buildGarage(mapFolder, index)
	end
end

return MapService
