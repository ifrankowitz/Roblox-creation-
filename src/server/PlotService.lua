--[[
	PlotService
	Hands out plots to players as they join, builds their shop in the style
	they picked, wires up the shop's interactive bits, and frees the plot
	when they leave.

	Each plot Model carries attributes the client reads for the Visit menu:
	  OwnerUserId, OwnerName, StyleId
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local HouseBuilder = require(script.Parent.HouseBuilder)
local PlayerData = require(script.Parent.PlayerData)
local Remotes = require(script.Parent.Remotes)

local PlotService = {}

type PlotRecord = {
	Index: number,
	Model: Model,
	CFrame: CFrame,
	ForSaleSign: Instance?,
	Owner: Player?,
	House: Model?,
	Info: { [string]: any }?,
	SparkledBy: { [number]: boolean },
}

local records: { PlotRecord } = {}
local byPlayer: { [Player]: PlotRecord } = {}

local function notify(player: Player, message: string)
	Remotes.Notify:FireClient(player, message)
end

local function updateNameTag(record: PlotRecord)
	local info = record.Info
	if not (info and record.Owner) then
		return
	end
	local data = PlayerData.Get(record.Owner)
	local sparkles = data and data.Sparkles or 0
	info.NameSubtitle.Text = string.format("%s %s  ·  ✨ %d", info.Style.Emoji, info.Style.DisplayName, sparkles)
end

local function sparkleBurst(part: BasePart)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 230, 140), Color3.fromRGB(255, 150, 230))
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new(0.5, 0)
	emitter.Lifetime = NumberRange.new(0.8, 1.6)
	emitter.Speed = NumberRange.new(6, 12)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Parent = part
	emitter:Emit(40)
	task.delay(2, emitter.Destroy, emitter)
end

-- Connects the door, cauldron and shop sign of a freshly built house.
local function attachInteractions(record: PlotRecord)
	local info = record.Info :: { [string]: any }
	local owner = record.Owner :: Player

	-- Door: starts open so visitors can wander in; anyone can open/close it.
	local door = info.Door
	local isOpen = true
	door.Part.CFrame = door.Open
	local doorPrompt = Instance.new("ProximityPrompt")
	doorPrompt.ActionText = "Close"
	doorPrompt.ObjectText = "Door"
	doorPrompt.RequiresLineOfSight = false
	doorPrompt.MaxActivationDistance = 8
	doorPrompt.Parent = door.Part
	doorPrompt.Triggered:Connect(function()
		isOpen = not isOpen
		doorPrompt.ActionText = isOpen and "Close" or "Open"
		TweenService:Create(door.Part, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = isOpen and door.Open or door.Closed,
		}):Play()
	end)

	-- Cauldron: stirring makes it bubble up in a random potion colour.
	-- (Real brewing with ingredients arrives in Phase 2.)
	local cauldron = info.Cauldron
	local stirring = false
	cauldron.Prompt.Triggered:Connect(function(player)
		if stirring then
			return
		end
		stirring = true
		local color = cauldron.BaseColor
		while color == cauldron.BaseColor do
			color = Config.PotionColors[math.random(1, #Config.PotionColors)]
		end
		local tweenInfo = TweenInfo.new(0.6)
		TweenService:Create(cauldron.Liquid, tweenInfo, { Color = color }):Play()
		TweenService:Create(cauldron.Light, tweenInfo, { Color = color }):Play()
		cauldron.Bubbles.Color = ColorSequence.new(color)
		cauldron.Bubbles:Emit(45)
		if player == owner then
			notify(player, "The brew shimmers... gather ingredients to brew real potions soon! 🧪")
		end
		task.delay(4, function()
			if not cauldron.Liquid.Parent then
				return
			end
			TweenService:Create(cauldron.Liquid, tweenInfo, { Color = cauldron.BaseColor }):Play()
			TweenService:Create(cauldron.Light, tweenInfo, { Color = cauldron.BaseColor }):Play()
			cauldron.Bubbles.Color = ColorSequence.new(cauldron.BaseColor)
			stirring = false
		end)
	end)

	-- Shop sign: visitors leave a sparkle, the owner can restyle.
	info.SparklePrompt:SetAttribute("OwnerUserId", owner.UserId)
	info.StylePrompt:SetAttribute("OwnerUserId", owner.UserId)

	info.SparklePrompt.Triggered:Connect(function(player)
		if player == owner then
			return
		end
		if record.SparkledBy[player.UserId] then
			notify(player, "You already left a sparkle here this visit ✨")
			return
		end
		record.SparkledBy[player.UserId] = true
		local data = PlayerData.Get(owner)
		if data then
			data.Sparkles += 1
		end
		updateNameTag(record)
		sparkleBurst(info.SparklePrompt.Parent)
		notify(player, "You left a sparkle for " .. owner.DisplayName .. "'s shop! ✨")
		notify(owner, player.DisplayName .. " left a sparkle on your shop! ✨")
	end)

	info.StylePrompt.Triggered:Connect(function(player)
		if player == owner then
			Remotes.OpenStylePicker:FireClient(player, false)
		end
	end)
end

local function rootPart(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function PlotService.Init(plotModels: { Model })
	for index, model in plotModels do
		records[index] = {
			Index = index,
			Model = model,
			CFrame = Config.GetPlotCFrame(index),
			ForSaleSign = model:FindFirstChild("ForSaleSign"),
			Owner = nil,
			House = nil,
			Info = nil,
			SparkledBy = {},
		}
	end
end

function PlotService.Claim(player: Player): PlotRecord?
	if byPlayer[player] then
		return byPlayer[player]
	end
	for _, record in records do
		if not record.Owner then
			record.Owner = player
			byPlayer[player] = record
			if record.ForSaleSign then
				record.ForSaleSign.Parent = nil
			end
			record.Model:SetAttribute("OwnerUserId", player.UserId)
			record.Model:SetAttribute("OwnerName", player.DisplayName)
			return record
		end
	end
	return nil
end

function PlotService.Get(player: Player): PlotRecord?
	return byPlayer[player]
end

function PlotService.GetByUserId(userId: number): PlotRecord?
	for _, record in records do
		if record.Owner and record.Owner.UserId == userId then
			return record
		end
	end
	return nil
end

-- Builds (or rebuilds) the player's shop in the given style.
function PlotService.SetStyle(player: Player, style)
	local record = byPlayer[player]
	if not record then
		return
	end

	-- Remember who is standing in or near the old house so nobody ends up
	-- stuck inside a wall after the rebuild.
	local nearby = {}
	local centre = record.CFrame.Position
	for _, other in Players:GetPlayers() do
		local root = rootPart(other)
		if root and (root.Position - centre).Magnitude < Config.PlotSize * 0.75 then
			table.insert(nearby, other)
		end
	end

	if record.House then
		record.House:Destroy()
	end
	local model, info = HouseBuilder.Build(style, record.CFrame, player)
	model.Parent = record.Model
	record.House = model
	record.Info = info
	record.Model:SetAttribute("StyleId", style.Id)
	attachInteractions(record)
	updateNameTag(record)

	for _, other in nearby do
		PlotService.TeleportToShop(other, record)
	end
end

-- Owners land inside their shop; visitors land on the path outside the door.
function PlotService.TeleportToShop(player: Player, record: PlotRecord)
	local character = player.Character
	local info = record.Info
	if not (character and info) then
		return
	end
	local target = (record.Owner == player) and info.SpawnCFrame or info.VisitCFrame
	character:PivotTo(target)
end

function PlotService.Release(player: Player)
	local record = byPlayer[player]
	if not record then
		return
	end
	byPlayer[player] = nil
	if record.House then
		record.House:Destroy()
	end
	record.Owner = nil
	record.House = nil
	record.Info = nil
	record.SparkledBy = {}
	record.Model:SetAttribute("OwnerUserId", nil)
	record.Model:SetAttribute("OwnerName", nil)
	record.Model:SetAttribute("StyleId", nil)
	if record.ForSaleSign then
		record.ForSaleSign.Parent = record.Model
	end
end

return PlotService
