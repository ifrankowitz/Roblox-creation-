--[[
	HouseStyles
	The 10 shop "vibes" a player can pick. HouseBuilder turns one of these
	tables into a building, and the client UI uses Emoji/Tagline/colours for
	the picker cards.

	Roof.Type is one of: "Gable", "Flat", "Dome", "Cone", "Pagoda"
	Features are optional decorations, see HouseBuilder for what each does.
]]

local M = Enum.Material
local rgb = Color3.fromRGB

local HouseStyles = {}

HouseStyles.List = {
	{
		Id = "EnchantedCottage",
		DisplayName = "Enchanted Cottage",
		Emoji = "🧙",
		Tagline = "Candlelit wood, crooked shingles and a smoking chimney.",
		Width = 32, Depth = 26, WallHeight = 13,
		Wall = { Color = rgb(120, 82, 56), Material = M.WoodPlanks },
		Trim = { Color = rgb(66, 42, 30), Material = M.Wood },
		Roof = { Type = "Gable", Color = rgb(64, 56, 86), Material = M.RoofShingles, Height = 12 },
		Floor = { Color = rgb(92, 62, 44), Material = M.WoodPlanks },
		Window = { Color = rgb(255, 190, 110), Material = M.Neon },
		Door = { Color = rgb(80, 50, 35), Material = M.Wood },
		Accent = rgb(130, 90, 200),
		Light = rgb(255, 180, 110),
		Features = { Chimney = true, Lanterns = true },
	},
	{
		Id = "FuturisticLab",
		DisplayName = "Futuristic Lab",
		Emoji = "🚀",
		Tagline = "Glowing neon strips and a chrome dome. Science!",
		Width = 34, Depth = 28, WallHeight = 14,
		Wall = { Color = rgb(225, 230, 238), Material = M.SmoothPlastic },
		Trim = { Color = rgb(0, 220, 255), Material = M.Neon },
		Roof = { Type = "Dome", Color = rgb(190, 200, 215), Material = M.Metal, Height = 10 },
		Floor = { Color = rgb(40, 45, 60), Material = M.DiamondPlate },
		Window = { Color = rgb(120, 230, 255), Material = M.Neon },
		Door = { Color = rgb(90, 95, 110), Material = M.Metal },
		Accent = rgb(0, 220, 255),
		Light = rgb(180, 235, 255),
		Features = { NeonStrips = true, Antenna = true },
	},
	{
		Id = "CoquetteBoutique",
		DisplayName = "Coquette Boutique",
		Emoji = "🎀",
		Tagline = "Pastel pink, striped awning and bows on everything.",
		Width = 30, Depth = 26, WallHeight = 13,
		Wall = { Color = rgb(255, 205, 220), Material = M.Plaster },
		Trim = { Color = rgb(255, 255, 255), Material = M.SmoothPlastic },
		Roof = { Type = "Gable", Color = rgb(240, 150, 180), Material = M.ClayRoofTiles, Height = 10 },
		Floor = { Color = rgb(245, 225, 230), Material = M.CeramicTiles },
		Window = { Color = rgb(255, 215, 235), Material = M.Neon },
		Door = { Color = rgb(255, 165, 195), Material = M.SmoothPlastic },
		Accent = rgb(230, 90, 140),
		Light = rgb(255, 205, 225),
		Features = { Bows = true, Awning = { rgb(255, 165, 195), rgb(255, 255, 255) }, FlowerBoxes = true },
	},
	{
		Id = "RusticFarmhouse",
		DisplayName = "Rustic Farmhouse",
		Emoji = "🌾",
		Tagline = "White boards, barn-red trim, picket fence and hay bales.",
		Width = 34, Depth = 26, WallHeight = 13,
		Wall = { Color = rgb(235, 228, 212), Material = M.WoodPlanks },
		Trim = { Color = rgb(150, 42, 36), Material = M.Wood },
		Roof = { Type = "Gable", Color = rgb(105, 110, 115), Material = M.CorrodedMetal, Height = 11 },
		Floor = { Color = rgb(150, 110, 70), Material = M.WoodPlanks },
		Window = { Color = rgb(255, 215, 150), Material = M.Neon },
		Door = { Color = rgb(150, 45, 40), Material = M.Wood },
		Accent = rgb(150, 42, 36),
		Light = rgb(255, 205, 140),
		Features = { Fence = true, HayBales = true, Chimney = true },
	},
	{
		Id = "WoodenLodge",
		DisplayName = "Wooden Lodge",
		Emoji = "🌲",
		Tagline = "Chunky log corners, steep roof and a stone chimney.",
		Width = 34, Depth = 28, WallHeight = 14,
		Wall = { Color = rgb(125, 85, 52), Material = M.Wood },
		Trim = { Color = rgb(85, 55, 32), Material = M.Wood },
		Roof = { Type = "Gable", Color = rgb(70, 58, 48), Material = M.WoodPlanks, Height = 15 },
		Floor = { Color = rgb(110, 75, 45), Material = M.WoodPlanks },
		Window = { Color = rgb(255, 180, 95), Material = M.Neon },
		Door = { Color = rgb(90, 58, 35), Material = M.Wood },
		Accent = rgb(60, 110, 70),
		Light = rgb(255, 175, 95),
		Features = { LogCorners = true, Chimney = true, Lanterns = true },
	},
	{
		Id = "GothicCastle",
		DisplayName = "Gothic Castle",
		Emoji = "🏰",
		Tagline = "Stone towers, battlements and spooky purple windows.",
		Width = 34, Depth = 28, WallHeight = 16,
		Wall = { Color = rgb(95, 92, 100), Material = M.Cobblestone },
		Trim = { Color = rgb(60, 58, 66), Material = M.Slate },
		Roof = { Type = "Flat", Color = rgb(55, 52, 60), Material = M.Slate },
		Floor = { Color = rgb(70, 66, 72), Material = M.Slate },
		Window = { Color = rgb(170, 90, 255), Material = M.Neon },
		Door = { Color = rgb(60, 35, 45), Material = M.Wood },
		Accent = rgb(110, 60, 160),
		Light = rgb(200, 150, 255),
		Features = { CornerTowers = rgb(70, 45, 105), Crenellations = true, Lanterns = true },
	},
	{
		Id = "MushroomHouse",
		DisplayName = "Mushroom Hideaway",
		Emoji = "🍄",
		Tagline = "A fairy home under a giant spotted mushroom cap.",
		Width = 26, Depth = 26, WallHeight = 12,
		Wall = { Color = rgb(245, 235, 210), Material = M.Plaster },
		Trim = { Color = rgb(150, 105, 70), Material = M.Wood },
		Roof = { Type = "Dome", Color = rgb(205, 45, 50), Material = M.SmoothPlastic, Height = 13, Radius = 21 },
		Floor = { Color = rgb(130, 95, 65), Material = M.Wood },
		Window = { Color = rgb(255, 230, 150), Material = M.Neon },
		Door = { Color = rgb(130, 85, 55), Material = M.Wood },
		Accent = rgb(205, 45, 50),
		Light = rgb(255, 220, 150),
		Features = { Spots = true, GlowShrooms = true },
	},
	{
		Id = "ZenTeaHouse",
		DisplayName = "Zen Tea House",
		Emoji = "⛩️",
		Tagline = "Layered pagoda roof, paper windows and red lanterns.",
		Width = 34, Depth = 26, WallHeight = 12,
		Wall = { Color = rgb(240, 232, 215), Material = M.Plaster },
		Trim = { Color = rgb(110, 45, 35), Material = M.Wood },
		Roof = { Type = "Pagoda", Color = rgb(50, 55, 62), Material = M.Slate },
		Floor = { Color = rgb(190, 160, 110), Material = M.WoodPlanks },
		Window = { Color = rgb(255, 238, 205), Material = M.Neon },
		Door = { Color = rgb(160, 120, 80), Material = M.Wood },
		Accent = rgb(200, 45, 40),
		Light = rgb(255, 225, 185),
		Features = { PaperLanterns = rgb(220, 50, 40) },
	},
	{
		Id = "CrystalSpire",
		DisplayName = "Crystal Spire",
		Emoji = "💎",
		Tagline = "Icy walls, a glass spire and glowing crystal clusters.",
		Width = 30, Depth = 26, WallHeight = 15,
		Wall = { Color = rgb(175, 215, 250), Material = M.Ice },
		Trim = { Color = rgb(120, 200, 255), Material = M.Neon },
		Roof = { Type = "Cone", Color = rgb(170, 140, 255), Material = M.Glass, Height = 20 },
		Floor = { Color = rgb(220, 225, 240), Material = M.Marble },
		Window = { Color = rgb(200, 170, 255), Material = M.Neon },
		Door = { Color = rgb(130, 160, 210), Material = M.Ice },
		Accent = rgb(170, 140, 255),
		Light = rgb(190, 200, 255),
		Features = { Crystals = true },
	},
	{
		Id = "SunstoneBazaar",
		DisplayName = "Sunstone Bazaar",
		Emoji = "🏜️",
		Tagline = "Desert sandstone, a teal onion dome and clay pots.",
		Width = 34, Depth = 26, WallHeight = 13,
		Wall = { Color = rgb(220, 180, 130), Material = M.Sandstone },
		Trim = { Color = rgb(170, 120, 80), Material = M.Sandstone },
		Roof = { Type = "Dome", Color = rgb(60, 145, 160), Material = M.CeramicTiles, Height = 9, Radius = 8 },
		Floor = { Color = rgb(200, 140, 90), Material = M.CeramicTiles },
		Window = { Color = rgb(255, 200, 120), Material = M.Neon },
		Door = { Color = rgb(120, 70, 40), Material = M.Wood },
		Accent = rgb(60, 145, 160),
		Light = rgb(255, 195, 120),
		Features = { Awning = { rgb(220, 80, 60), rgb(250, 230, 180) }, Pots = true, Crenellations = true },
	},
}

HouseStyles.ById = {}
for index, style in ipairs(HouseStyles.List) do
	style.Order = index
	HouseStyles.ById[style.Id] = style
end

function HouseStyles.Get(id: string?)
	return (id and HouseStyles.ById[id]) or nil
end

return HouseStyles
