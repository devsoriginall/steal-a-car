-- Formato 3D de cada carro (usado pelo CarFactory). Medidas em studs.
-- Campos (todos opcionais, com valores padrão no CarFactory):
--   length, width        tamanho da carroceria (máx. 12 x 6 para caber na vaga)
--   bodyHeight           altura da carroceria
--   wheel                raio da roda;  rearWheel: raio da roda traseira, se diferente
--   cabinLength, cabinHeight, cabinOffset (+ = mais para a frente)
--   windshield, rearSlope comprimento das inclinações dos vidros (0 = reto)
--   roofColor            cor do teto (para carros de duas cores)
--   extras               lista de detalhes (ver CarFactory)
local CarStyles = {
	fuscao = { length = 9, width = 5, bodyHeight = 1.5, cabinLength = 4.6, cabinHeight = 2, cabinOffset = -0.6, windshield = 1.4, rearSlope = 2.4, extras = { "roundLights" } },
	kombi = { length = 10, width = 5.5, bodyHeight = 2, cabinLength = 9.4, cabinHeight = 2.6, cabinOffset = 0, windshield = 0.4, rearSlope = 0.2, roofColor = Color3.fromRGB(245, 245, 240), extras = { "twoTone", "roundLights" } },
	hatch = { length = 9, width = 5.2, cabinLength = 5, cabinHeight = 1.9, cabinOffset = -1.2, windshield = 1.6, rearSlope = 0.4 },
	taxi = { length = 10.5, cabinLength = 5, cabinOffset = -0.4, extras = { "taxiSign", "checker" } },
	picape = { length = 11, width = 5.6, bodyHeight = 1.9, wheel = 1.2, cabinLength = 3.6, cabinHeight = 2, cabinOffset = 1.6, windshield = 0.9, rearSlope = 0.1, extras = { "bed", "bullbar" } },

	seda = { length = 11.5, cabinLength = 5.4, cabinHeight = 1.7, cabinOffset = -0.6, windshield = 1.8, rearSlope = 1.6, extras = { "chrome" } },
	jipe = { length = 9.5, width = 5.6, bodyHeight = 2.1, wheel = 1.35, cabinLength = 5.6, cabinHeight = 2.1, cabinOffset = -0.8, windshield = 0.3, rearSlope = 0, extras = { "spareTire", "roofRack", "bullbar" } },
	van = { length = 11.5, width = 5.8, bodyHeight = 2.2, cabinLength = 9.5, cabinHeight = 3, cabinOffset = -0.9, windshield = 1.2, rearSlope = 0, extras = { "sideStripe" } },
	compacto = { length = 9.5, width = 5.2, bodyHeight = 1.3, wheel = 0.95, cabinLength = 4.4, cabinHeight = 1.4, cabinOffset = -0.6, windshield = 2, rearSlope = 1.2, extras = { "spoiler", "stripes" } },

	muscle = { length = 11, width = 5.6, bodyHeight = 1.6, rearWheel = 1.15, cabinLength = 4.2, cabinHeight = 1.5, cabinOffset = -1.6, windshield = 1.6, rearSlope = 1.6, extras = { "stripes", "hoodScoop", "exhaust" } },
	rally = { length = 9.5, width = 5.4, bodyHeight = 1.6, wheel = 1.1, cabinLength = 5, cabinHeight = 1.8, cabinOffset = -1, windshield = 1.5, rearSlope = 0.6, extras = { "spoiler", "roofLights", "number", "mudFlaps" } },
	limo = { length = 12, width = 5.4, bodyHeight = 1.5, cabinLength = 8.4, cabinHeight = 1.7, cabinOffset = -0.4, windshield = 1.6, rearSlope = 1.2, extras = { "chrome" } },
	monstro = { length = 10.5, width = 6, bodyHeight = 2.2, wheel = 2.3, cabinLength = 4, cabinHeight = 2, cabinOffset = 0.8, windshield = 0.8, rearSlope = 0.1, extras = { "bed", "lightbar", "bullbar" } },

	supercarro = { length = 11, width = 5.8, bodyHeight = 1.1, wheel = 0.95, cabinLength = 4, cabinHeight = 1.2, cabinOffset = -0.2, windshield = 2.2, rearSlope = 1.8, extras = { "spoiler", "sideIntakes", "underglow" } },
	hotrod = { length = 10, width = 5.2, bodyHeight = 1.4, wheel = 0.95, rearWheel = 1.45, cabinLength = 3.4, cabinHeight = 1.8, cabinOffset = -1.8, windshield = 0.3, rearSlope = 0.5, extras = { "flames", "engine", "exhaust" } },
	gt = { length = 11.5, width = 5.8, bodyHeight = 1.15, wheel = 1, cabinLength = 4.2, cabinHeight = 1.3, cabinOffset = -0.6, windshield = 2, rearSlope = 2, extras = { "bigSpoiler", "stripes", "number", "underglow" } },

	formula = { shape = "formula", length = 12, width = 5.8, wheel = 1.1, extras = { "underglow" } },
	hipercarro = { length = 11.5, width = 6, bodyHeight = 1, wheel = 1, cabinLength = 3.8, cabinHeight = 1.15, cabinOffset = 0, windshield = 2.4, rearSlope = 2.2, extras = { "bigSpoiler", "sideIntakes", "underglow", "lightStrip" } },
	foguete = { length = 11.5, width = 5.4, bodyHeight = 1.3, wheel = 1, cabinLength = 3.6, cabinHeight = 1.3, cabinOffset = 1, windshield = 2, rearSlope = 1.4, extras = { "rocket", "fins", "underglow" } },

	voador = { length = 11, width = 5.6, bodyHeight = 1.3, wheel = 0.9, cabinLength = 4.4, cabinHeight = 1.5, cabinOffset = 0, windshield = 2, rearSlope = 2, extras = { "wings", "hoverJets", "underglow", "lightStrip" } },
}

return CarStyles
