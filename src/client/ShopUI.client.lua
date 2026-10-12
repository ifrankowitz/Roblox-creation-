--[[
	ShopUI (client)
	  - Side menu: Home / Style / Visit / Town
	  - Style picker with the 10 shop vibes
	  - Visit menu listing every other player's shop
	  - Toast notifications from the server
	  - Shows owner-only prompts (Change Style) to the owner and
	    visitor-only prompts (Leave a Sparkle) to everyone else
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local HouseStyles = require(ReplicatedStorage.Shared.HouseStyles)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local ChooseStyle = remotes:WaitForChild("ChooseStyle")
local RequestTeleport = remotes:WaitForChild("RequestTeleport")
local OpenStylePicker = remotes:WaitForChild("OpenStylePicker")
local Notify = remotes:WaitForChild("Notify")

local rgb = Color3.fromRGB
local THEME = {
	Panel = rgb(34, 24, 48),
	Card = rgb(54, 38, 76),
	CardHover = rgb(72, 52, 100),
	Gold = rgb(255, 205, 110),
	Text = rgb(245, 235, 255),
	Muted = rgb(190, 175, 210),
	Button = rgb(120, 70, 180),
}

--------------------------------------------------------------------------------
-- Small UI helpers
--------------------------------------------------------------------------------

local function create(className: string, props: { [string]: any }, children: { Instance }?)
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	instance.Parent = props.Parent
	return instance
end

local function corner(radius: number)
	return create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function stroke(color: Color3, thickness: number)
	return create("UIStroke", { Color = color, Thickness = thickness, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function label(props)
	props.BackgroundTransparency = 1
	props.TextColor3 = props.TextColor3 or THEME.Text
	props.Font = props.Font or Enum.Font.GothamMedium
	return create("TextLabel", props)
end

--------------------------------------------------------------------------------
-- Root
--------------------------------------------------------------------------------

local gui = create("ScreenGui", {
	Name = "PotionTownUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

local uiScale = create("UIScale", { Parent = gui })
local function rescale()
	local camera = workspace.CurrentCamera
	if camera then
		uiScale.Scale = math.clamp(camera.ViewportSize.Y / 820, 0.6, 1.15)
	end
end
rescale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

local function makePanel(name: string, title: string, maxSize: Vector2)
	local panel = create("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.86, 0.82),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = 0.05,
		Visible = false,
		Parent = gui,
	}, {
		corner(18),
		stroke(THEME.Gold, 2),
		create("UISizeConstraint", { MaxSize = maxSize }),
	})
	local titleLabel = label({
		Name = "Title",
		Text = title,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		TextColor3 = THEME.Gold,
		Position = UDim2.fromOffset(20, 12),
		Size = UDim2.new(1, -80, 0, 38),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	})
	local close = create("TextButton", {
		Name = "Close",
		Text = "✕",
		Font = Enum.Font.GothamBold,
		TextSize = 22,
		TextColor3 = THEME.Text,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = THEME.Card,
		Parent = panel,
	}, { corner(12) })
	close.Activated:Connect(function()
		panel.Visible = false
	end)
	return panel, titleLabel
end

--------------------------------------------------------------------------------
-- Toasts
--------------------------------------------------------------------------------

local toast = label({
	Name = "Toast",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -110),
	Size = UDim2.fromOffset(560, 50),
	BackgroundTransparency = 0.15,
	BackgroundColor3 = THEME.Panel,
	TextWrapped = true,
	TextSize = 18,
	Font = Enum.Font.GothamBold,
	Visible = false,
	Parent = gui,
})
toast.BackgroundTransparency = 0.15
corner(14).Parent = toast
stroke(THEME.Gold, 1.5).Parent = toast
create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = toast })

local toastToken = 0
local function showToast(message: string)
	toastToken += 1
	local token = toastToken
	toast.Text = message
	toast.TextTransparency = 0
	toast.BackgroundTransparency = 0.15
	toast.Visible = true
	task.delay(4, function()
		if token ~= toastToken then
			return
		end
		local fade = TweenInfo.new(0.6)
		TweenService:Create(toast, fade, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		task.wait(0.6)
		if token == toastToken then
			toast.Visible = false
		end
	end)
end
Notify.OnClientEvent:Connect(showToast)

--------------------------------------------------------------------------------
-- Plot helpers (plots carry OwnerUserId / OwnerName / StyleId attributes)
--------------------------------------------------------------------------------

local function plotsFolder(): Instance?
	local town = workspace:FindFirstChild("Town")
	return town and town:FindFirstChild("Plots")
end

local function myStyleId(): string?
	local folder = plotsFolder()
	if not folder then
		return nil
	end
	for _, plot in folder:GetChildren() do
		if plot:GetAttribute("OwnerUserId") == player.UserId then
			return plot:GetAttribute("StyleId")
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- Style picker
--------------------------------------------------------------------------------

local stylePanel, styleTitle = makePanel("StylePicker", "Choose your shop's vibe", Vector2.new(820, 600))
local styleSubtitle = label({
	Text = "Pick a look for your potion shop. You can change it any time from the 🎨 button or your shop sign.",
	TextWrapped = true,
	TextSize = 15,
	TextColor3 = THEME.Muted,
	TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromOffset(20, 52),
	Size = UDim2.new(1, -40, 0, 36),
	Parent = stylePanel,
})

local grid = create("ScrollingFrame", {
	Position = UDim2.fromOffset(16, 96),
	Size = UDim2.new(1, -32, 1, -112),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	ScrollBarImageColor3 = THEME.Gold,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Parent = stylePanel,
}, {
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(180, 196),
		CellPadding = UDim2.fromOffset(12, 12),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
	create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8) }),
})

local cardStrokes: { [string]: UIStroke } = {}

-- A tiny flat drawing of the house: roof band, walls, door, two windows.
local function stylePreview(style, parent: Instance)
	local preview = create("Frame", {
		Size = UDim2.new(1, -16, 0, 96),
		Position = UDim2.fromOffset(8, 8),
		BackgroundColor3 = rgb(70, 95, 70),
		ClipsDescendants = true,
		Parent = parent,
	}, { corner(10) })
	create("Frame", { -- sky
		Size = UDim2.fromScale(1, 0.78),
		BackgroundColor3 = rgb(95, 70, 120),
		BorderSizePixel = 0,
		Parent = preview,
	})
	local house = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.86),
		Size = UDim2.fromScale(0.62, 0.5),
		BackgroundColor3 = style.Wall.Color,
		BorderSizePixel = 0,
		Parent = preview,
	})
	create("Frame", { -- roof
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.38),
		Size = UDim2.fromScale(style.Roof.Type == "Dome" and 0.55 or 0.72, 0.3),
		BackgroundColor3 = style.Roof.Color,
		BorderSizePixel = 0,
		Parent = preview,
	}, style.Roof.Type == "Dome" and { corner(40) } or nil)
	create("Frame", { -- door
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromScale(0.18, 0.62),
		BackgroundColor3 = style.Door.Color,
		BorderSizePixel = 0,
		Parent = house,
	}, { stroke(style.Trim.Color, 2) })
	for _, x in { 0.2, 0.8 } do
		create("Frame", { -- windows
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, 0.45),
			Size = UDim2.fromScale(0.18, 0.32),
			BackgroundColor3 = style.Window.Color,
			BorderSizePixel = 0,
			Parent = house,
		}, { stroke(style.Trim.Color, 2) })
	end
	label({
		Text = style.Emoji,
		TextScaled = true,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -4, 0, 4),
		Size = UDim2.fromOffset(30, 30),
		Parent = preview,
	})
end

for _, style in HouseStyles.List do
	local card = create("TextButton", {
		Name = style.Id,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = style.Order,
		BackgroundColor3 = THEME.Card,
		Parent = grid,
	}, { corner(14) })
	local cardStroke = stroke(THEME.Gold, 0)
	cardStroke.Parent = card
	cardStrokes[style.Id] = cardStroke

	stylePreview(style, card)
	label({
		Text = style.DisplayName,
		Font = Enum.Font.FredokaOne,
		TextSize = 18,
		TextColor3 = THEME.Text,
		Position = UDim2.fromOffset(8, 108),
		Size = UDim2.new(1, -16, 0, 22),
		Parent = card,
	})
	label({
		Text = style.Tagline,
		TextSize = 13,
		TextWrapped = true,
		TextColor3 = THEME.Muted,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(10, 132),
		Size = UDim2.new(1, -20, 0, 58),
		Parent = card,
	})

	card.MouseEnter:Connect(function()
		card.BackgroundColor3 = THEME.CardHover
	end)
	card.MouseLeave:Connect(function()
		card.BackgroundColor3 = THEME.Card
	end)
	card.Activated:Connect(function()
		ChooseStyle:FireServer(style.Id)
		stylePanel.Visible = false
	end)
end

local function openStylePicker(firstVisit: boolean?)
	styleTitle.Text = firstVisit and "Welcome to Potion Town! Pick your shop's vibe" or "Choose your shop's vibe"
	styleSubtitle.Text = firstVisit
			and "Every potion maker gets their own shop. Choose a look below. You can change it any time from the 🎨 button."
		or "Pick a look for your potion shop. You can change it any time from the 🎨 button or your shop sign."
	local current = myStyleId()
	for id, cardStroke in cardStrokes do
		cardStroke.Thickness = (id == current) and 3 or 0
	end
	stylePanel.Visible = true
end
OpenStylePicker.OnClientEvent:Connect(openStylePicker)

--------------------------------------------------------------------------------
-- Visit menu
--------------------------------------------------------------------------------

local visitPanel = makePanel("VisitMenu", "Visit a Shop", Vector2.new(460, 520))
local list = create("ScrollingFrame", {
	Position = UDim2.fromOffset(16, 62),
	Size = UDim2.new(1, -32, 1, -78),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	ScrollBarImageColor3 = THEME.Gold,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = visitPanel,
}, {
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local function refreshVisitList()
	for _, child in list:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local folder = plotsFolder()
	local count = 0
	for _, plot in (folder and folder:GetChildren() or {}) do
		local ownerId = plot:GetAttribute("OwnerUserId")
		if ownerId and ownerId ~= player.UserId then
			count += 1
			local style = HouseStyles.Get(plot:GetAttribute("StyleId"))
			local row = create("Frame", {
				Size = UDim2.new(1, -8, 0, 64),
				BackgroundColor3 = THEME.Card,
				LayoutOrder = plot:GetAttribute("PlotIndex") or 0,
				Parent = list,
			}, { corner(12) })
			label({
				Text = string.format("%s  %s's Potion Shop", style and style.Emoji or "🧪", plot:GetAttribute("OwnerName") or "?"),
				Font = Enum.Font.FredokaOne,
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.fromOffset(12, 8),
				Size = UDim2.new(1, -120, 0, 24),
				Parent = row,
			})
			label({
				Text = style and style.DisplayName or "",
				TextSize = 14,
				TextColor3 = THEME.Muted,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(12, 34),
				Size = UDim2.new(1, -120, 0, 20),
				Parent = row,
			})
			local visit = create("TextButton", {
				Text = "Visit",
				Font = Enum.Font.GothamBold,
				TextSize = 16,
				TextColor3 = THEME.Text,
				BackgroundColor3 = THEME.Button,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(92, 40),
				Parent = row,
			}, { corner(10) })
			visit.Activated:Connect(function()
				RequestTeleport:FireServer(ownerId)
				visitPanel.Visible = false
			end)
		end
	end
	if count == 0 then
		label({
			Text = "No other shops yet. Invite your friends to Potion Town! 🧪",
			TextWrapped = true,
			TextSize = 16,
			TextColor3 = THEME.Muted,
			Size = UDim2.new(1, -8, 0, 80),
			Parent = list,
		})
	end
end

-- Keep the list fresh while it is open
task.spawn(function()
	local folder = workspace:WaitForChild("Town"):WaitForChild("Plots")
	local function watch(plot: Instance)
		plot.AttributeChanged:Connect(function()
			if visitPanel.Visible then
				refreshVisitList()
			end
		end)
	end
	for _, plot in folder:GetChildren() do
		watch(plot)
	end
	folder.ChildAdded:Connect(watch)
end)

--------------------------------------------------------------------------------
-- Side menu
--------------------------------------------------------------------------------

local menu = create("Frame", {
	Name = "SideMenu",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 14, 0.5, 0),
	Size = UDim2.fromOffset(78, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local function menuButton(order: number, emoji: string, text: string, onClick: () -> ())
	local button = create("TextButton", {
		Text = "",
		LayoutOrder = order,
		Size = UDim2.fromOffset(78, 78),
		BackgroundColor3 = THEME.Panel,
		BackgroundTransparency = 0.1,
		AutoButtonColor = true,
		Parent = menu,
	}, { corner(16), stroke(THEME.Gold, 1.5) })
	label({ Text = emoji, TextScaled = true, Position = UDim2.fromOffset(18, 8), Size = UDim2.fromOffset(42, 42), Parent = button })
	label({ Text = text, Font = Enum.Font.GothamBold, TextSize = 14, Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, 0, 0, 18), Parent = button })
	button.Activated:Connect(onClick)
	return button
end

menuButton(1, "🏠", "Home", function()
	RequestTeleport:FireServer("Home")
end)
menuButton(2, "🎨", "Style", function()
	visitPanel.Visible = false
	if stylePanel.Visible then
		stylePanel.Visible = false
	else
		openStylePicker(false)
	end
end)
menuButton(3, "🧭", "Visit", function()
	stylePanel.Visible = false
	visitPanel.Visible = not visitPanel.Visible
	if visitPanel.Visible then
		refreshVisitList()
	end
end)
menuButton(4, "⛲", "Town", function()
	RequestTeleport:FireServer("Town")
end)

--------------------------------------------------------------------------------
-- Owner-only / visitor-only prompts
--------------------------------------------------------------------------------

local function applyAudience(prompt: ProximityPrompt)
	local audience = prompt:GetAttribute("Audience")
	if not audience then
		return
	end
	local isOwner = prompt:GetAttribute("OwnerUserId") == player.UserId
	if audience == "Owner" then
		prompt.Enabled = isOwner
	elseif audience == "Visitor" then
		prompt.Enabled = not isOwner
	end
end

local function trackPrompt(instance: Instance)
	if instance:IsA("ProximityPrompt") and instance:GetAttribute("Audience") then
		applyAudience(instance)
		instance:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
			applyAudience(instance)
		end)
	end
end

for _, descendant in workspace:GetDescendants() do
	trackPrompt(descendant)
end
workspace.DescendantAdded:Connect(trackPrompt)
