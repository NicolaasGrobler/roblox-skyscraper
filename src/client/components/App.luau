--[[
	App.luau
	Root component for the client UI.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local GameHUD = require(script.Parent.GameHUD)
local GameState = require(script.Parent.Parent.state.GameState)

local function App()
	-- Subscribe to game state changes
	local state, setState = React.useState(GameState.getState())

	React.useEffect(function()
		local unsubscribe = GameState.subscribe(function()
			setState(GameState.getState())
		end)

		return unsubscribe
	end, {})

	return React.createElement("ScreenGui", {
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
	}, {
		HUD = React.createElement(GameHUD, {
			score = state.score,
			comboCount = state.comboCount,
			blockCount = state.blockCount,
			showPerfect = state.showPerfect,
			pointsEarned = state.pointsEarned,
			isGameOver = state.isGameOver,
			isEliminated = state.isEliminated,
		}),
	})
end

return App
