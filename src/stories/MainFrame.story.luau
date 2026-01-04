--[[
	MainFrame.story.luau
	Story for the MainFrame component.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local MainFrame = require(StarterPlayer.StarterPlayerScripts.Client.components.MainFrame)

local controls = {
	text = "Hello from React!",
}

local story = {
	react = React,
	reactRoblox = ReactRoblox,
	controls = controls,
	story = function(props)
		return React.createElement(MainFrame, {
			text = props.controls.text,
		})
	end,
}

return story
