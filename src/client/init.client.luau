--[[
	Client Entry Point
	Initializes the React UI and game controllers.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local App = require(script.components.App)
local BlockController = require(script.controllers.BlockController)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hide default Roblox UI elements
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

-- Function to hide a character and prevent it from falling
local function hideCharacter(character: Model)
	if not character then
		return
	end

	-- Hide all parts of the character
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CanCollide = false
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant.Transparency = 1
		elseif descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
			descendant.Enabled = false
		end
	end

	-- Anchor the root part so character doesn't fall
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.Anchored = true
	end

	-- Disable humanoid display
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

-- Hide character when it spawns
player.CharacterAdded:Connect(hideCharacter)

-- Hide current character if already spawned
if player.Character then
	hideCharacter(player.Character)
end

print("[Client] Waiting for Remotes folder...")

-- Wait for remotes to be created by server
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

print("[Client] Remotes folder found, initializing BlockController...")

-- Initialize game controller with arena base position
local arenaBasePosition = Vector3.new(0, 5, 0)
BlockController.init(remotesFolder, arenaBasePosition)

-- React takes full ownership of the container, so use a Folder, not PlayerGui directly
local container = Instance.new("Folder")
container.Name = "ReactRoot"
container.Parent = playerGui

-- Mount the app
local root = ReactRoblox.createRoot(container)
root:render(React.createElement(App))

print("[Client] Initialization complete!")
