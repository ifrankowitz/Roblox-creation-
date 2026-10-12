--[[
	HouseBuilder
	Turns a HouseStyles entry into a full potion shop on a plot:
	  - the shell (foundation, walls, door, windows, roof)
	  - style features (chimney, towers, awning, bows, crystals...)
	  - a cosy interior (shelves of glowing bottles, cauldron, counter, lanterns)
	  - the front yard (path, lamp posts, shop sign)

	All coordinates below are in "house space": origin on the plot surface at
	the house centre, -Z is the front of the house (towards the town plaza).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local BuildUtil = require(script.Parent.BuildUtil)

local Part = BuildUtil.Part
local Cylinder = BuildUtil.Cylinder
local Ball = BuildUtil.Ball
local M = Enum.Material
local rgb = Color3.fromRGB

local T = 1 -- wall thickness
local DOOR_W = 6
local DOOR_H = 9
local FLOOR_Y = 1.2 -- the walking surface inside the house
local STONE = rgb(105, 100, 108)
local WOOD_DARK = rgb(70, 45, 30)

local HouseBuilder = {}

--------------------------------------------------------------------------------
-- Shell
--------------------------------------------------------------------------------

local function buildWindow(ctx, cf: CFrame, w: number, h: number)
	-- `cf` is the window centre; its -Z faces outside.
	local s = ctx.Style
	local m = ctx.Model
	local at = ctx.Origin * cf
	Part(m, Vector3.new(w + 0.8, h + 0.8, T + 0.2), at, s.Trim.Color, s.Trim.Material)
	Part(m, Vector3.new(w, h, T + 0.4), at, s.Window.Color, s.Window.Material, { Name = "Window" })
	Part(m, Vector3.new(0.25, h, T + 0.6), at, s.Trim.Color, s.Trim.Material)
	Part(m, Vector3.new(w, 0.25, T + 0.6), at, s.Trim.Color, s.Trim.Material)
	Part(m, Vector3.new(w + 1.2, 0.3, T + 1.2), at * CFrame.new(0, -h / 2 - 0.5, 0), s.Trim.Color, s.Trim.Material)

	if s.Features.FlowerBoxes then
		local box = at * CFrame.new(0, -h / 2 - 1.2, -(T / 2 + 0.8))
		Part(m, Vector3.new(w + 0.6, 0.9, 1.2), box, s.Trim.Color, s.Trim.Material)
		for i = 1, math.floor(w / 1.1) do
			local x = -w / 2 + (i - 0.5) * (w / math.floor(w / 1.1))
			local color = (i % 2 == 0) and s.Accent or rgb(255, 245, 250)
			Ball(m, 0.9, box * CFrame.new(x, 0.65, 0), color, M.SmoothPlastic, { CanCollide = false })
		end
	end

	if s.Features.Bows then
		HouseBuilder.Bow(m, at * CFrame.new(0, h / 2 + 0.9, -(T / 2 + 0.4)), s.Accent)
	end
end

function HouseBuilder.Bow(parent, cf: CFrame, color: Color3)
	Ball(parent, 1.3, cf * CFrame.new(-0.75, 0, 0), color, M.SmoothPlastic, { CanCollide = false })
	Ball(parent, 1.3, cf * CFrame.new(0.75, 0, 0), color, M.SmoothPlastic, { CanCollide = false })
	Ball(parent, 0.8, cf * CFrame.new(0, 0, -0.2), color, M.SmoothPlastic, { CanCollide = false })
	Part(parent, Vector3.new(0.4, 1.3, 0.2), cf * CFrame.new(-0.35, -0.8, -0.1) * CFrame.Angles(0, 0, math.rad(-20)), color, M.SmoothPlastic, { CanCollide = false })
	Part(parent, Vector3.new(0.4, 1.3, 0.2), cf * CFrame.new(0.35, -0.8, -0.1) * CFrame.Angles(0, 0, math.rad(20)), color, M.SmoothPlastic, { CanCollide = false })
end

local function buildShell(ctx)
	local s, m, W, D, H = ctx.Style, ctx.Model, ctx.W, ctx.D, ctx.H
	local function L(x, y, z)
		return ctx.Origin * CFrame.new(x, y, z)
	end
	local wallY = 1 + H / 2

	-- Foundation + floor
	Part(m, Vector3.new(W + 2, 1, D + 2), L(0, 0.5, 0), STONE, M.Cobblestone, { Name = "Foundation" })
	Part(m, Vector3.new(W - 2 * T, 0.2, D - 2 * T), L(0, 1.1, 0), s.Floor.Color, s.Floor.Material, { Name = "Floor" })

	-- Walls (the front wall is split around the door)
	local wc, wm = s.Wall.Color, s.Wall.Material
	Part(m, Vector3.new(W, H, T), L(0, wallY, D / 2 - T / 2), wc, wm, { Name = "BackWall" })
	Part(m, Vector3.new(T, H, D - 2 * T), L(-W / 2 + T / 2, wallY, 0), wc, wm, { Name = "LeftWall" })
	Part(m, Vector3.new(T, H, D - 2 * T), L(W / 2 - T / 2, wallY, 0), wc, wm, { Name = "RightWall" })
	local segW = (W - DOOR_W) / 2
	local segX = DOOR_W / 2 + segW / 2
	local frontZ = -D / 2 + T / 2
	Part(m, Vector3.new(segW, H, T), L(-segX, wallY, frontZ), wc, wm, { Name = "FrontWall" })
	Part(m, Vector3.new(segW, H, T), L(segX, wallY, frontZ), wc, wm, { Name = "FrontWall" })
	Part(m, Vector3.new(DOOR_W, H - DOOR_H, T), L(0, 1 + DOOR_H + (H - DOOR_H) / 2, frontZ), wc, wm, { Name = "FrontWall" })

	-- Trim: corner posts and a band along the top of the walls
	local tc, tm = s.Trim.Color, s.Trim.Material
	if not (s.Features.CornerTowers or s.Features.LogCorners) then
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				Part(m, Vector3.new(T + 0.4, H, T + 0.4), L(sx * (W / 2 - T / 2), wallY, sz * (D / 2 - T / 2)), tc, tm)
			end
		end
	end
	Part(m, Vector3.new(W + 0.4, 0.8, T + 0.4), L(0, ctx.WallTop - 0.4, frontZ), tc, tm)
	Part(m, Vector3.new(W + 0.4, 0.8, T + 0.4), L(0, ctx.WallTop - 0.4, D / 2 - T / 2), tc, tm)
	Part(m, Vector3.new(T + 0.4, 0.8, D), L(-W / 2 + T / 2, ctx.WallTop - 0.4, 0), tc, tm)
	Part(m, Vector3.new(T + 0.4, 0.8, D), L(W / 2 - T / 2, ctx.WallTop - 0.4, 0), tc, tm)

	-- Door frame
	Part(m, Vector3.new(0.6, DOOR_H, T + 0.4), L(-DOOR_W / 2 - 0.3, 1 + DOOR_H / 2, frontZ), tc, tm)
	Part(m, Vector3.new(0.6, DOOR_H, T + 0.4), L(DOOR_W / 2 + 0.3, 1 + DOOR_H / 2, frontZ), tc, tm)
	Part(m, Vector3.new(DOOR_W + 1.2, 0.6, T + 0.4), L(0, 1 + DOOR_H + 0.3, frontZ), tc, tm)
	Part(m, Vector3.new(DOOR_W + 1, 0.4, 2.4), L(0, 0.8, -D / 2 - 1.2), STONE, M.Slate, { Name = "Doorstep" })

	-- The door swings inwards around a hinge on its left edge
	local hinge = L(-DOOR_W / 2, 1 + DOOR_H / 2, frontZ)
	local closed = hinge * CFrame.new(DOOR_W / 2, 0, 0)
	local open = hinge * CFrame.Angles(0, math.rad(-100), 0) * CFrame.new(DOOR_W / 2, 0, 0)
	local door = Part(m, Vector3.new(DOOR_W - 0.1, DOOR_H - 0.1, 0.5), closed, s.Door.Color, s.Door.Material, { Name = "Door" })
	ctx.Info.Door = { Part = door, Closed = closed, Open = open }

	-- Windows: two on the front, two on the right, two small high ones on the
	-- left (the left wall is lined with shelves inside).
	local frontW = math.min(6, segW - 3)
	buildWindow(ctx, CFrame.new(-segX, 1 + H * 0.48, frontZ), frontW, 5)
	buildWindow(ctx, CFrame.new(segX, 1 + H * 0.48, frontZ), frontW, 5)
	for _, z in { -D / 4, D / 4 } do
		buildWindow(ctx, CFrame.new(W / 2 - T / 2, 1 + H * 0.48, z) * CFrame.Angles(0, math.rad(-90), 0), 5, 5)
		buildWindow(ctx, CFrame.new(-W / 2 + T / 2, ctx.WallTop - 3.2, z) * CFrame.Angles(0, math.rad(90), 0), 4, 2.4)
	end
end

--------------------------------------------------------------------------------
-- Roofs. Each returns the height (house space) of the highest point.
--------------------------------------------------------------------------------

local Roofs = {}

function Roofs.Gable(ctx)
	local s, m, W, D = ctx.Style, ctx.Model, ctx.W, ctx.D
	local top = ctx.WallTop
	local rh = s.Roof.Height or W * 0.35
	ctx.RoofRise = rh

	-- Two wedges fill the attic and close the gable ends. A WedgePart is tall
	-- at its +Z end, so each half is turned to face the ridge.
	Part(m, Vector3.new(D, rh, W / 2), ctx.Origin * CFrame.new(W / 4, top + rh / 2, 0) * CFrame.Angles(0, -math.pi / 2, 0), s.Wall.Color, s.Wall.Material, { ClassName = "WedgePart", Name = "Gable" })
	Part(m, Vector3.new(D, rh, W / 2), ctx.Origin * CFrame.new(-W / 4, top + rh / 2, 0) * CFrame.Angles(0, math.pi / 2, 0), s.Wall.Color, s.Wall.Material, { ClassName = "WedgePart", Name = "Gable" })

	-- Two sloped roof slabs with an overhang at the eaves and gable ends
	local half = W / 2
	local alpha = math.atan2(rh, half)
	local overhang = 2.5
	local length = math.sqrt(half * half + rh * rh) + overhang
	local downX, downY = math.cos(alpha), -math.sin(alpha)
	local normX, normY = math.sin(alpha), math.cos(alpha)
	local cx = half / 2 + downX * overhang / 2 + normX * 0.4
	local cy = top + rh / 2 + downY * overhang / 2 + normY * 0.4
	local size = Vector3.new(length, 0.8, D + 3)
	Part(m, size, ctx.Origin * CFrame.new(cx, cy, 0) * CFrame.Angles(0, 0, -alpha), s.Roof.Color, s.Roof.Material, { Name = "Roof" })
	Part(m, size, ctx.Origin * CFrame.new(-cx, cy, 0) * CFrame.Angles(0, 0, alpha), s.Roof.Color, s.Roof.Material, { Name = "Roof" })
	Part(m, Vector3.new(1.3, 1.3, D + 3.2), ctx.Origin * CFrame.new(0, top + rh + 0.3, 0) * CFrame.Angles(0, 0, math.pi / 4), s.Trim.Color, s.Trim.Material, { Name = "Ridge" })
	return top + rh + 1
end

local function flatSlab(ctx)
	local s = ctx.Style
	Part(ctx.Model, Vector3.new(ctx.W + 2, 1, ctx.D + 2), ctx.Origin * CFrame.new(0, ctx.WallTop + 0.5, 0), s.Roof.Color, s.Roof.Material, { Name = "Roof" })
	ctx.RoofRise = 1
	return ctx.WallTop + 1
end

function Roofs.Flat(ctx)
	return flatSlab(ctx)
end

function Roofs.Dome(ctx)
	local s = ctx.Style
	local base = flatSlab(ctx)
	local radius = s.Roof.Radius or math.min(ctx.W, ctx.D) / 2 - 1
	local height = s.Roof.Height or radius
	local tiers = BuildUtil.Tiered(ctx.Model, ctx.Origin * CFrame.new(0, base, 0), radius, height, 10, BuildUtil.DomeProfile, s.Roof.Color, s.Roof.Material, { Name = "Roof" })

	if s.Features.Spots then
		for i = 1, #tiers - 2 do
			local tier = tiers[i]
			for _ = 1, 3 do
				local angle = ctx.Rng:NextNumber() * math.pi * 2
				local r = tier.Radius - 0.5
				Ball(ctx.Model, ctx.Rng:NextNumber(1.6, 2.8), ctx.Origin * CFrame.new(math.cos(angle) * r, base + tier.Y, math.sin(angle) * r), rgb(255, 250, 240), M.SmoothPlastic, { CanCollide = false })
			end
		end
	else
		Ball(ctx.Model, 1.6, ctx.Origin * CFrame.new(0, base + height + 0.6, 0), s.Accent, M.Neon, { CanCollide = false })
	end
	ctx.RoofRise = height
	return base + height + 1.4
end

function Roofs.Cone(ctx)
	local s = ctx.Style
	local base = flatSlab(ctx)
	local radius = s.Roof.Radius or math.min(ctx.W, ctx.D) / 2
	local height = s.Roof.Height or radius * 1.4
	BuildUtil.Tiered(ctx.Model, ctx.Origin * CFrame.new(0, base, 0), radius, height, 12, BuildUtil.ConeProfile, s.Roof.Color, s.Roof.Material, { Name = "Roof", Transparency = s.Roof.Material == M.Glass and 0.2 or 0 })
	local tip = Ball(ctx.Model, 2.2, ctx.Origin * CFrame.new(0, base + height + 1, 0), s.Trim.Color, M.Neon, { CanCollide = false })
	BuildUtil.Light(tip, s.Trim.Color, 24, 2)
	ctx.RoofRise = height
	return base + height + 2
end

function Roofs.Pagoda(ctx)
	local s, m, W, D = ctx.Style, ctx.Model, ctx.W, ctx.D
	local y = ctx.WallTop
	for level = 0, 2 do
		local ew, ed = W + 8 - level * 8, D + 8 - level * 8
		Part(m, Vector3.new(ew, 0.9, ed), ctx.Origin * CFrame.new(0, y + 0.45, 0), s.Roof.Color, s.Roof.Material, { Name = "Roof" })
		-- upturned eave tips
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				Part(m, Vector3.new(1.2, 1, 1.2), ctx.Origin * CFrame.new(sx * (ew / 2 - 0.6), y + 1.3, sz * (ed / 2 - 0.6)), s.Trim.Color, s.Trim.Material)
			end
		end
		y += 0.9
		if level < 2 then
			Part(m, Vector3.new(W - 6 - level * 8, 3.2, D - 6 - level * 8), ctx.Origin * CFrame.new(0, y + 1.6, 0), s.Wall.Color, s.Wall.Material)
			y += 3.2
		end
	end
	Cylinder(m, 3, 0.8, ctx.Origin * CFrame.new(0, y + 1.5, 0), s.Trim.Color, s.Trim.Material)
	Ball(m, 1.4, ctx.Origin * CFrame.new(0, y + 3.3, 0), rgb(255, 205, 90), M.Neon, { CanCollide = false })
	ctx.RoofRise = y - ctx.WallTop
	return y + 4
end

--------------------------------------------------------------------------------
-- Style features
--------------------------------------------------------------------------------

local function smokeEmitter(parent, cf: CFrame)
	local holder = Part(parent, Vector3.new(1, 1, 1), cf, rgb(0, 0, 0), M.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false, Name = "Smoke" })
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(rgb(200, 195, 210), rgb(120, 115, 130))
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 5) })
	smoke.Lifetime = NumberRange.new(4, 6)
	smoke.Speed = NumberRange.new(2, 4)
	smoke.Rate = 3
	smoke.SpreadAngle = Vector2.new(12, 12)
	smoke.Acceleration = Vector3.new(0.6, 0.6, 0)
	smoke.RotSpeed = NumberRange.new(-20, 20)
	smoke.Parent = holder
end

local Features = {}

function Features.Chimney(ctx)
	local W, D = ctx.W, ctx.D
	local x, z = W / 2 - 6, D / 4
	local roofAtX = ctx.Style.Roof.Type == "Gable" and ctx.RoofRise * (1 - x / (W / 2)) or ctx.RoofRise
	local topY = ctx.WallTop + roofAtX + 3.5
	local height = topY - ctx.WallTop
	local brick = rgb(125, 72, 60)
	Part(ctx.Model, Vector3.new(3, height, 3), ctx.Origin * CFrame.new(x, ctx.WallTop + height / 2, z), brick, M.Brick, { Name = "Chimney" })
	Part(ctx.Model, Vector3.new(3.8, 0.6, 3.8), ctx.Origin * CFrame.new(x, topY + 0.3, z), STONE, M.Slate)
	smokeEmitter(ctx.Model, ctx.Origin * CFrame.new(x, topY + 1, z))
end

function Features.Lanterns(ctx)
	for _, sx in { -1, 1 } do
		local cf = ctx.Origin * CFrame.new(sx * (DOOR_W / 2 + 2), 1 + DOOR_H - 1.8, -ctx.D / 2 - 0.9)
		Part(ctx.Model, Vector3.new(0.3, 0.3, 1), cf * CFrame.new(0, 1.3, 0.4), WOOD_DARK, M.Metal)
		BuildUtil.Lantern(ctx.Model, cf, ctx.Style.Light, nil, 14)
	end
end

function Features.NeonStrips(ctx)
	local s, W, D = ctx.Style, ctx.W, ctx.D
	local color = s.Accent
	for _, sz in { -1, 1 } do
		Part(ctx.Model, Vector3.new(W + 2.4, 0.3, 0.3), ctx.Origin * CFrame.new(0, 1, sz * (D / 2 + 1.05)), color, M.Neon, { CanCollide = false })
	end
	for _, sx in { -1, 1 } do
		Part(ctx.Model, Vector3.new(0.3, 0.3, D + 2.4), ctx.Origin * CFrame.new(sx * (W / 2 + 1.05), 1, 0), color, M.Neon, { CanCollide = false })
	end
end

function Features.Antenna(ctx)
	local top = ctx.WallTop + 1 + ctx.RoofRise
	Cylinder(ctx.Model, 6, 0.35, ctx.Origin * CFrame.new(0, top + 3, 0), rgb(180, 185, 195), M.Metal)
	local bulb = Ball(ctx.Model, 1.1, ctx.Origin * CFrame.new(0, top + 6.3, 0), rgb(255, 60, 90), M.Neon, { CanCollide = false })
	BuildUtil.Light(bulb, rgb(255, 60, 90), 10, 1.5)
end

function Features.Bows(ctx)
	-- One big bow over the door (window bows are added in buildWindow)
	HouseBuilder.Bow(ctx.Model, ctx.Origin * CFrame.new(0, ctx.WallTop - 0.3, -ctx.D / 2 - 0.6), ctx.Style.Accent)
end

function Features.Awning(ctx, colors)
	local W, D = ctx.W, ctx.D
	local span = W - 4
	local strips = math.floor(span / 2)
	local stripW = span / strips
	local depth, tilt = 5, math.rad(22)
	local y0, z0 = 1 + DOOR_H + 0.8, -D / 2
	local cy = y0 - math.sin(tilt) * depth / 2
	local cz = z0 - math.cos(tilt) * depth / 2
	for i = 1, strips do
		local x = -span / 2 + (i - 0.5) * stripW
		Part(ctx.Model, Vector3.new(stripW, 0.3, depth), ctx.Origin * CFrame.new(x, cy, cz) * CFrame.Angles(-tilt, 0, 0), colors[(i % 2) + 1], M.Fabric, { Name = "Awning" })
	end
	-- scalloped edge
	local edgeY = y0 - math.sin(tilt) * depth - 0.2
	local edgeZ = z0 - math.cos(tilt) * depth
	for i = 1, strips do
		local x = -span / 2 + (i - 0.5) * stripW
		Ball(ctx.Model, stripW * 0.9, ctx.Origin * CFrame.new(x, edgeY, edgeZ), colors[(i % 2) + 1], M.Fabric, { CanCollide = false })
	end
end

function Features.FlowerBoxes(_ctx)
	-- handled per window in buildWindow
end

function Features.Spots(_ctx)
	-- handled in Roofs.Dome
end

function Features.Crenellations(ctx)
	local W, D = ctx.W, ctx.D
	local y = ctx.WallTop + 1 + 0.9
	local color, material = ctx.Style.Wall.Color, ctx.Style.Wall.Material
	local size = Vector3.new(1.8, 1.8, 1.2)
	local x = -W / 2 + 1
	while x <= W / 2 - 1 do
		Part(ctx.Model, size, ctx.Origin * CFrame.new(x, y, -D / 2 - 0.4), color, material)
		Part(ctx.Model, size, ctx.Origin * CFrame.new(x, y, D / 2 + 0.4), color, material)
		x += 3.6
	end
	local z = -D / 2 + 2.8
	while z <= D / 2 - 1 do
		Part(ctx.Model, size, ctx.Origin * CFrame.new(-W / 2 - 0.4, y, z) * CFrame.Angles(0, math.pi / 2, 0), color, material)
		Part(ctx.Model, size, ctx.Origin * CFrame.new(W / 2 + 0.4, y, z) * CFrame.Angles(0, math.pi / 2, 0), color, material)
		z += 3.6
	end
end

function Features.CornerTowers(ctx, roofColor)
	local s, W, D, H = ctx.Style, ctx.W, ctx.D, ctx.H
	local towerH = H + 7
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local x, z = sx * W / 2, sz * D / 2
			Cylinder(ctx.Model, towerH, 7, ctx.Origin * CFrame.new(x, 1 + towerH / 2, z), s.Wall.Color, s.Wall.Material, { Name = "Tower" })
			Cylinder(ctx.Model, 0.8, 8, ctx.Origin * CFrame.new(x, 1 + towerH + 0.4, z), s.Trim.Color, s.Trim.Material)
			BuildUtil.Tiered(ctx.Model, ctx.Origin * CFrame.new(x, 1 + towerH + 0.8, z), 4.6, 9, 9, BuildUtil.ConeProfile, roofColor, M.Slate)
			Part(ctx.Model, Vector3.new(0.9, 3, 0.6), ctx.Origin * CFrame.new(x, 1 + towerH - 4, z + sz * 3.4), s.Window.Color, s.Window.Material, { CanCollide = false })
		end
	end
end

function Features.LogCorners(ctx)
	local s, W, D, H = ctx.Style, ctx.W, ctx.D, ctx.H
	local rows = math.floor(H / 1.6)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			for k = 0, rows - 1 do
				local y = 1 + 0.8 + k * 1.6
				local cf
				if k % 2 == 0 then
					cf = ctx.Origin * CFrame.new(sx * (W / 2 - 1), y, sz * (D / 2 - 0.5))
				else
					cf = ctx.Origin * CFrame.new(sx * (W / 2 - 0.5), y, sz * (D / 2 - 1)) * CFrame.Angles(0, math.pi / 2, 0)
				end
				Part(ctx.Model, Vector3.new(5, 1.6, 1.6), cf, s.Trim.Color, M.Wood, { Shape = Enum.PartType.Cylinder })
			end
		end
	end
end

function Features.PaperLanterns(ctx, color)
	local W, D = ctx.W, ctx.D
	local spots = {
		Vector3.new(W / 2 + 2.5, ctx.WallTop - 1.4, -D / 2 - 2.5),
		Vector3.new(-W / 2 - 2.5, ctx.WallTop - 1.4, -D / 2 - 2.5),
		Vector3.new(W / 2 + 2.5, ctx.WallTop - 1.4, D / 2 + 2.5),
		Vector3.new(-W / 2 - 2.5, ctx.WallTop - 1.4, D / 2 + 2.5),
		Vector3.new(DOOR_W / 2 + 2, 1 + DOOR_H - 1, -D / 2 - 1.2),
		Vector3.new(-DOOR_W / 2 - 2, 1 + DOOR_H - 1, -D / 2 - 1.2),
	}
	for i, p in spots do
		local cf = ctx.Origin * CFrame.new(p)
		Part(ctx.Model, Vector3.new(0.15, 1.2, 0.15), cf * CFrame.new(0, 1.6, 0), WOOD_DARK, M.SmoothPlastic, { CanCollide = false })
		local lantern = Ball(ctx.Model, 1.8, cf, color, M.Neon, { CanCollide = false, Transparency = 0.1 })
		Part(ctx.Model, Vector3.new(1.2, 0.3, 1.2), cf * CFrame.new(0, 0.95, 0), WOOD_DARK, M.Wood, { CanCollide = false })
		if i > 4 then
			BuildUtil.Light(lantern, rgb(255, 150, 110), 14, 1.3)
		end
	end
end

function Features.Crystals(ctx)
	local colors = { ctx.Style.Accent, ctx.Style.Trim.Color, rgb(255, 160, 240) }
	local W, D = ctx.W, ctx.D
	local spots = {
		Vector3.new(-W / 2 - 3, 0, -D / 2 - 3), Vector3.new(W / 2 + 3, 0, -D / 2 - 3),
		Vector3.new(-W / 2 - 3, 0, D / 2 + 2), Vector3.new(W / 2 + 3, 0, D / 2 + 2),
		Vector3.new(-W / 2 - 3.5, 0, 0), Vector3.new(W / 2 + 3.5, 0, 0),
		Vector3.new(-DOOR_W / 2 - 9, 0, -D / 2 - 6), Vector3.new(DOOR_W / 2 + 9, 0, -D / 2 - 6),
	}
	for _, p in spots do
		for _ = 1, 3 do
			local h = ctx.Rng:NextNumber(3, 7)
			local tilt = CFrame.Angles(ctx.Rng:NextNumber(-0.4, 0.4), ctx.Rng:NextNumber(0, math.pi), ctx.Rng:NextNumber(-0.4, 0.4))
			local cf = ctx.Origin * CFrame.new(p + Vector3.new(ctx.Rng:NextNumber(-1, 1), 0, ctx.Rng:NextNumber(-1, 1))) * tilt * CFrame.new(0, h / 2 - 0.5, 0)
			Part(ctx.Model, Vector3.new(1.1, h, 1.1), cf, colors[ctx.Rng:NextInteger(1, #colors)], M.Neon, { CanCollide = false, Transparency = 0.15 })
		end
	end
end

function Features.Pots(ctx)
	local clay = rgb(180, 100, 62)
	local D = ctx.D
	local spots = { Vector3.new(-DOOR_W / 2 - 3, 0, -D / 2 - 2.5), Vector3.new(DOOR_W / 2 + 3, 0, -D / 2 - 2.5), Vector3.new(-ctx.W / 2 - 1.5, 0, -D / 2 - 4), Vector3.new(ctx.W / 2 + 1.5, 0, -D / 2 - 4) }
	for _, p in spots do
		local cf = ctx.Origin * CFrame.new(p)
		Cylinder(ctx.Model, 2.4, 2.4, cf * CFrame.new(0, 1.2, 0), clay, M.Concrete)
		Cylinder(ctx.Model, 0.4, 2.8, cf * CFrame.new(0, 2.4, 0), clay, M.Concrete)
		Ball(ctx.Model, 2.2, cf * CFrame.new(0, 3, 0), rgb(70, 140, 70), M.Grass, { CanCollide = false })
	end
end

function Features.GlowShrooms(ctx)
	local colors = { rgb(120, 230, 255), rgb(200, 120, 255), rgb(255, 140, 200) }
	for i = 1, 7 do
		local x = ctx.Rng:NextNumber(-ctx.W / 2 - 2, ctx.W / 2 + 2)
		if math.abs(x) < 4 then
			x += 8
		end
		local z = -ctx.D / 2 - ctx.Rng:NextNumber(3, 14)
		local h = ctx.Rng:NextNumber(1, 2.4)
		local cf = ctx.Origin * CFrame.new(x, 0, z)
		Cylinder(ctx.Model, h, 0.5, cf * CFrame.new(0, h / 2, 0), rgb(240, 235, 220), M.SmoothPlastic, { CanCollide = false })
		local cap = Cylinder(ctx.Model, 0.5, h * 1.3, cf * CFrame.new(0, h, 0), colors[(i % #colors) + 1], M.Neon, { CanCollide = false })
		if i <= 2 then
			BuildUtil.Light(cap, colors[(i % #colors) + 1], 8, 1)
		end
	end
end

function Features.HayBales(ctx)
	local hay = rgb(222, 190, 95)
	local yard = ctx.PlotOrigin
	Part(ctx.Model, Vector3.new(4, 2.4, 2.6), yard * CFrame.new(-20, 1.2, -18), hay, M.Grass)
	Part(ctx.Model, Vector3.new(4, 2.4, 2.6), yard * CFrame.new(-16, 1.2, -18.5) * CFrame.Angles(0, 0.3, 0), hay, M.Grass)
	Part(ctx.Model, Vector3.new(4, 2.4, 2.6), yard * CFrame.new(-18, 3.6, -18.2) * CFrame.Angles(0, 0.15, 0), hay, M.Grass)
end

function Features.Fence(ctx)
	local white = rgb(245, 242, 235)
	local half = Config.PlotSize / 2 - 1
	local function run(from: Vector3, to: Vector3)
		local delta = to - from
		local length = delta.Magnitude
		local mid = (from + to) / 2
		local look = ctx.PlotOrigin * CFrame.lookAt(mid, mid + delta)
		for _, y in { 1.1, 2.3 } do
			Part(ctx.Model, Vector3.new(0.25, 0.4, length), look * CFrame.new(0, y, 0), white, M.WoodPlanks)
		end
		local posts = math.floor(length / 3.5)
		for i = 0, posts do
			local p = from + delta * (i / posts)
			Part(ctx.Model, Vector3.new(0.6, 3.2, 0.6), ctx.PlotOrigin * CFrame.new(p + Vector3.new(0, 1.6, 0)), white, M.WoodPlanks)
		end
	end
	run(Vector3.new(-half, 0, half), Vector3.new(half, 0, half))
	run(Vector3.new(-half, 0, -half), Vector3.new(-half, 0, half))
	run(Vector3.new(half, 0, -half), Vector3.new(half, 0, half))
	run(Vector3.new(-half, 0, -half), Vector3.new(-6, 0, -half))
	run(Vector3.new(6, 0, -half), Vector3.new(half, 0, -half))
end

--------------------------------------------------------------------------------
-- Interior
--------------------------------------------------------------------------------

local function bottle(ctx, standCF: CFrame)
	local rng = ctx.Rng
	local color = Config.PotionColors[rng:NextInteger(1, #Config.PotionColors)]
	local glowing = rng:NextNumber() < 0.4
	local material = glowing and M.Neon or M.Glass
	local props = { CanCollide = false, CastShadow = false, Transparency = glowing and 0 or 0.15 }
	local cork = rgb(150, 105, 70)
	local kind = rng:NextInteger(1, 3)
	local m = ctx.Model
	if kind == 1 then -- round flask
		Ball(m, 1.1, standCF * CFrame.new(0, 0.55, 0), color, material, table.clone(props))
		Cylinder(m, 0.6, 0.35, standCF * CFrame.new(0, 1.3, 0), color, M.Glass, table.clone(props))
		Cylinder(m, 0.25, 0.42, standCF * CFrame.new(0, 1.7, 0), cork, M.Wood, { CanCollide = false, CastShadow = false })
	elseif kind == 2 then -- tall vial
		Cylinder(m, 1.5, 0.6, standCF * CFrame.new(0, 0.75, 0), color, material, table.clone(props))
		Cylinder(m, 0.25, 0.45, standCF * CFrame.new(0, 1.62, 0), cork, M.Wood, { CanCollide = false, CastShadow = false })
	else -- squat jar
		Cylinder(m, 1.1, 1.0, standCF * CFrame.new(0, 0.55, 0), color, material, table.clone(props))
		Cylinder(m, 0.2, 1.1, standCF * CFrame.new(0, 1.2, 0), cork, M.Wood, { CanCollide = false, CastShadow = false })
	end
end

local function shelfUnit(ctx, cf: CFrame, length: number, levels: { number })
	-- `cf` sits on the floor at the middle of the unit; shelves run along local X.
	local wood = WOOD_DARK
	local topLevel = levels[#levels]
	for _, x in { -length / 2, 0, length / 2 } do
		Part(ctx.Model, Vector3.new(0.4, topLevel + 0.6, 1.7), cf * CFrame.new(x, (topLevel + 0.6) / 2, 0), wood, M.Wood)
	end
	for _, y in levels do
		Part(ctx.Model, Vector3.new(length + 0.4, 0.3, 1.7), cf * CFrame.new(0, y, 0), wood, M.WoodPlanks)
		local count = math.floor((length - 0.6) / 1.5)
		for i = 1, count do
			local x = -length / 2 + 0.3 + (i - 0.5) * ((length - 0.6) / count)
			if math.abs(x) > 0.5 and math.abs(math.abs(x) - length / 2) > 0.5 and ctx.Rng:NextNumber() < 0.85 then
				bottle(ctx, cf * CFrame.new(x, y + 0.15, ctx.Rng:NextNumber(-0.3, 0.3)))
			end
		end
	end
end

local function buildCauldron(ctx, cf: CFrame)
	local m = ctx.Model
	local iron = rgb(38, 36, 42)
	for i = 0, 2 do
		local a = i * math.pi * 2 / 3
		Cylinder(m, 0.8, 0.5, cf * CFrame.new(math.cos(a) * 1.6, 0.4, math.sin(a) * 1.6), iron, M.Metal)
	end
	local radii = { 1.7, 2.3, 2.6, 2.7, 2.6 }
	local y = 0.6
	for _, r in radii do
		Cylinder(m, 0.7, r * 2, cf * CFrame.new(0, y + 0.35, 0), iron, M.Metal, { Name = "Cauldron" })
		y += 0.7
	end
	Cylinder(m, 0.4, 5.8, cf * CFrame.new(0, y + 0.2, 0), rgb(55, 52, 60), M.Metal, { Name = "CauldronRim" })
	local liquidColor = Config.PotionColors[1]
	local liquid = Cylinder(m, 0.2, 4.8, cf * CFrame.new(0, y + 0.35, 0), liquidColor, M.Neon, { Name = "Brew", CanCollide = false })

	local fx = Part(m, Vector3.new(4, 0.2, 4), cf * CFrame.new(0, y + 0.6, 0), rgb(0, 0, 0), M.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false, Name = "BrewFX" })
	local light = BuildUtil.Light(fx, liquidColor, 16, 2.2, true)
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Name = "Bubbles"
	bubbles.Color = ColorSequence.new(liquidColor)
	bubbles.LightEmission = 0.8
	bubbles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	bubbles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1.8) })
	bubbles.Lifetime = NumberRange.new(1.5, 3)
	bubbles.Speed = NumberRange.new(2, 4)
	bubbles.Rate = 10
	bubbles.SpreadAngle = Vector2.new(18, 18)
	bubbles.Parent = fx

	local embers = Part(m, Vector3.new(1.6, 0.3, 1.6), cf * CFrame.new(0, 0.2, 0), rgb(255, 120, 40), M.Neon, { CanCollide = false })
	local fire = Instance.new("Fire")
	fire.Size = 3
	fire.Heat = 3
	fire.Color = rgb(255, 140, 50)
	fire.SecondaryColor = rgb(255, 60, 20)
	fire.Parent = embers

	local prompt = BuildUtil.Prompt(fx, "Stir", "Cauldron")
	prompt.MaxActivationDistance = 9
	ctx.Info.Cauldron = { Liquid = liquid, Light = light, Bubbles = bubbles, Prompt = prompt, BaseColor = liquidColor }
end

local function buildInterior(ctx)
	local s, m, W, D = ctx.Style, ctx.Model, ctx.W, ctx.D
	local function L(x, y, z)
		return ctx.Origin * CFrame.new(x, y, z)
	end
	local top = ctx.WallTop

	-- Rug + cauldron in the middle of the room
	Part(m, Vector3.new(W * 0.45, 0.06, D * 0.42), L(0, FLOOR_Y + 0.03, 2), s.Accent, M.Carpet, { CanCollide = false })
	buildCauldron(ctx, L(0, FLOOR_Y, 2))

	-- Shelves full of potion bottles on the back and left walls
	shelfUnit(ctx, L(0, FLOOR_Y, D / 2 - T - 0.9), W - 2 * T - 2, { 2.6, 5.4, 8.2 })
	local zA, zB = -D / 2 + 8.5, D / 2 - T - 2.5
	shelfUnit(ctx, L(-W / 2 + T + 0.9, FLOOR_Y, (zA + zB) / 2) * CFrame.Angles(0, math.pi / 2, 0), zB - zA, { 2.6, 5.4 })

	-- Shop counter by the door, with a till and a little bell
	local counter = L(W / 4 + 1, FLOOR_Y, -D / 2 + 5.5)
	Part(m, Vector3.new(9, 3.5, 2.4), counter * CFrame.new(0, 1.75, 0), WOOD_DARK, M.WoodPlanks, { Name = "Counter" })
	Part(m, Vector3.new(9.6, 0.4, 3), counter * CFrame.new(0, 3.7, 0), s.Trim.Color, s.Trim.Material)
	Part(m, Vector3.new(1.8, 1.2, 1.2), counter * CFrame.new(2.6, 4.5, 0), rgb(200, 160, 70), M.Metal, { Name = "Till" })
	Ball(m, 0.7, counter * CFrame.new(-2.8, 4.25, 0), rgb(255, 210, 90), M.Metal, { CanCollide = false })
	for i = -1, 1 do
		bottle(ctx, counter * CFrame.new(i * 1.1 - 0.3, 3.9, 0.3))
	end
	local candle = Part(m, Vector3.new(0.3, 0.9, 0.3), counter * CFrame.new(-4, 4.35, 0.6), rgb(250, 240, 220), M.SmoothPlastic, { CanCollide = false })
	local flame = Part(m, Vector3.new(0.2, 0.35, 0.2), candle.CFrame * CFrame.new(0, 0.6, 0), rgb(255, 190, 90), M.Neon, { CanCollide = false })
	BuildUtil.Light(flame, rgb(255, 170, 90), 8, 1)

	-- Barrels by the left front corner
	for i = 0, 1 do
		Cylinder(m, 3, 2.6, L(-W / 2 + 2.8, FLOOR_Y + 1.5, -D / 2 + 3 + i * 3), rgb(120, 80, 50), M.Wood)
		Cylinder(m, 0.3, 2.75, L(-W / 2 + 2.8, FLOOR_Y + 2.4, -D / 2 + 3 + i * 3), rgb(60, 60, 65), M.Metal)
	end

	-- Ceiling beams, hanging lanterns and drying herbs
	for _, z in { -D / 4, 0, D / 4 } do
		Part(m, Vector3.new(W - 2 * T, 0.8, 0.8), L(0, top - 0.4, z), s.Trim.Color, s.Trim.Material, { Name = "Beam" })
	end
	for _, p in { Vector3.new(-W / 4, 0, -D / 4), Vector3.new(W / 4, 0, -D / 4), Vector3.new(0, 0, D / 4) } do
		Part(m, Vector3.new(0.15, 1.4, 0.15), L(p.X, top - 1.5, p.Z), WOOD_DARK, M.Metal, { CanCollide = false })
		BuildUtil.Lantern(m, L(p.X, top - 3.2, p.Z), s.Light, nil, 22)
	end
	local herbColors = { rgb(90, 140, 70), rgb(120, 160, 80), rgb(140, 100, 170), rgb(170, 130, 70) }
	local x = -W / 2 + 3
	while x < W / 2 - 3 do
		if math.abs(x) > 3.5 then
			local color = herbColors[ctx.Rng:NextInteger(1, #herbColors)]
			Part(m, Vector3.new(0.1, 0.8, 0.1), L(x, top - 1.2, 0), WOOD_DARK, M.SmoothPlastic, { CanCollide = false })
			Part(m, Vector3.new(0.7, 1.6, 0.7), L(x, top - 2.4, 0), color, M.LeafyGrass, { CanCollide = false, CastShadow = false })
		end
		x += 2.4
	end
end

--------------------------------------------------------------------------------
-- Front yard: path, lamps and the shop sign
--------------------------------------------------------------------------------

local function buildYard(ctx, ownerName: string)
	local s, m = ctx.Style, ctx.Model
	local yard = ctx.PlotOrigin
	local half = Config.PlotSize / 2
	local doorZ = Config.HouseOffset - ctx.D / 2 - 2.4
	local pathLength = doorZ + half
	Part(m, Vector3.new(5, 0.3, pathLength), yard * CFrame.new(0, 0.15, -half + pathLength / 2), rgb(150, 140, 135), M.Cobblestone, { Name = "Path" })

	for _, sx in { -1, 1 } do
		BuildUtil.LampPost(m, yard * CFrame.new(sx * 5, 0, -half + 3))
	end

	-- Sign post beside the path
	local signCF = yard * CFrame.new(-6.5, 0, doorZ - 6) * CFrame.Angles(0, math.rad(25), 0)
	Cylinder(m, 4.6, 0.5, signCF * CFrame.new(-2.2, 2.3, 0), WOOD_DARK, M.Wood)
	Cylinder(m, 4.6, 0.5, signCF * CFrame.new(2.2, 2.3, 0), WOOD_DARK, M.Wood)
	local board = Part(m, Vector3.new(5.4, 2.6, 0.4), signCF * CFrame.new(0, 4, 0), s.Trim.Material == M.Neon and rgb(40, 45, 60) or s.Trim.Color, s.Trim.Material == M.Neon and M.Metal or s.Trim.Material, { Name = "ShopSign" })
	local signText = string.format("%s\n%s's Potions", s.Emoji, ownerName)
	BuildUtil.SurfaceText(board, Enum.NormalId.Front, signText, rgb(255, 235, 190))
	BuildUtil.SurfaceText(board, Enum.NormalId.Back, signText, rgb(255, 235, 190))
	if s.Features.Bows then
		HouseBuilder.Bow(m, signCF * CFrame.new(0, 5.5, -0.3), s.Accent)
	end

	local sparkle = BuildUtil.Prompt(board, "Leave a Sparkle ✨", ownerName .. "'s Shop")
	sparkle:SetAttribute("Audience", "Visitor")
	local restyle = BuildUtil.Prompt(board, "Change Shop Style", "Your Shop")
	restyle:SetAttribute("Audience", "Owner")
	restyle.KeyboardKeyCode = Enum.KeyCode.R
	restyle.GamepadKeyCode = Enum.KeyCode.ButtonY
	ctx.Info.SparklePrompt = sparkle
	ctx.Info.StylePrompt = restyle
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--[[
	Builds a house for `owner` on the plot at `plotCFrame`.
	Returns the Model (not yet parented) and an info table:
	  SpawnCFrame, VisitCFrame, Door, Cauldron, SparklePrompt, StylePrompt,
	  NameTitle, NameSubtitle
]]
function HouseBuilder.Build(style, plotCFrame: CFrame, owner: Player)
	local model = Instance.new("Model")
	model.Name = "House"

	local ctx = {
		Model = model,
		Style = style,
		W = style.Width,
		D = style.Depth,
		H = style.WallHeight,
		WallTop = 1 + style.WallHeight,
		PlotOrigin = plotCFrame * CFrame.new(0, 0.5, 0),
		Origin = plotCFrame * CFrame.new(0, 0.5, Config.HouseOffset),
		Rng = Random.new(owner.UserId + style.Order * 1000),
		RoofRise = 0,
		Info = {},
	}

	buildShell(ctx)
	local roofTop = Roofs[style.Roof.Type](ctx)
	for name, value in style.Features do
		local feature = Features[name]
		if feature then
			feature(ctx, value)
		else
			warn("[HouseBuilder] Unknown feature", name, "in style", style.Id)
		end
	end
	buildInterior(ctx)
	buildYard(ctx, owner.DisplayName)

	-- Floating name tag above the roof
	local tagAnchor = Part(model, Vector3.new(1, 1, 1), ctx.Origin * CFrame.new(0, roofTop + 5, 0), rgb(0, 0, 0), M.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false, Name = "NameTagAnchor" })
	local _, title, subtitle = BuildUtil.Billboard(tagAnchor, owner.DisplayName .. "'s Potion Shop", style.Emoji .. " " .. style.DisplayName .. "  ·  ✨ 0")

	local info = ctx.Info
	info.Model = model
	info.Style = style
	info.NameTitle = title
	info.NameSubtitle = subtitle
	-- Owners appear inside, just behind the door, looking at the cauldron.
	local spawnPos = Vector3.new(0, FLOOR_Y + 3.2, -ctx.D / 2 + 4)
	info.SpawnCFrame = ctx.Origin * CFrame.lookAt(spawnPos, spawnPos + Vector3.new(0, 0, 1))
	-- Visitors appear on the path, facing the front door.
	local visitPos = Vector3.new(0, 3.5, -ctx.D / 2 - 8)
	info.VisitCFrame = ctx.Origin * CFrame.lookAt(visitPos, visitPos + Vector3.new(0, 0, 1))

	model.PrimaryPart = model:FindFirstChild("Foundation")
	return model, info
end

return HouseBuilder
