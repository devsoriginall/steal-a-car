-- Monta o modelo 3D de cada carro a partir de peças simples, usando o
-- formato definido em Config/CarStyles.luau. Cada carro tem silhueta própria,
-- faróis, rodas com aro e detalhes (aerofólio, faixas, foguete...).
-- Raridades altas e mutações ganham brilho e partículas.
--
-- Modelos prontos: se existir ServerStorage.CarModels.<id do carro> (por
-- exemplo ServerStorage.CarModels.fuscao), ele é usado no lugar do modelo
-- gerado. Veja "Usar modelos 3D prontos" no README.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cars = require(Shared.Config.Cars)
local CarStyles = require(Shared.Config.CarStyles)
local Rarities = require(Shared.Config.Rarities)
local Mutations = require(Shared.Config.Mutations)
local Format = require(Shared.Format)

local CarFactory = {}

local DEFAULT_STYLE = {
	length = 10.5,
	width = 5.4,
	bodyHeight = 1.6,
	wheel = 1,
	cabinLength = 5,
	cabinHeight = 1.7,
	cabinOffset = -0.5,
	windshield = 1.5,
	rearSlope = 1.2,
	extras = {},
}

local DARK = Color3.fromRGB(30, 30, 34)
local TIRE = Color3.fromRGB(22, 22, 22)
local SILVER = Color3.fromRGB(200, 200, 210)
local GLASS = Color3.fromRGB(35, 55, 75)

-- Inclinações (WedgePart): a parte baixa da cunha aponta para a frente (+X) ou para trás (-X).
local SLOPE_FRONT = CFrame.Angles(0, math.rad(-90), 0)
local SLOPE_BACK = CFrame.Angles(0, math.rad(90), 0)
-- Cilindros: o eixo padrão é X; estas rotações apontam o eixo para Z ou Y.
local AXIS_Z = CFrame.Angles(0, math.rad(90), 0)
local AXIS_Y = CFrame.Angles(0, 0, math.rad(90))

local function contrast(color: Color3): Color3
	local brightness = color.R * 0.3 + color.G * 0.59 + color.B * 0.11
	return if brightness > 0.6 then Color3.fromRGB(25, 25, 25) else Color3.fromRGB(245, 245, 245)
end

-- Cria e guarda as peças de um carro em construção.
local Builder = {}
Builder.__index = Builder

function Builder.new(model: Model)
	return setmetatable({ model = model, paint = {} }, Builder)
end

function Builder:part(name: string, size: Vector3, cframe: CFrame, color: Color3, options: { [string]: any }?): BasePart
	options = options or {}
	local part
	if options.wedge then
		part = Instance.new("WedgePart")
	else
		part = Instance.new("Part")
		if options.shape then
			part.Shape = options.shape
		end
	end
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = options.material or Enum.Material.SmoothPlastic
	part.Transparency = options.transparency or 0
	part.Reflectance = options.reflectance or 0
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = options.shadow ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = self.model
	if options.paint then
		table.insert(self.paint, part)
	end
	return part
end

function Builder:light(parent: BasePart, color: Color3, range: number, brightness: number?)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness or 1.5
	light.Parent = parent
end

function Builder:particles(parent: BasePart, color: Color3, rate: number, size: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(0.8, 1.6)
	emitter.Speed = NumberRange.new(1, 2.5)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new(0.2)
	emitter.Parent = parent
end

function Builder:wheel(x: number, z: number, radius: number, width: number?)
	local tireWidth = width or 0.9
	local cframe = CFrame.new(x, radius, z) * AXIS_Z
	self:part("Tire", Vector3.new(tireWidth, radius * 2, radius * 2), cframe, TIRE, { shape = Enum.PartType.Cylinder })
	local side = if z > 0 then 1 else -1
	local rimCFrame = CFrame.new(x, radius, z + side * 0.05) * AXIS_Z
	self:part("Rim", Vector3.new(tireWidth + 0.02, radius * 1.15, radius * 1.15), rimCFrame, SILVER, { shape = Enum.PartType.Cylinder, material = Enum.Material.Metal })
	self:part("Hub", Vector3.new(tireWidth + 0.06, radius * 0.4, radius * 0.4), rimCFrame, DARK, { shape = Enum.PartType.Cylinder })
end

-- Carroceria padrão (sedã, hatch, picape, van, esportivo...).
local function buildStandard(b, style, color: Color3)
	local L, W = style.length, style.width
	local frontWheel = style.wheel
	local rearWheel = style.rearWheel or style.wheel
	local bottom = math.max(frontWheel, rearWheel) * 0.7
	local bh = style.bodyHeight
	local top = bottom + bh

	-- Carroceria
	local body = b:part("Body", Vector3.new(L, bh, W), CFrame.new(0, bottom + bh / 2, 0), color, { paint = true })

	-- Para-choques e grade
	local bumperColor = if table.find(style.extras, "chrome") then SILVER else DARK
	local bumperMaterial = if table.find(style.extras, "chrome") then Enum.Material.Metal else Enum.Material.SmoothPlastic
	b:part("FrontBumper", Vector3.new(0.4, bh * 0.4, W + 0.1), CFrame.new(L / 2 - 0.1, bottom + bh * 0.2, 0), bumperColor, { material = bumperMaterial })
	b:part("RearBumper", Vector3.new(0.4, bh * 0.4, W + 0.1), CFrame.new(-L / 2 + 0.1, bottom + bh * 0.2, 0), bumperColor, { material = bumperMaterial })
	b:part("Grille", Vector3.new(0.1, bh * 0.35, W * 0.4), CFrame.new(L / 2 + 0.05, bottom + bh * 0.55, 0), DARK)

	-- Faróis e lanternas
	local round = table.find(style.extras, "roundLights")
	for _, z in { -1, 1 } do
		local lightZ = z * (W / 2 - 0.9)
		if round then
			b:part("Headlight", Vector3.new(0.15, 0.7, 0.7), CFrame.new(L / 2 + 0.05, top - 0.45, lightZ), Color3.fromRGB(255, 250, 220), { shape = Enum.PartType.Cylinder, material = Enum.Material.Neon })
		else
			b:part("Headlight", Vector3.new(0.15, 0.35, 1), CFrame.new(L / 2 + 0.05, top - 0.35, lightZ), Color3.fromRGB(255, 250, 220), { material = Enum.Material.Neon })
		end
		b:part("Taillight", Vector3.new(0.15, 0.35, 0.9), CFrame.new(-L / 2 - 0.05, top - 0.35, lightZ), Color3.fromRGB(220, 20, 20), { material = Enum.Material.Neon })
	end

	-- Cabine: vidro central, teto pintado e vidros inclinados na frente e atrás
	local c, cl, ch = style.cabinOffset, style.cabinLength, style.cabinHeight
	local ws = math.min(style.windshield, cl * 0.45)
	local rs = math.min(style.rearSlope, cl * 0.45)
	local boxLength = math.max(0.4, cl - ws - rs)
	local boxCenter = c - cl / 2 + rs + boxLength / 2
	local glassWidth = W - 0.5
	b:part("Windows", Vector3.new(boxLength, ch - 0.2, glassWidth), CFrame.new(boxCenter, top + (ch - 0.2) / 2, 0), GLASS, { material = Enum.Material.Glass, transparency = 0.2 })
	b:part("Roof", Vector3.new(boxLength + 0.1, 0.22, glassWidth + 0.1), CFrame.new(boxCenter, top + ch - 0.11, 0), style.roofColor or color, { paint = style.roofColor == nil })
	if ws > 0.05 then
		b:part("Windshield", Vector3.new(glassWidth, ch, ws), CFrame.new(c + cl / 2 - ws / 2, top + ch / 2, 0) * SLOPE_FRONT, GLASS, { wedge = true, material = Enum.Material.Glass, transparency = 0.15 })
	end
	if rs > 0.05 then
		b:part("RearWindow", Vector3.new(glassWidth, ch, rs), CFrame.new(c - cl / 2 + rs / 2, top + ch / 2, 0) * SLOPE_BACK, GLASS, { wedge = true, material = Enum.Material.Glass, transparency = 0.15 })
	end

	-- Rodas
	local frontX = L / 2 - frontWheel - 0.5
	local rearX = -L / 2 + rearWheel + 0.5
	for _, z in { -1, 1 } do
		b:wheel(frontX, z * (W / 2 - 0.3), frontWheel)
		b:wheel(rearX, z * (W / 2 - 0.3), rearWheel, if rearWheel > frontWheel then 1.2 else nil)
	end

	return {
		body = body,
		bottom = bottom,
		top = top,
		roofTop = top + ch,
		hoodX = (c + cl / 2 + L / 2) / 2, -- meio do capô
		cabinRear = c - cl / 2,
		boxCenter = boxCenter,
		boxLength = boxLength,
	}
end

-- Fórmula 1: corpo estreito, rodas expostas e asas.
local function buildFormula(b, style, color: Color3)
	local L, W, r = style.length, style.width, style.wheel
	local y = r * 0.85
	local body = b:part("Body", Vector3.new(L * 0.55, 0.9, 2), CFrame.new(-0.4, y, 0), color, { paint = true })
	b:part("Nose", Vector3.new(1.6, 0.8, 3), CFrame.new(L * 0.275 - 0.4 + 1.5, y - 0.05, 0) * SLOPE_FRONT, color, { wedge = true, paint = true })
	for _, z in { -1, 1 } do
		b:part("Sidepod", Vector3.new(3.2, 0.8, 1.1), CFrame.new(-0.8, y - 0.05, z * 1.5), color, { paint = true })
	end
	b:part("Cockpit", Vector3.new(1.6, 0.2, 1.1), CFrame.new(0.4, y + 0.5, 0), DARK)
	b:part("Helmet", Vector3.new(0.9, 0.9, 0.9), CFrame.new(0.3, y + 0.85, 0), Color3.fromRGB(255, 220, 0), { shape = Enum.PartType.Ball })
	b:part("Airbox", Vector3.new(1.4, 1, 0.7), CFrame.new(-0.9, y + 0.9, 0), color, { paint = true })
	b:part("FrontWing", Vector3.new(0.9, 0.15, W), CFrame.new(L / 2 - 0.5, 0.45, 0), DARK)
	b:part("RearWing", Vector3.new(1, 0.25, W - 1.2), CFrame.new(-L / 2 + 0.6, 2.6, 0), color, { paint = true })
	for _, z in { -1, 1 } do
		b:part("WingPlate", Vector3.new(1.2, 1.2, 0.12), CFrame.new(-L / 2 + 0.6, 2.2, z * (W / 2 - 0.6)), DARK)
		b:part("FrontPlate", Vector3.new(1, 0.5, 0.12), CFrame.new(L / 2 - 0.5, 0.6, z * (W / 2)), DARK)
	end
	b:part("WingPost", Vector3.new(0.3, 1.4, 0.2), CFrame.new(-L / 2 + 0.7, 1.7, 0), DARK)
	b:part("Taillight", Vector3.new(0.12, 0.3, 0.5), CFrame.new(-L / 2 + 0.2, 1.6, 0), Color3.fromRGB(220, 20, 20), { material = Enum.Material.Neon })
	for _, z in { -1, 1 } do
		b:wheel(L / 2 - 2.2, z * (W / 2 - 0.55), r, 1)
		b:wheel(-L / 2 + 2, z * (W / 2 - 0.55), r * 1.15, 1.3)
	end
	return { body = body, bottom = 0.3, top = y + 0.45, roofTop = 3, hoodX = 2, cabinRear = -1, boxCenter = 0, boxLength = 2 }
end

-- Detalhes opcionais, aplicados por nome (campo "extras" do estilo).
local EXTRAS = {}

function EXTRAS.taxiSign(b, s, info)
	b:part("TaxiSign", Vector3.new(1.4, 0.5, 0.8), CFrame.new(info.boxCenter, info.roofTop + 0.25, 0), Color3.fromRGB(255, 220, 40), { material = Enum.Material.Neon })
end

function EXTRAS.checker(b, s, info)
	for i = 0, 9 do
		local x = -s.length * 0.4 + i * (s.length * 0.8 / 9)
		local color = if i % 2 == 0 then Color3.new(0, 0, 0) else Color3.new(1, 1, 1)
		for _, z in { -1, 1 } do
			b:part("Checker", Vector3.new(s.length * 0.08, 0.35, 0.05), CFrame.new(x, info.bottom + s.bodyHeight * 0.55, z * (s.width / 2 + 0.03)), color)
		end
	end
end

function EXTRAS.twoTone(b, s, info)
	b:part("TwoTone", Vector3.new(s.length + 0.02, s.bodyHeight * 0.35, s.width + 0.02), CFrame.new(0, info.top - s.bodyHeight * 0.175, 0), s.roofColor or Color3.new(1, 1, 1))
end

function EXTRAS.bed(b, s, info)
	local rear, front = -s.length / 2, info.cabinRear
	local length = front - rear
	local center = (front + rear) / 2
	b:part("BedFloor", Vector3.new(length - 0.3, 0.1, s.width - 0.5), CFrame.new(center, info.top + 0.05, 0), DARK)
	for _, z in { -1, 1 } do
		b:part("BedWall", Vector3.new(length, 0.8, 0.25), CFrame.new(center, info.top + 0.4, z * (s.width / 2 - 0.125)), Color3.new(), { paint = true })
	end
	b:part("Tailgate", Vector3.new(0.25, 0.8, s.width), CFrame.new(rear + 0.125, info.top + 0.4, 0), Color3.new(), { paint = true })
end

function EXTRAS.bullbar(b, s, info)
	b:part("Bullbar", Vector3.new(0.3, s.bodyHeight + 0.3, s.width * 0.7), CFrame.new(s.length / 2 + 0.3, info.bottom + s.bodyHeight / 2, 0), DARK, { material = Enum.Material.DiamondPlate })
end

function EXTRAS.chrome(b, s, info)
	b:part("ChromeStrip", Vector3.new(s.length * 0.92, 0.12, s.width + 0.04), CFrame.new(0, info.bottom + s.bodyHeight * 0.45, 0), SILVER, { material = Enum.Material.Metal, reflectance = 0.2 })
end

function EXTRAS.spareTire(b, s, info)
	b:part("SpareTire", Vector3.new(0.6, 1.9, 1.9), CFrame.new(-s.length / 2 - 0.35, info.bottom + s.bodyHeight * 0.65, 0), TIRE, { shape = Enum.PartType.Cylinder })
	b:part("SpareRim", Vector3.new(0.62, 1.1, 1.1), CFrame.new(-s.length / 2 - 0.36, info.bottom + s.bodyHeight * 0.65, 0), SILVER, { shape = Enum.PartType.Cylinder, material = Enum.Material.Metal })
end

function EXTRAS.roofRack(b, s, info)
	local y = info.roofTop + 0.25
	for _, z in { -1, 1 } do
		b:part("RackRail", Vector3.new(info.boxLength + 0.6, 0.15, 0.15), CFrame.new(info.boxCenter, y, z * (s.width / 2 - 0.6)), DARK)
	end
	for i = -1, 1 do
		b:part("RackBar", Vector3.new(0.15, 0.15, s.width - 1.1), CFrame.new(info.boxCenter + i * info.boxLength * 0.35, y, 0), DARK)
	end
end

function EXTRAS.sideStripe(b, s, info)
	b:part("SideStripe", Vector3.new(s.length * 0.96, 0.35, s.width + 0.04), CFrame.new(0, info.bottom + s.bodyHeight * 0.5, 0), Color3.fromRGB(230, 40, 40))
end

function EXTRAS.spoiler(b, s, info)
	b:part("Spoiler", Vector3.new(1, 0.15, s.width - 0.4), CFrame.new(-s.length / 2 + 0.6, info.top + 0.75, 0), DARK)
	for _, z in { -1, 1 } do
		b:part("SpoilerPost", Vector3.new(0.2, 0.7, 0.15), CFrame.new(-s.length / 2 + 0.6, info.top + 0.35, z * (s.width / 2 - 1.1)), DARK)
	end
end

function EXTRAS.bigSpoiler(b, s, info)
	b:part("Spoiler", Vector3.new(1.5, 0.2, s.width), CFrame.new(-s.length / 2 + 0.7, info.top + 1.3, 0), DARK)
	for _, z in { -1, 1 } do
		b:part("SpoilerPost", Vector3.new(0.25, 1.2, 0.15), CFrame.new(-s.length / 2 + 0.7, info.top + 0.6, z * (s.width / 2 - 1.2)), DARK)
		b:part("SpoilerPlate", Vector3.new(1.6, 0.6, 0.1), CFrame.new(-s.length / 2 + 0.7, info.top + 1.2, z * (s.width / 2)), DARK)
	end
end

function EXTRAS.stripes(b, s, info, color)
	local stripeColor = contrast(color)
	for _, z in { -0.45, 0.45 } do
		b:part("Stripe", Vector3.new(s.length * 0.98, 0.05, 0.5), CFrame.new(0, info.top + 0.025, z), stripeColor)
		b:part("RoofStripe", Vector3.new(info.boxLength, 0.05, 0.5), CFrame.new(info.boxCenter, info.roofTop + 0.025, z), stripeColor)
	end
end

function EXTRAS.hoodScoop(b, s, info)
	b:part("HoodScoop", Vector3.new(1.6, 0.45, 1.4), CFrame.new(info.hoodX, info.top + 0.22, 0), DARK)
end

function EXTRAS.exhaust(b, s, info)
	for _, z in { -1, 1 } do
		b:part("Exhaust", Vector3.new(0.8, 0.35, 0.35), CFrame.new(-s.length / 2 - 0.2, info.bottom + 0.2, z * 1.2), SILVER, { shape = Enum.PartType.Cylinder, material = Enum.Material.Metal })
	end
end

function EXTRAS.roofLights(b, s, info)
	for i = -1.5, 1.5 do
		b:part("RoofLight", Vector3.new(0.3, 0.4, 0.5), CFrame.new(info.boxCenter + info.boxLength / 2 - 0.2, info.roofTop + 0.2, i * 0.9), Color3.fromRGB(255, 240, 150), { material = Enum.Material.Neon })
	end
end

function EXTRAS.number(b, s, info)
	for _, side in { -1, 1 } do
		local plate = b:part("NumberPlate", Vector3.new(1.4, 1.1, 0.05), CFrame.new(0, info.bottom + s.bodyHeight * 0.5, side * (s.width / 2 + 0.03)), Color3.new(1, 1, 1))
		local gui = Instance.new("SurfaceGui")
		gui.Face = if side > 0 then Enum.NormalId.Back else Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(140, 110)
		gui.Parent = plate
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = Color3.new(0, 0, 0)
		label.Text = "07"
		label.Parent = gui
	end
end

function EXTRAS.mudFlaps(b, s, info)
	for _, z in { -1, 1 } do
		b:part("MudFlap", Vector3.new(0.08, 0.7, 0.8), CFrame.new(-s.length / 2 + 0.25, info.bottom - 0.1, z * (s.width / 2 - 0.4)), Color3.fromRGB(200, 30, 30))
	end
end

function EXTRAS.lightbar(b, s, info)
	b:part("Lightbar", Vector3.new(0.4, 0.3, s.width - 0.6), CFrame.new(info.boxCenter + info.boxLength / 2 - 0.2, info.roofTop + 0.15, 0), DARK)
	for i = -1.5, 1.5 do
		b:part("LightbarLamp", Vector3.new(0.1, 0.25, 0.7), CFrame.new(info.boxCenter + info.boxLength / 2, info.roofTop + 0.15, i * 1.1), Color3.fromRGB(255, 255, 230), { material = Enum.Material.Neon })
	end
end

function EXTRAS.sideIntakes(b, s, info)
	for _, z in { -1, 1 } do
		b:part("Intake", Vector3.new(1.6, 0.6, 0.08), CFrame.new(-s.length * 0.2, info.bottom + s.bodyHeight * 0.5, z * (s.width / 2 + 0.03)), DARK)
	end
end

function EXTRAS.underglow(b, s, info, color, glow)
	local pad = b:part("Underglow", Vector3.new(s.length * 0.8, 0.1, s.width * 0.8), CFrame.new(0, math.max(0.15, info.bottom - 0.05), 0), glow, { material = Enum.Material.Neon, shadow = false })
	b:light(pad, glow, 10, 2)
end

function EXTRAS.lightStrip(b, s, info, color, glow)
	b:part("LightStrip", Vector3.new(s.length * 0.9, 0.08, s.width + 0.04), CFrame.new(0, info.bottom + s.bodyHeight * 0.4, 0), glow, { material = Enum.Material.Neon, shadow = false })
end

function EXTRAS.flames(b, s, info)
	local colors = { Color3.fromRGB(255, 70, 0), Color3.fromRGB(255, 160, 0), Color3.fromRGB(255, 230, 60) }
	for _, z in { -1, 1 } do
		for i, flameColor in colors do
			local length = 3 - i * 0.6
			b:part("Flame", Vector3.new(length, 0.25, 0.04), CFrame.new(s.length / 2 - length / 2 - 0.3, info.bottom + 0.3 + i * 0.3, z * (s.width / 2 + 0.03)) * CFrame.Angles(0, 0, math.rad(8)), flameColor, { material = Enum.Material.Neon, shadow = false })
		end
	end
end

function EXTRAS.engine(b, s, info)
	b:part("Engine", Vector3.new(1.8, 0.8, 2), CFrame.new(info.hoodX, info.top + 0.4, 0), SILVER, { material = Enum.Material.Metal, reflectance = 0.15 })
	for _, z in { -0.5, 0.5 } do
		b:part("AirIntake", Vector3.new(0.5, 0.6, 0.5), CFrame.new(info.hoodX, info.top + 1.05, z) * AXIS_Y, DARK, { shape = Enum.PartType.Cylinder })
	end
end

function EXTRAS.rocket(b, s, info)
	local y = info.top + 0.3
	local x = -s.length / 2 - 0.8
	b:part("Rocket", Vector3.new(3, 1.6, 1.6), CFrame.new(x + 0.6, y, 0), Color3.fromRGB(170, 170, 185), { shape = Enum.PartType.Cylinder, material = Enum.Material.Metal })
	b:part("Nozzle", Vector3.new(0.6, 1.2, 1.2), CFrame.new(x - 1.1, y, 0), DARK, { shape = Enum.PartType.Cylinder })
	local flame = b:part("RocketFlame", Vector3.new(0.1, 1, 1), CFrame.new(x - 1.45, y, 0), Color3.fromRGB(255, 140, 0), { shape = Enum.PartType.Cylinder, material = Enum.Material.Neon, shadow = false })
	local fire = Instance.new("Fire")
	fire.Size = 3
	fire.Heat = 0
	fire.Color = Color3.fromRGB(255, 120, 0)
	fire.SecondaryColor = Color3.fromRGB(255, 230, 80)
	fire.Parent = flame
	b:light(flame, Color3.fromRGB(255, 140, 0), 12, 2)
end

function EXTRAS.fins(b, s, info, color)
	for _, z in { -1, 1 } do
		b:part("Fin", Vector3.new(0.15, 1.4, 1.8), CFrame.new(-s.length / 2 + 1.1, info.top + 0.7, z * (s.width / 2 - 0.3)) * SLOPE_FRONT, color, { wedge = true, paint = true })
	end
end

function EXTRAS.wings(b, s, info, color)
	for _, z in { -1, 1 } do
		local cframe = CFrame.new(-0.4, info.top - 0.1, z * (s.width / 2 + 0.3)) * CFrame.Angles(math.rad(z * -35), 0, 0)
		b:part("Wing", Vector3.new(3.2, 0.15, 1.1), cframe, color, { paint = true })
	end
end

function EXTRAS.hoverJets(b, s, info, color, glow)
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			local jet = b:part("HoverJet", Vector3.new(0.12, 1.2, 1.2), CFrame.new(x * s.length * 0.3, 0.1, z * (s.width / 2 - 1)) * AXIS_Y, glow, { shape = Enum.PartType.Cylinder, material = Enum.Material.Neon, shadow = false })
			if x == 1 and z == 1 then
				b:light(jet, glow, 10, 2)
			end
		end
	end
end

-- Tamanho máximo de um modelo pronto (para caber na vaga da garagem).
local CUSTOM_MAX_LENGTH = 11.5
local CUSTOM_MAX_WIDTH = 5.8

-- Copia um modelo pronto de ServerStorage.CarModels, remove scripts, deixa a
-- frente virada para +X e ajusta o tamanho para caber na vaga.
local function buildCustom(b, template: Model)
	local clone = template:Clone()
	for _, descendant in clone:GetDescendants() do
		-- Modelos grátis podem trazer scripts (às vezes maliciosos): nunca rodamos nenhum.
		if descendant:IsA("LuaSourceContainer") then
			descendant:Destroy()
		end
	end

	local center, size = clone:GetBoundingBox()
	if size.Magnitude < 0.1 then
		return nil
	end

	-- O lado mais comprido vira o comprimento (eixo X).
	local rotation = CFrame.new()
	local length, width = size.X, size.Z
	if size.Z > size.X then
		rotation = CFrame.Angles(0, math.rad(90), 0)
		length, width = size.Z, size.X
	end
	-- Se o carro ficar de ré, marque o modelo com o atributo Flip = true.
	if template:GetAttribute("Flip") then
		rotation *= CFrame.Angles(0, math.pi, 0)
	end

	clone.WorldPivot = center
	clone:ScaleTo(clone:GetScale() * math.min(CUSTOM_MAX_LENGTH / length, CUSTOM_MAX_WIDTH / width))
	local _, scaledSize = clone:GetBoundingBox()
	clone:PivotTo(CFrame.new(0, scaledSize.Y / 2, 0) * rotation)

	local body, bodyVolume = nil, 0
	local tagged = false
	for _, part in clone:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			local volume = part.Size.X * part.Size.Y * part.Size.Z
			if volume > bodyVolume then
				body, bodyVolume = part, volume
			end
			-- Peças com o atributo Paint = true recebem a cor das mutações.
			if part:GetAttribute("Paint") then
				table.insert(b.paint, part)
				tagged = true
			end
		end
	end
	if not body then
		return nil
	end
	if not tagged then
		table.insert(b.paint, body)
	end

	for _, child in clone:GetChildren() do
		child.Parent = b.model
	end
	clone:Destroy()

	return {
		body = body,
		bottom = 0.5,
		top = scaledSize.Y * 0.6,
		roofTop = scaledSize.Y,
		custom = true,
	}
end

-- Retorna um Model com o pivô no chão, centralizado, com a frente para +X.
function CarFactory.build(carId: string, mutationName: string?, showPrice: boolean?): Model
	local car = Cars.get(carId)
	assert(car, "Carro desconhecido: " .. tostring(carId))

	local rarity = Rarities.get(car.rarity)
	local mutation = Mutations.get(mutationName)

	local style = table.clone(DEFAULT_STYLE)
	for key, value in CarStyles[carId] or {} do
		style[key] = value
	end

	local model = Instance.new("Model")
	model.Name = car.name
	local b = Builder.new(model)

	local customFolder = ServerStorage:FindFirstChild("CarModels")
	local template = customFolder and customFolder:FindFirstChild(carId)
	local info = if template and template:IsA("Model") then buildCustom(b, template) else nil

	if not info then
		info = if style.shape == "formula" then buildFormula(b, style, car.color) else buildStandard(b, style, car.color)
		for _, extra in style.extras do
			local addExtra = EXTRAS[extra]
			if addExtra then
				addExtra(b, style, info, car.color, rarity.color)
			end
		end

		-- Peças das extras sem cor definida (Color3.new()) herdam a cor do carro.
		for _, part in b.paint do
			part.Color = car.color
		end
	end

	-- Mutação: pinta a carroceria e adiciona brilho
	if mutation then
		for _, part in b.paint do
			if mutation.color then
				part.Color = mutation.color
			end
			part.Material = mutation.material
			if mutation.name == "Dourado" then
				part.Reflectance = 0.3
			end
		end
		b:particles(info.body, mutation.color or car.color, 6, 0.4)
	end

	-- Raridade: Épico em diante solta brilho; Lendário e Secreto também iluminam
	if rarity.order >= 4 then
		b:particles(info.body, rarity.color, if rarity.order >= 5 then 8 else 3, 0.35)
	end
	if rarity.order >= 5 then
		b:light(info.body, rarity.color, 14, 1.5)
	end

	model.PrimaryPart = info.body
	model.WorldPivot = CFrame.new()

	-- Placa com nome, raridade, renda e preço
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Info"
	billboard.Size = UDim2.fromOffset(200, if showPrice then 90 else 70)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, info.roofTop + 2.5 - info.body.Position.Y, 0)
	billboard.MaxDistance = 90
	billboard.Adornee = info.body
	billboard.Parent = info.body

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = billboard

	local rows = if showPrice then 4 else 3
	local function addLabel(order: number, text: string, textColor: Color3)
		local label = Instance.new("TextLabel")
		label.LayoutOrder = order
		label.Size = UDim2.new(1, 0, 1 / rows, 0)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = textColor
		label.TextStrokeTransparency = 0.3
		label.Text = text
		label.Parent = billboard
	end

	local title = if mutation then mutation.name .. " " .. car.name else car.name
	addLabel(1, title, Color3.new(1, 1, 1))
	addLabel(2, car.rarity, rarity.color)
	addLabel(3, Format.money(car.income * Mutations.multiplier(mutationName)) .. "/s", Color3.fromRGB(120, 255, 120))
	if showPrice then
		addLabel(4, Format.money(car.price), Color3.fromRGB(255, 230, 90))
	end

	model:SetAttribute("CarId", carId)
	model:SetAttribute("Mutation", mutationName)

	return model
end

return CarFactory
