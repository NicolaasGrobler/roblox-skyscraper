--[[
	Client Entry Point
	Initializes the React UI for the local player.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local App = require(script.components.App)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- React takes full ownership of the container, so use a Folder, not PlayerGui directly
local container = Instance.new("Folder")
container.Name = "ReactRoot"
container.Parent = playerGui

-- Mount the app
local root = ReactRoblox.createRoot(container)
root:render(React.createElement(App))
