-- Carrega e salva o progresso dos jogadores no DataStore.
--
-- Formato salvo (versão 1):
-- {
--   money = number,
--   slots = number,                          -- vagas liberadas na garagem
--   cars = { ["1"] = { id = "fuscao", m = "Dourado" }, ... },  -- chave = número da vaga
--   rebirths = number,
-- }
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DataService = {}

local MAX_ATTEMPTS = 3

local store: DataStore? = nil
local profiles = {} -- [Player] = { data = table, canSave = boolean }
local activeSaves = 0

local function defaultData()
	return {
		money = GameConfig.StartingMoney,
		slots = GameConfig.StartingSlots,
		cars = {},
		rebirths = 0,
	}
end

-- Preenche campos que faltam (útil quando adicionarmos campos novos).
local function reconcile(data)
	local defaults = defaultData()
	for key, value in defaults do
		if data[key] == nil then
			data[key] = value
		end
	end
	return data
end

local function withRetries(callback)
	-- No Studio uma tentativa basta: sem acesso à API, esperar só atrasa o teste.
	local attempts = if RunService:IsStudio() then 1 else MAX_ATTEMPTS
	local lastError
	for attempt = 1, attempts do
		local ok, result = pcall(callback)
		if ok then
			return true, result
		end
		lastError = result
		if attempt < attempts then
			task.wait(attempt * 2)
		end
	end
	return false, lastError
end

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

function DataService.Init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(GameConfig.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStore indisponível. O progresso NÃO será salvo.", result)
	end
end

-- Carrega os dados do jogador. Retorna nil se o jogador saiu durante o carregamento.
function DataService.Load(player: Player)
	local data, canSave = nil, false

	if store then
		local ok, result = withRetries(function()
			return store:GetAsync(keyFor(player))
		end)
		if ok then
			data = result
			canSave = true
		elseif RunService:IsStudio() then
			warn("[DataService] Falha ao carregar no Studio. Ative 'Enable Studio Access to API Services'. Usando dados novos sem salvar.", result)
		else
			-- Nunca deixar jogar com dados vazios: salvar por cima apagaria o progresso real.
			player:Kick("Não foi possível carregar seu progresso. Tente entrar de novo em alguns instantes.")
			return nil
		end
	end

	if not player.Parent then
		return nil
	end

	profiles[player] = {
		data = reconcile(data or defaultData()),
		canSave = canSave,
	}
	return profiles[player].data
end

function DataService.Get(player: Player)
	local profile = profiles[player]
	return profile and profile.data
end

function DataService.Save(player: Player)
	local profile = profiles[player]
	if not (profile and profile.canSave and store) then
		return
	end
	activeSaves += 1
	local ok, result = withRetries(function()
		return store:UpdateAsync(keyFor(player), function()
			return profile.data
		end)
	end)
	activeSaves -= 1
	if not ok then
		warn("[DataService] Falha ao salvar", player.Name, result)
	end
end

-- Salva e esquece o jogador (chamado quando ele sai).
function DataService.Release(player: Player)
	DataService.Save(player)
	profiles[player] = nil
end

function DataService.Start()
	task.spawn(function()
		while true do
			task.wait(GameConfig.AutosaveInterval)
			for player in profiles do
				task.spawn(DataService.Save, player)
			end
		end
	end)

	-- Quando o servidor fecha, salva todo mundo antes de desligar.
	-- Quando o servidor fecha, salva todo mundo antes de desligar
	-- (inclusive esperando saves que já estavam em andamento).
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			if profiles[player] then
				task.spawn(DataService.Save, player)
			end
		end
		task.wait()
		while activeSaves > 0 do
			task.wait()
		end
	end)
end

return DataService
