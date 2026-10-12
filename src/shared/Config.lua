--[[
	Config
	Shared numbers for the town layout. Server and client both read this.
]]

local Config = {}

-- Town layout ---------------------------------------------------------------
Config.MaxPlots = 8 -- one plot per player; set the place's Max Players to match
Config.PlotRingRadius = 150 -- distance from the town centre to each plot centre
Config.PlotSize = 64 -- plots are square
Config.HouseOffset = 6 -- houses sit this far behind the plot centre (front yard)
Config.PlazaRadius = 46

Config.ForestInnerRadius = 230
Config.ForestOuterRadius = 420
Config.TreeCount = 180
Config.WorldHalfSize = 520 -- invisible walls stop players walking off the map

-- Gameplay ------------------------------------------------------------------
Config.DefaultStyle = "EnchantedCottage"
Config.StyleChangeCooldown = 3 -- seconds between rebuilds per player
Config.TeleportCooldown = 1

-- Saving --------------------------------------------------------------------
Config.DataStoreName = "PotionTown_PlayerData_v1"

-- Potion glass colours used for bottle decorations (and later, real potions)
Config.PotionColors = {
	Color3.fromRGB(60, 220, 120), -- emerald
	Color3.fromRGB(170, 90, 255), -- violet
	Color3.fromRGB(230, 50, 80), -- ruby
	Color3.fromRGB(255, 170, 40), -- amber
	Color3.fromRGB(60, 200, 255), -- aqua
	Color3.fromRGB(255, 110, 200), -- pink
	Color3.fromRGB(255, 215, 80), -- gold
}

-- Plot i sits on a ring around the plaza, facing the town centre.
-- Its LookVector (-Z) points at the plaza, so "front" is -Z in plot space.
function Config.GetPlotCFrame(index: number): CFrame
	local angle = (index - 1) / Config.MaxPlots * math.pi * 2
	local position = Vector3.new(math.cos(angle), 0, math.sin(angle)) * Config.PlotRingRadius
	return CFrame.lookAt(position, Vector3.zero)
end

Config.TownSpawn = CFrame.lookAt(Vector3.new(0, 4, -32), Vector3.new(0, 4, 0))

return Config
