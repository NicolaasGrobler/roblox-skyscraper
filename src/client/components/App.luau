--[[
	App.luau
	Root component for the client UI.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local function App()
	-- Empty ScreenGui for now - will add game HUD later
	return React.createElement("ScreenGui", {
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
end

return App
