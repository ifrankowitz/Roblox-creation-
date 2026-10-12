--[[
	Potion Town - server entry point (Phase 1: town, plots and shop styles)

	1. Builds the world (lighting, terrain, plaza, plots, forest).
	2. Gives every joining player a plot and builds their potion shop.
	3. Spawns players inside their own shop.
	4. Handles the style picker, the Visit/Home/Town buttons and the plaza props.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local HouseStyles = require(ReplicatedStorage.Shared.HouseStyles)
local WorldBuilder = require(script.Parent.WorldBuilder)
local PlotService = require(script.Parent.PlotService)
local PlayerData = require(script.Parent.PlayerData)
local Remotes = require(script.Parent.Remotes)

local world = WorldBuilder.Build()
PlotService.Init(world.Plots)

local function notify(player: Player, message: string)
	Remotes.Notify:FireClient(player, message)
end

--------------------------------------------------------------------------------
-- Plaza props
--------------------------------------------------------------------------------

for _, prompt in world.MarketPrompts do
	prompt.Triggered:Connect(function(player)
		notify(player, "🏪 The Town Market opens in a future update. Save up your coins!")
	end)
end

local FORTUNES = {
	"The well whispers: a rare ingredient grows where the fireflies gather...",
	"The well whispers: your shop will be famous across the realm!",
	"The well whispers: mix bravely, some mistakes become masterpieces.",
	"The well whispers: a friend's shop holds a secret worth visiting.",
}
world.WellPrompt.Triggered:Connect(function(player)
	world.WellSparkles:Emit(30)
	notify(player, "🌟 " .. FORTUNES[math.random(1, #FORTUNES)])
end)

--------------------------------------------------------------------------------
-- Player lifecycle
--------------------------------------------------------------------------------

local function placeCharacter(player: Player, character: Model)
	character:WaitForChild("HumanoidRootPart", 10)
	task.wait() -- let the default spawn finish before moving the character
	local record = PlotService.Get(player)
	if record and record.Info then
		PlotService.TeleportToShop(player, record)
	end
end

local function onPlayerAdded(player: Player)
	-- Hook spawning first so we never miss the first character
	player.CharacterAdded:Connect(function(character)
		placeCharacter(player, character)
	end)

	local data = PlayerData.Load(player)
	if not player.Parent then
		return -- left while loading
	end

	local record = PlotService.Claim(player)
	if record then
		local style = HouseStyles.Get(data.Style) or HouseStyles.Get(Config.DefaultStyle)
		PlotService.SetStyle(player, style)
		if player.Character then
			task.spawn(placeCharacter, player, player.Character)
		end
	else
		notify(player, "All plots are taken in this town. You can still explore and visit shops!")
	end

	if record and not data.Style then
		-- First visit ever: welcome them with the style picker
		task.delay(2, function()
			if player.Parent then
				Remotes.OpenStylePicker:FireClient(player, true)
			end
		end)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	PlotService.Release(player)
	PlayerData.Release(player)
end)

--------------------------------------------------------------------------------
-- Remotes
--------------------------------------------------------------------------------

local lastStyleChange: { [Player]: number } = {}
Remotes.ChooseStyle.OnServerEvent:Connect(function(player, styleId)
	if type(styleId) ~= "string" then
		return
	end
	local style = HouseStyles.Get(styleId)
	local record = PlotService.Get(player)
	if not (style and record) then
		return
	end

	local now = os.clock()
	if lastStyleChange[player] and now - lastStyleChange[player] < Config.StyleChangeCooldown then
		notify(player, "Give the builders a second... ⏳")
		return
	end
	lastStyleChange[player] = now

	PlayerData.Set(player, "Style", style.Id)
	if record.Model:GetAttribute("StyleId") ~= style.Id then
		PlotService.SetStyle(player, style)
	end
	PlotService.TeleportToShop(player, record)
	notify(player, string.format("%s Welcome to your %s!", style.Emoji, style.DisplayName))
end)

local lastTeleport: { [Player]: number } = {}
Remotes.RequestTeleport.OnServerEvent:Connect(function(player, target)
	local now = os.clock()
	if lastTeleport[player] and now - lastTeleport[player] < Config.TeleportCooldown then
		return
	end
	lastTeleport[player] = now

	local character = player.Character
	if not character then
		return
	end

	if target == "Town" then
		character:PivotTo(Config.TownSpawn)
	elseif target == "Home" then
		local record = PlotService.Get(player)
		if record then
			PlotService.TeleportToShop(player, record)
		end
	elseif type(target) == "number" then
		local record = PlotService.GetByUserId(target)
		if record then
			PlotService.TeleportToShop(player, record)
			if record.Owner and record.Owner ~= player then
				notify(record.Owner, player.DisplayName .. " is visiting your shop! 👋")
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastStyleChange[player] = nil
	lastTeleport[player] = nil
end)
