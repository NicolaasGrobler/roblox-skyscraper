--[[
	App.luau
	Root component for the client UI.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local MainFrame = require(script.Parent.MainFrame)

local function App()
	return React.createElement("ScreenGui", {
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		MainFrame = React.createElement(MainFrame),
	})
end

return App
