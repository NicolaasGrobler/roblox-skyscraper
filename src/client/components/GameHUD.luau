--[[
	GameHUD.luau
	Main HUD component displaying score, combo, and block count.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local ScoreDisplay = require(script.Parent.ScoreDisplay)
local ComboDisplay = require(script.Parent.ComboDisplay)
local GameOverScreen = require(script.Parent.GameOverScreen)
local GameState = require(script.Parent.Parent.state.GameState)

export type GameHUDProps = {
	score: number,
	comboCount: number,
	blockCount: number,
	showPerfect: boolean,
	pointsEarned: number,
	isGameOver: boolean,
	isEliminated: boolean,
}

local function GameHUD(props: GameHUDProps)
	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		-- Score display (top-center) - hidden when game over
		ScoreDisplay = not props.isGameOver and React.createElement(ScoreDisplay, {
			score = props.score,
			blockCount = props.blockCount,
			isEliminated = props.isEliminated,
		}),

		-- Combo display (below score) - hidden when game over
		ComboDisplay = not props.isGameOver and React.createElement(ComboDisplay, {
			comboCount = props.comboCount,
			isEliminated = props.isEliminated,
		}),

		-- Game over screen
		GameOverScreen = React.createElement(GameOverScreen, {
			visible = props.isGameOver,
			score = props.score,
			blockCount = props.blockCount,
			onRestart = function()
				GameState.requestRestart()
			end,
		}),
	})
end

return GameHUD
