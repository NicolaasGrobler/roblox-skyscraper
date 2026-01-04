--[[
	Server Entry Point
	Initializes game systems and handles player connections.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local BlockService = require(script.services.BlockService)

-- Setup environment (atmosphere, lighting, sky)
local function setupEnvironment()
	-- Clear existing atmosphere/sky if any
	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("Sky") or child:IsA("BloomEffect") then
			child:Destroy()
		end
	end

	-- Set lighting properties for a clean, bright look
	Lighting.Brightness = 2
	Lighting.ClockTime = 14 -- Afternoon sun
	Lighting.GeographicLatitude = 0
	Lighting.Ambient = Color3.fromRGB(150, 150, 160)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160)
	Lighting.ColorShift_Bottom = Color3.fromRGB(200, 200, 220)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1

	-- Add atmosphere with fog at the bottom
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.25 -- Fog starts lower
	atmosphere.Color = Color3.fromRGB(200, 210, 230) -- Light blue-ish fog
	atmosphere.Decay = Color3.fromRGB(150, 170, 200) -- Subtle color shift in distance
	atmosphere.Glare = 0
	atmosphere.Haze = 1.5
	atmosphere.Parent = Lighting

	-- Add subtle bloom for a polished look
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 24
	bloom.Threshold = 1.5
	bloom.Parent = Lighting

	-- Add a clean gradient sky
	local sky = Instance.new("Sky")
	sky.SkyboxBk = "rbxassetid://1012890" -- Default Roblox sky (clean)
	sky.SkyboxDn = "rbxassetid://1012891"
	sky.SkyboxFt = "rbxassetid://1012887"
	sky.SkyboxLf = "rbxassetid://1012889"
	sky.SkyboxRt = "rbxassetid://1012888"
	sky.SkyboxUp = "rbxassetid://1012892"
	sky.StarCount = 0 -- No stars during day
	sky.SunAngularSize = 15
	sky.MoonAngularSize = 10
	sky.Parent = Lighting

	print("[Server] Environment setup complete")
end

setupEnvironment()

-- Create RemoteEvents folder
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

-- Create required RemoteEvents
local remoteNames = { "RequestDrop", "BlockDropped", "BlockSpawned", "GameStateUpdate" }
for _, name in remoteNames do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
end

-- Initialize services
BlockService.init(remotesFolder)

-- Handle player connections
Players.PlayerAdded:Connect(function(player)
	-- For MVP, start game immediately at a fixed position
	-- In full game, this would be handled by MatchManager
	local basePosition = Vector3.new(0, 5, 0)
	BlockService.startGameForPlayer(player, basePosition)
end)

Players.PlayerRemoving:Connect(function(player)
	BlockService.cleanup(player)
end)

-- Handle players already in the game (for Studio testing)
for _, player in Players:GetPlayers() do
	task.spawn(function()
		local basePosition = Vector3.new(0, 5, 0)
		BlockService.startGameForPlayer(player, basePosition)
	end)
end

print("Stack Royale server initialized!")
