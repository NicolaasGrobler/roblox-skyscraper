--[[
	Storybook Configuration
	UI Labs will automatically discover this file and load stories from storyRoots.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
	name = "Components",
	storyRoots = {
		ReplicatedStorage.Stories,
	},
}
