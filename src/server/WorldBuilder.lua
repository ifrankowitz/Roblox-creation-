--[[
	WorldBuilder
	Builds Potion Town when the server starts:
	  - golden-hour lighting with soft fog and bloom (the cosy, glowy look)
	  - grass terrain with a pond
	  - the central plaza with the Town Market pavilion (shop opens in Phase 5)
	  - a ring of empty plots, each linked to the plaza by a cobblestone path
	  - the enchanted forest around the town (ingredients arrive in Phase 2)
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local BuildUtil = require(script.Parent.BuildUtil)

local Part = BuildUtil.Part
local Cylinder = BuildUtil.Cylinder
local Ball = BuildUtil.Ball
local M = Enum.Material
local rgb = Color3.fromRGB

local WorldBuilder = {}

local function ensure(parent: Instance, className: string, name: string)
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local function setupLighting()
	Lighting.ClockTime = 18.1
	Lighting.GeographicLatitude = 30
	Lighting.Brightness = 2.2
	Lighting.Ambient = rgb(70, 55, 85)
	Lighting.OutdoorAmbient = rgb(125, 105, 135)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.3

	local atmosphere = ensure(Lighting, "Atmosphere", "PotionTownAtmosphere")
	atmosphere.Density = 0.33
	atmosphere.Offset = 0.15
	atmosphere.Color = rgb(205, 175, 215)
	atmosphere.Decay = rgb(110, 80, 125)
	atmosphere.Glare = 0.35
	atmosphere.Haze = 1.6

	local bloom = ensure(Lighting, "BloomEffect", "PotionTownBloom")
	bloom.Intensity = 0.7
	bloom.Size = 30
	bloom.Threshold = 1.4

	local color = ensure(Lighting, "ColorCorrectionEffect", "PotionTownColor")
	color.Saturation = 0.12
	color.Contrast = 0.08
	color.TintColor = rgb(255, 242, 232)

	local rays = ensure(Lighting, "SunRaysEffect", "PotionTownSunRays")
	rays.Intensity = 0.06
	rays.Spread = 0.6
end

local function setupTerrain()
	local terrain = workspace.Terrain
	terrain:Clear()
	local size = Config.WorldHalfSize * 2 + 80
	terrain:FillBlock(CFrame.new(0, -10, 0), Vector3.new(size, 20, size), M.Grass)
	terrain:SetMaterialColor(M.Grass, rgb(82, 112, 60))
	terrain:SetMaterialColor(M.LeafyGrass, rgb(66, 98, 52))

	-- Darker, leafy ground under the forest
	local ring = (Config.ForestInnerRadius + Config.ForestOuterRadius) / 2
	for i = 0, 23 do
		local a = i / 24 * math.pi * 2
		terrain:FillCylinder(CFrame.new(math.cos(a) * ring, -0.5, math.sin(a) * ring), 1, 70, M.LeafyGrass)
	end

	-- A pond between two plots, out in the forest edge
	local pondAngle = math.pi / Config.MaxPlots
	local pond = Vector3.new(math.cos(pondAngle), 0, math.sin(pondAngle)) * 270
	terrain:FillCylinder(CFrame.new(pond + Vector3.new(0, -3, 0)), 6, 22, M.Water)
	return pond
end

local function boundaryWalls(folder: Folder)
	local h = Config.WorldHalfSize
	for _, data in {
		{ Vector3.new(0, 50, h), Vector3.new(h * 2, 100, 2) },
		{ Vector3.new(0, 50, -h), Vector3.new(h * 2, 100, 2) },
		{ Vector3.new(h, 50, 0), Vector3.new(2, 100, h * 2) },
		{ Vector3.new(-h, 50, 0), Vector3.new(2, 100, h * 2) },
	} do
		Part(folder, data[2], CFrame.new(data[1]), rgb(0, 0, 0), M.SmoothPlastic, { Transparency = 1, Name = "Boundary", CanQuery = false })
	end
end

--------------------------------------------------------------------------------
-- Plaza and Town Market
--------------------------------------------------------------------------------

local function buildMarket(folder: Folder)
	local market = Instance.new("Model")
	market.Name = "TownMarket"
	market.Parent = folder

	local purple, deepPurple, gold = rgb(95, 60, 140), rgb(60, 38, 95), rgb(230, 185, 80)
	local marble = rgb(225, 215, 230)

	Cylinder(market, 1.2, 36, CFrame.new(0, 0.6, 0), marble, M.Marble, { Name = "MarketFloor" })
	Cylinder(market, 0.6, 38, CFrame.new(0, 0.3, 0), gold, M.Marble)

	-- Pillars, a ring beam and a tall tiered roof
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local p = CFrame.new(math.cos(a) * 16, 0, math.sin(a) * 16)
		Cylinder(market, 16, 2, p * CFrame.new(0, 9.2, 0), marble, M.Marble)
		Cylinder(market, 0.8, 3, p * CFrame.new(0, 1.6, 0), gold, M.Metal)
		Cylinder(market, 0.8, 3, p * CFrame.new(0, 16.8, 0), gold, M.Metal)
		local lantern = p * CFrame.new(0, 14, 0) * CFrame.new(-math.cos(a) * 1.6, 0, -math.sin(a) * 1.6)
		BuildUtil.Lantern(market, lantern, rgb(255, 185, 120), gold, 18)
	end
	Cylinder(market, 1.5, 36, CFrame.new(0, 17.95, 0), deepPurple, M.Slate)
	local tiers = BuildUtil.Tiered(market, CFrame.new(0, 18.7, 0), 20, 16, 12, BuildUtil.ConeProfile, purple, M.RoofShingles)
	for i, tier in tiers do
		if i % 2 == 0 then
			tier.Part.Color = deepPurple
		end
	end
	Cylinder(market, 3, 0.6, CFrame.new(0, 36, 0), gold, M.Metal)
	local star = Ball(market, 2.4, CFrame.new(0, 38.2, 0), rgb(255, 220, 120), M.Neon, { CanCollide = false })
	BuildUtil.Light(star, rgb(255, 210, 120), 30, 2)

	-- Giant bubbling cauldron in the middle
	local cauldron = CFrame.new(0, 1.2, 0)
	for i, r in { 3, 4, 4.5, 4.6, 4.4 } do
		Cylinder(market, 1, r * 2, cauldron * CFrame.new(0, 0.5 + (i - 1), 0), rgb(38, 36, 42), M.Metal)
	end
	Cylinder(market, 0.5, 9.6, cauldron * CFrame.new(0, 5.25, 0), rgb(60, 55, 65), M.Metal)
	Cylinder(market, 0.2, 8, cauldron * CFrame.new(0, 5.5, 0), rgb(170, 90, 255), M.Neon, { CanCollide = false })
	local fx = Part(market, Vector3.new(6, 0.2, 6), cauldron * CFrame.new(0, 5.9, 0), rgb(0, 0, 0), M.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false })
	BuildUtil.Light(fx, rgb(180, 110, 255), 24, 2.5, true)
	local fumes = Instance.new("ParticleEmitter")
	fumes.Color = ColorSequence.new(rgb(190, 120, 255), rgb(120, 220, 255))
	fumes.LightEmission = 0.8
	fumes.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	fumes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 3) })
	fumes.Lifetime = NumberRange.new(2, 4)
	fumes.Speed = NumberRange.new(3, 5)
	fumes.Rate = 14
	fumes.SpreadAngle = Vector2.new(20, 20)
	fumes.Parent = fx

	-- Four market stalls facing outwards
	local prompts = {}
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + math.pi / 4
		local outward = Vector3.new(math.cos(a), 0, math.sin(a))
		local base = CFrame.lookAt(outward * 10 + Vector3.new(0, 1.2, 0), outward * 20 + Vector3.new(0, 1.2, 0))
		Part(market, Vector3.new(8, 3.4, 2.4), base * CFrame.new(0, 1.7, 0), rgb(95, 62, 40), M.WoodPlanks)
		Part(market, Vector3.new(8.6, 0.4, 3), base * CFrame.new(0, 3.6, 0), gold, M.Wood)
		local rng = Random.new(i + 10)
		for b = -3, 3 do
			local color = Config.PotionColors[rng:NextInteger(1, #Config.PotionColors)]
			Cylinder(market, rng:NextNumber(0.9, 1.6), 0.7, base * CFrame.new(b, 4.4, 0), color, M.Neon, { CanCollide = false })
		end
		local prompt = BuildUtil.Prompt(Part(market, Vector3.new(8, 3.4, 0.2), base * CFrame.new(0, 1.7, -1.3), rgb(0, 0, 0), M.SmoothPlastic, { Transparency = 1, CanCollide = false }), "Browse", "Town Market")
		table.insert(prompts, prompt)
	end

	local anchor = Part(market, Vector3.one, CFrame.new(0, 44, 0), rgb(0, 0, 0), M.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false })
	BuildUtil.Billboard(anchor, "✦ Town Market ✦", "Shop decor & rare items · opening soon", 400)
	return prompts
end

local function buildWishingWell(folder: Folder, cf: CFrame)
	local well = Instance.new("Model")
	well.Name = "WishingWell"
	well.Parent = folder
	local stone = rgb(140, 135, 145)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		Part(well, Vector3.new(2.2, 3, 1.2), cf * CFrame.new(math.cos(a) * 4, 1.5, math.sin(a) * 4) * CFrame.Angles(0, -a + math.pi / 2, 0), stone, M.Cobblestone)
	end
	local water = Cylinder(well, 0.2, 7, cf * CFrame.new(0, 2.2, 0), rgb(90, 220, 255), M.Neon, { CanCollide = false })
	BuildUtil.Light(water, rgb(90, 220, 255), 14, 1.6)
	for _, sx in { -1, 1 } do
		Part(well, Vector3.new(0.6, 7, 0.6), cf * CFrame.new(sx * 4, 4.5, 0), rgb(90, 60, 40), M.Wood)
	end
	local roof = cf * CFrame.new(0, 8.6, 0)
	Part(well, Vector3.new(10, 0.5, 4), roof * CFrame.new(0, 0, -1.4) * CFrame.Angles(math.rad(30), 0, 0), rgb(120, 60, 60), M.ClayRoofTiles)
	Part(well, Vector3.new(10, 0.5, 4), roof * CFrame.new(0, 0, 1.4) * CFrame.Angles(math.rad(-30), 0, 0), rgb(120, 60, 60), M.ClayRoofTiles)

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "WishSparkles"
	sparkles.Color = ColorSequence.new(rgb(255, 230, 140), rgb(150, 230, 255))
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new(0.4, 0)
	sparkles.Lifetime = NumberRange.new(1, 2)
	sparkles.Speed = NumberRange.new(4, 8)
	sparkles.SpreadAngle = Vector2.new(35, 35)
	sparkles.Rate = 2
	sparkles.EmissionDirection = Enum.NormalId.Right -- upwards on an upright cylinder
	sparkles.Parent = water

	return BuildUtil.Prompt(water, "Make a Wish", "Wishing Well", 0.5), sparkles
end

local function buildPlaza(folder: Folder)
	local r = Config.PlazaRadius
	Cylinder(folder, 0.4, r * 2, CFrame.new(0, 0.2, 0), rgb(160, 150, 145), M.Cobblestone, { Name = "Plaza" })
	Cylinder(folder, 0.3, r * 2 + 3, CFrame.new(0, 0.15, 0), rgb(110, 100, 105), M.Slate)

	for i = 0, 11 do
		local a = (i + 0.5) / 12 * math.pi * 2
		BuildUtil.LampPost(folder, CFrame.new(math.cos(a) * (r - 3), 0.4, math.sin(a) * (r - 3)))
	end

	-- Flower beds around the inner plaza
	local flowers = { rgb(255, 140, 190), rgb(200, 150, 255), rgb(255, 210, 110), rgb(140, 220, 255) }
	local rng = Random.new(7)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2 + math.pi / 8
		local bed = CFrame.new(math.cos(a) * 27, 0.4, math.sin(a) * 27) * CFrame.Angles(0, -a, 0)
		Part(folder, Vector3.new(4, 1, 9), bed * CFrame.new(0, 0.5, 0), rgb(110, 80, 60), M.Wood)
		Part(folder, Vector3.new(3.4, 0.2, 8.4), bed * CFrame.new(0, 1.05, 0), rgb(80, 55, 40), M.Mud)
		for _ = 1, 6 do
			Ball(folder, 0.9, bed * CFrame.new(rng:NextNumber(-1.3, 1.3), 1.5, rng:NextNumber(-3.6, 3.6)), flowers[rng:NextInteger(1, #flowers)], M.SmoothPlastic, { CanCollide = false })
		end
	end

	local marketPrompts = buildMarket(folder)
	local wellAngle = math.pi * 2 * (Config.MaxPlots - 0.5) / Config.MaxPlots
	local wellPrompt, wellSparkles = buildWishingWell(folder, CFrame.new(math.cos(wellAngle) * 34, 0.4, math.sin(wellAngle) * 34))

	local townSpawn = Instance.new("SpawnLocation")
	townSpawn.Name = "TownSpawn"
	townSpawn.Anchored = true
	townSpawn.Neutral = true
	townSpawn.Size = Vector3.new(6, 0.2, 6)
	townSpawn.CFrame = CFrame.new(Config.TownSpawn.Position.X, 0.5, Config.TownSpawn.Position.Z)
	townSpawn.Transparency = 1
	townSpawn.CanCollide = false
	townSpawn.Duration = 0
	townSpawn.Parent = folder

	return marketPrompts, wellPrompt, wellSparkles
end

--------------------------------------------------------------------------------
-- Plots and paths
--------------------------------------------------------------------------------

local function buildPlot(folder: Folder, index: number)
	local cf = Config.GetPlotCFrame(index)
	local size = Config.PlotSize
	local plot = Instance.new("Model")
	plot.Name = "Plot" .. index
	plot:SetAttribute("PlotIndex", index)
	plot.Parent = folder

	local base = Part(plot, Vector3.new(size, 1, size), cf, rgb(96, 128, 70), M.Grass, { Name = "Base" })
	plot.PrimaryPart = base
	-- low stone border (gap at the front for the path)
	local border = rgb(130, 122, 128)
	local h = size / 2
	Part(plot, Vector3.new(size + 1, 0.8, 1), cf * CFrame.new(0, 0.6, h), border, M.Cobblestone)
	Part(plot, Vector3.new(1, 0.8, size + 1), cf * CFrame.new(-h, 0.6, 0), border, M.Cobblestone)
	Part(plot, Vector3.new(1, 0.8, size + 1), cf * CFrame.new(h, 0.6, 0), border, M.Cobblestone)
	for _, sx in { -1, 1 } do
		Part(plot, Vector3.new(h - 4, 0.8, 1), cf * CFrame.new(sx * (h + 4) / 2, 0.6, -h), border, M.Cobblestone)
	end

	-- "For sale" sign shown while nobody owns the plot
	local sign = Instance.new("Model")
	sign.Name = "ForSaleSign"
	sign.Parent = plot
	local signCF = cf * CFrame.new(0, 0.5, -6)
	Cylinder(sign, 5, 0.5, signCF * CFrame.new(0, 2.5, 0), rgb(90, 60, 40), M.Wood)
	local board = Part(sign, Vector3.new(6, 3, 0.4), signCF * CFrame.new(0, 5, 0), rgb(120, 85, 55), M.WoodPlanks)
	BuildUtil.SurfaceText(board, Enum.NormalId.Front, "✦ Empty Plot ✦\nWaiting for a potion maker", rgb(255, 235, 190))
	local glow = Part(sign, Vector3.new(4, 0.2, 4), signCF * CFrame.new(0, 0.1, 0), rgb(170, 90, 255), M.Neon, { CanCollide = false, Transparency = 0.4 })
	glow.Name = "Glow"
	return plot
end

local function buildPath(folder: Folder, index: number)
	local plotCF = Config.GetPlotCFrame(index)
	local from = Config.PlazaRadius - 1
	local to = Config.PlotRingRadius - Config.PlotSize / 2
	local length = to - from
	local direction = plotCF.Position.Unit
	local mid = direction * (from + length / 2)
	local cf = CFrame.lookAt(mid, mid + direction) * CFrame.new(0, 0.2, 0)
	Part(folder, Vector3.new(7, 0.4, length), cf, rgb(150, 140, 135), M.Cobblestone, { Name = "Path" })
	Part(folder, Vector3.new(9, 0.3, length), cf * CFrame.new(0, -0.08, 0), rgb(110, 100, 90), M.Pebble)
end

--------------------------------------------------------------------------------
-- Enchanted forest
--------------------------------------------------------------------------------

local LEAVES = { rgb(60, 110, 55), rgb(75, 125, 60), rgb(50, 95, 60), rgb(90, 130, 65) }
local MAGIC_LEAVES = { rgb(140, 90, 200), rgb(80, 160, 170), rgb(200, 110, 170) }

local function tree(folder, rng: Random, pos: Vector3)
	local magic = rng:NextNumber() < 0.15
	local height = rng:NextNumber(10, 20)
	local trunkD = rng:NextNumber(1.6, 2.8)
	local base = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	Cylinder(folder, height, trunkD, base * CFrame.new(0, height / 2 - 0.5, 0), rgb(85, 60, 45), M.Wood)

	if not magic and rng:NextNumber() < 0.4 then
		-- pine
		for i = 0, 3 do
			local r = (4 - i) * 2.2 + 1
			Cylinder(folder, 3, r * 2, base * CFrame.new(0, height - 3 + i * 3, 0), rgb(45, 90, 60), M.LeafyGrass)
		end
		return
	end

	local palette = magic and MAGIC_LEAVES or LEAVES
	for _ = 1, 3 do
		local offset = Vector3.new(rng:NextNumber(-3, 3), rng:NextNumber(-1, 3), rng:NextNumber(-3, 3))
		Ball(folder, rng:NextNumber(8, 12), base * CFrame.new(Vector3.new(0, height, 0) + offset), palette[rng:NextInteger(1, #palette)], M.LeafyGrass, { CastShadow = true })
	end
	if magic then
		for _ = 1, 4 do
			local fruit = Ball(folder, 0.9, base * CFrame.new(rng:NextNumber(-4, 4), height + rng:NextNumber(-4, 0), rng:NextNumber(-4, 4)), rgb(255, 220, 120), M.Neon, { CanCollide = false })
			fruit.Name = "GlowFruit"
		end
	end
end

local function mushroom(folder, rng: Random, pos: Vector3, withLight: boolean)
	local colors = { rgb(120, 230, 255), rgb(200, 120, 255), rgb(255, 140, 200), rgb(140, 255, 170) }
	local color = colors[rng:NextInteger(1, #colors)]
	local h = rng:NextNumber(1.2, 3)
	Cylinder(folder, h, 0.6, CFrame.new(pos + Vector3.new(0, h / 2, 0)), rgb(240, 235, 220), M.SmoothPlastic, { CanCollide = false })
	local cap = Cylinder(folder, 0.6, h * 1.4, CFrame.new(pos + Vector3.new(0, h, 0)), color, M.Neon, { CanCollide = false })
	if withLight then
		BuildUtil.Light(cap, color, 10, 1.2)
	end
end

local function fireflies(folder, pos: Vector3)
	local holder = Part(folder, Vector3.new(30, 8, 30), CFrame.new(pos + Vector3.new(0, 5, 0)), rgb(0, 0, 0), M.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false, Name = "Fireflies" })
	local emitter = Instance.new("ParticleEmitter")
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.Color = ColorSequence.new(rgb(220, 255, 140))
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 0.25), NumberSequenceKeypoint.new(0.8, 0.25), NumberSequenceKeypoint.new(1, 0) })
	emitter.Lifetime = NumberRange.new(4, 7)
	emitter.Speed = NumberRange.new(0.3, 1)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 4
	emitter.Parent = holder
end

local function buildForest(folder: Folder, pond: Vector3)
	local rng = Random.new(42)
	local inner, outer = Config.ForestInnerRadius, Config.ForestOuterRadius

	local function randomSpot()
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(inner, outer)
		return Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
	end

	local planted = 0
	while planted < Config.TreeCount do
		local p = randomSpot()
		if (p - pond).Magnitude > 30 then
			tree(folder, rng, p)
			planted += 1
		end
	end

	-- Scattered trees between the plots so the town feels tucked into the woods
	for i = 1, Config.MaxPlots do
		local a = (i - 0.5) / Config.MaxPlots * math.pi * 2
		for _ = 1, 3 do
			local r = Config.PlotRingRadius + rng:NextNumber(10, 45)
			local jitter = rng:NextNumber(-0.03, 0.03)
			tree(folder, rng, Vector3.new(math.cos(a + jitter) * r, 0, math.sin(a + jitter) * r))
		end
	end

	for i = 1, 40 do
		local p = randomSpot()
		mushroom(folder, rng, p, i <= 14)
	end
	for _ = 1, 30 do
		local p = randomSpot()
		Ball(folder, rng:NextNumber(2, 6), CFrame.new(p) * CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0), rgb(120, 118, 125), M.Rock)
	end
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		fireflies(folder, Vector3.new(math.cos(a), 0, math.sin(a)) * (inner + 30))
	end
end

--------------------------------------------------------------------------------

function WorldBuilder.Build()
	setupLighting()

	-- Clear the default Baseplate template pieces
	for _, name in { "Baseplate", "SpawnLocation" } do
		local old = workspace:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	local oldTown = workspace:FindFirstChild("Town")
	if oldTown then
		oldTown:Destroy()
	end

	local pond = setupTerrain()

	local town = Instance.new("Folder")
	town.Name = "Town"
	town.Parent = workspace

	local scenery = Instance.new("Folder")
	scenery.Name = "Scenery"
	scenery.Parent = town
	boundaryWalls(scenery)

	local plaza = Instance.new("Folder")
	plaza.Name = "Plaza"
	plaza.Parent = town
	local marketPrompts, wellPrompt, wellSparkles = buildPlaza(plaza)

	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = town
	local plots = {}
	for i = 1, Config.MaxPlots do
		plots[i] = buildPlot(plotsFolder, i)
		buildPath(scenery, i)
	end

	local forest = Instance.new("Folder")
	forest.Name = "Forest"
	forest.Parent = scenery
	buildForest(forest, pond)

	return {
		Plots = plots,
		MarketPrompts = marketPrompts,
		WellPrompt = wellPrompt,
		WellSparkles = wellSparkles,
	}
end

return WorldBuilder
