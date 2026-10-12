--[[
	Remotes
	Creates the RemoteEvents the client and server talk through.
	The client waits for ReplicatedStorage.Remotes.<Name>.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("Remotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
end

local function event(name: string): RemoteEvent
	local remote = folder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	return remote
end

return {
	ChooseStyle = event("ChooseStyle"), -- client -> server: (styleId)
	RequestTeleport = event("RequestTeleport"), -- client -> server: ("Home" | "Town" | ownerUserId)
	OpenStylePicker = event("OpenStylePicker"), -- server -> client: (isFirstVisit)
	Notify = event("Notify"), -- server -> client: (message)
}
