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

	-- Add atmosphere with dense fog at the bottom
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.4
	atmosphere.Offset = 0 -- Fog starts at the very bottom
	atmosphere.Color = Color3.fromRGB(220, 225, 240) -- Light misty fog
	atmosphere.Decay = Color3.fromRGB(180, 190, 210) -- Subtle color shift in distance
	atmosphere.Glare = 0
	atmosphere.Haze = 2.5
	atmosphere.Parent = Lighting

	-- Add subtle bloom for a polished look
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 24
	bloom.Threshold = 1.5
	bloom.Parent = Lighting

	-- Add a clean gradient sky with stars
	local sky = Instance.new("Sky")
	sky.SkyboxBk = "rbxassetid://1012890" -- Default Roblox sky (clean)
	sky.SkyboxDn = "rbxassetid://1012891"
	sky.SkyboxFt = "rbxassetid://1012887"
	sky.SkyboxLf = "rbxassetid://1012889"
	sky.SkyboxRt = "rbxassetid://1012888"
	sky.SkyboxUp = "rbxassetid://1012892"
	sky.StarCount = 3000 -- Visible stars for sparkle effect
	sky.SunAngularSize = 15
	sky.MoonAngularSize = 10
	sky.CelestialBodiesShown = false -- Hide sun/moon for cleaner look
	sky.Parent = Lighting

	print("[Server] Environment setup complete")
end

-- Create background particle effects (floating sparkles/stars)
local function createBackgroundEffects()
	local effectsFolder = Instance.new("Folder")
	effectsFolder.Name = "BackgroundEffects"
	effectsFolder.Parent = workspace

	-- Helper to create a sparkle emitter
	local function createSparkleEmitter(parent, rate, size)
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "Sparkles"
		sparkles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 240, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		})
		sparkles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.2, size),
			NumberSequenceKeypoint.new(0.8, size),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparkles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0.3),
			NumberSequenceKeypoint.new(0.8, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		})
		sparkles.LightEmission = 1
		sparkles.LightInfluence = 0
		sparkles.Brightness = 2
		sparkles.Lifetime = NumberRange.new(6, 12)
		sparkles.Speed = NumberRange.new(0.3, 1)
		sparkles.SpreadAngle = Vector2.new(360, 360)
		sparkles.Rate = rate
		sparkles.Parent = parent
		-- Pre-emit particles so they're visible immediately
		sparkles:Emit(math.floor(rate * 5))
		return sparkles
	end

	-- Sky emitters (visible in upper part of screen during gameplay)
	-- Camera looks from +X +Z at 45° down, so sky behind tower is -X -Z direction
	local skyPositions = {
		Vector3.new(-60, 60, -60),
		Vector3.new(-80, 80, -40),
		Vector3.new(-40, 70, -80),
		Vector3.new(0, 90, -70),
		Vector3.new(-70, 75, 0),
	}

	for i, pos in skyPositions do
		local emitterPart = Instance.new("Part")
		emitterPart.Name = "SkyEmitter" .. i
		emitterPart.Size = Vector3.new(50, 50, 50)
		emitterPart.Position = pos
		emitterPart.Anchored = true
		emitterPart.CanCollide = false
		emitterPart.Transparency = 1
		emitterPart.Parent = effectsFolder
		createSparkleEmitter(emitterPart, 3, 0.4)
	end

	-- Fog/ground emitters (visible in lower part of screen, in the fog)
	local fogPositions = {
		Vector3.new(-50, -30, -50),
		Vector3.new(-70, -40, -30),
		Vector3.new(-30, -35, -70),
		Vector3.new(-60, -25, 0),
		Vector3.new(0, -30, -60),
	}

	for i, pos in fogPositions do
		local emitterPart = Instance.new("Part")
		emitterPart.Name = "FogEmitter" .. i
		emitterPart.Size = Vector3.new(60, 30, 60)
		emitterPart.Position = pos
		emitterPart.Anchored = true
		emitterPart.CanCollide = false
		emitterPart.Transparency = 1
		emitterPart.Parent = effectsFolder
		createSparkleEmitter(emitterPart, 2, 0.5)
	end

	-- Ring emitters (for game over orbiting camera)
	local radius = 70
	local numRingEmitters = 6

	for i = 1, numRingEmitters do
		local angle = (i / numRingEmitters) * math.pi * 2
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius

		local emitterPart = Instance.new("Part")
		emitterPart.Name = "RingEmitter" .. i
		emitterPart.Size = Vector3.new(40, 80, 40)
		emitterPart.Position = Vector3.new(x, 30, z)
		emitterPart.Anchored = true
		emitterPart.CanCollide = false
		emitterPart.Transparency = 1
		emitterPart.Parent = effectsFolder
		createSparkleEmitter(emitterPart, 2, 0.35)
	end

	print("[Server] Background effects created")
end

setupEnvironment()
createBackgroundEffects()

-- Create RemoteEvents folder
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

-- Create required RemoteEvents
local remoteNames = { "RequestDrop", "BlockDropped", "BlockSpawned", "GameStateUpdate", "RestartGame" }
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
