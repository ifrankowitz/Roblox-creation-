--[[
	BuildUtil
	Small helpers for making anchored parts from code. Everything in Potion
	Town is built by script, so the world can be rebuilt or restyled at any time.
]]

local BuildUtil = {}

local UP = CFrame.Angles(0, 0, math.pi / 2) -- turns a Roblox cylinder (X axis) upright

-- Creates an anchored part. `props` may contain any Part property, plus
-- ClassName (e.g. "WedgePart") and Shape (applied before Size so balls work).
function BuildUtil.Part(parent: Instance, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, props: { [string]: any }?)
	local part = Instance.new(props and props.ClassName or "Part")
	if props and props.Shape then
		part.Shape = props.Shape
	end
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if props then
		for key, value in pairs(props) do
			if key ~= "ClassName" and key ~= "Shape" then
				part[key] = value
			end
		end
	end
	part.Parent = parent
	return part
end

-- Upright cylinder whose centre is at `cframe`.
function BuildUtil.Cylinder(parent, height: number, diameter: number, cframe: CFrame, color, material, props)
	props = props or {}
	props.Shape = Enum.PartType.Cylinder
	return BuildUtil.Part(parent, Vector3.new(height, diameter, diameter), cframe * UP, color, material, props)
end

function BuildUtil.Ball(parent, diameter: number, cframe: CFrame, color, material, props)
	props = props or {}
	props.Shape = Enum.PartType.Ball
	return BuildUtil.Part(parent, Vector3.one * diameter, cframe, color, material, props)
end

function BuildUtil.Light(part: BasePart, color: Color3, range: number, brightness: number, shadows: boolean?)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = shadows == true
	light.Parent = part
	return light
end

-- A round roof/dome/cone built from stacked cylinders.
-- `baseCFrame` is the centre of the bottom of the shape.
-- profile(t) returns the radius multiplier at height fraction t (0..1).
function BuildUtil.Tiered(parent, baseCFrame: CFrame, radius: number, height: number, tiers: number, profile: (number) -> number, color, material, props)
	local tierHeight = height / tiers
	local parts = {}
	for i = 1, tiers do
		local t = (i - 1) / tiers
		local r = math.max(radius * profile(t), 0.4)
		local cf = baseCFrame * CFrame.new(0, (i - 0.5) * tierHeight, 0)
		local copy = props and table.clone(props) or nil
		parts[i] = { Part = BuildUtil.Cylinder(parent, tierHeight, r * 2, cf, color, material, copy), Radius = r, Y = (i - 0.5) * tierHeight }
	end
	return parts
end

BuildUtil.DomeProfile = function(t)
	return math.sqrt(math.max(1 - t * t, 0))
end

BuildUtil.ConeProfile = function(t)
	return 1 - t
end

-- Glowing lantern: dark frame, neon core and a warm point light.
function BuildUtil.Lantern(parent, cframe: CFrame, lightColor: Color3, frameColor: Color3?, range: number?)
	local frame = frameColor or Color3.fromRGB(40, 32, 30)
	BuildUtil.Part(parent, Vector3.new(1.4, 0.3, 1.4), cframe * CFrame.new(0, 1, 0), frame, Enum.Material.Metal, { CanCollide = false })
	BuildUtil.Part(parent, Vector3.new(1.4, 0.3, 1.4), cframe * CFrame.new(0, -1, 0), frame, Enum.Material.Metal, { CanCollide = false })
	local core = BuildUtil.Part(parent, Vector3.new(1, 1.7, 1), cframe, lightColor, Enum.Material.Neon, { CanCollide = false, Name = "LanternCore" })
	BuildUtil.Light(core, lightColor, range or 16, 1.4, true)
	return core
end

-- Street lamp used around the plaza and at every plot entrance.
function BuildUtil.LampPost(parent, groundCFrame: CFrame)
	local metal = Color3.fromRGB(35, 30, 38)
	BuildUtil.Cylinder(parent, 1, 1.6, groundCFrame * CFrame.new(0, 0.5, 0), metal, Enum.Material.Metal)
	BuildUtil.Cylinder(parent, 10, 0.6, groundCFrame * CFrame.new(0, 5, 0), metal, Enum.Material.Metal)
	BuildUtil.Lantern(parent, groundCFrame * CFrame.new(0, 11, 0), Color3.fromRGB(255, 190, 120), metal, 22)
	BuildUtil.Part(parent, Vector3.new(2, 0.4, 2), groundCFrame * CFrame.new(0, 12.3, 0), metal, Enum.Material.Metal)
end

-- Floating name tag. Returns the BillboardGui and its two labels.
function BuildUtil.Billboard(adornee: BasePart, title: string, subtitle: string, maxDistance: number?)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.fromOffset(280, 72)
	gui.LightInfluence = 0
	gui.MaxDistance = maxDistance or 260
	gui.Adornee = adornee

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, 0, 0.6, 0)
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.TextScaled = true
	titleLabel.TextColor3 = Color3.fromRGB(255, 230, 170)
	titleLabel.TextStrokeTransparency = 0.3
	titleLabel.TextStrokeColor3 = Color3.fromRGB(40, 20, 50)
	titleLabel.Text = title
	titleLabel.Parent = gui

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Position = UDim2.new(0, 0, 0.6, 0)
	subtitleLabel.Size = UDim2.new(1, 0, 0.4, 0)
	subtitleLabel.Font = Enum.Font.GothamBold
	subtitleLabel.TextScaled = true
	subtitleLabel.TextColor3 = Color3.fromRGB(235, 220, 255)
	subtitleLabel.TextStrokeTransparency = 0.4
	subtitleLabel.Text = subtitle
	subtitleLabel.Parent = gui

	gui.Parent = adornee
	return gui, titleLabel, subtitleLabel
end

-- Text painted on one face of a part (used for shop signs).
function BuildUtil.SurfaceText(part: BasePart, face: Enum.NormalId, text: string, textColor: Color3)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.3
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = textColor
	label.Text = text
	label.Parent = gui
	gui.Parent = part
	return label
end

function BuildUtil.Prompt(part: BasePart, actionText: string, objectText: string, holdDuration: number?)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = holdDuration or 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

return BuildUtil
