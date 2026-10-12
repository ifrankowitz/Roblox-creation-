--[[
	PlayerData
	Loads and saves each player's progress with DataStoreService.
	Phase 1 saves the chosen shop style and sparkle count. Later phases add
	coins, unlocked recipes, upgrades and items to DEFAULTS.

	In Studio, saving only works if "Enable Studio Access to API Services" is
	turned on (Game Settings > Security). Without it the game still runs, it
	just doesn't remember anything.
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local DEFAULTS = {
	Version = 1,
	Style = nil, -- nil until the player picks a style (shows the welcome picker)
	Sparkles = 0,
}

local PlayerData = {}

local store: DataStore? = nil
do
	local ok, result = pcall(DataStoreService.GetDataStore, DataStoreService, Config.DataStoreName)
	if ok then
		store = result
	else
		warn("[PlayerData] DataStores unavailable, progress will not save:", result)
	end
end

local cache: { [Player]: { [string]: any } } = {}
local loadFailed: { [Player]: boolean } = {}

local function key(player: Player)
	return "player_" .. player.UserId
end

local function withRetries(callback)
	for attempt = 1, 3 do
		local ok, result = pcall(callback)
		if ok then
			return true, result
		end
		warn(string.format("[PlayerData] attempt %d failed: %s", attempt, tostring(result)))
		if string.find(tostring(result), "Studio", 1, true) then
			-- Studio without API access: stop trying for the rest of the session
			store = nil
			break
		end
		task.wait(attempt)
	end
	return false, nil
end

function PlayerData.Load(player: Player)
	local data = table.clone(DEFAULTS)
	if store then
		local ok, saved = withRetries(function()
			return (store :: DataStore):GetAsync(key(player))
		end)
		if ok and type(saved) == "table" then
			for k, v in saved do
				data[k] = v
			end
		elseif not ok then
			-- Never overwrite real progress with defaults after a failed load
			loadFailed[player] = true
		end
	end
	cache[player] = data
	return data
end

function PlayerData.Get(player: Player)
	return cache[player]
end

function PlayerData.Set(player: Player, field: string, value: any)
	local data = cache[player]
	if data then
		data[field] = value
	end
end

function PlayerData.Save(player: Player)
	local data = cache[player]
	if not (store and data) or loadFailed[player] then
		return
	end
	local snapshot = table.clone(data)
	withRetries(function()
		(store :: DataStore):SetAsync(key(player), snapshot, { player.UserId })
	end)
end

function PlayerData.Release(player: Player)
	PlayerData.Save(player)
	cache[player] = nil
	loadFailed[player] = nil
end

game:BindToClose(function()
	local pending = 0
	for player in cache do
		pending += 1
		task.spawn(function()
			PlayerData.Save(player)
			pending -= 1
		end)
	end
	local started = os.clock()
	while pending > 0 and os.clock() - started < 20 do
		task.wait(0.2)
	end
end)

return PlayerData
