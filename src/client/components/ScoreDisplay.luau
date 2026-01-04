--[[
	ScoreDisplay.luau
	Clean, minimal score display - centered at top of screen.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local React = require(ReplicatedStorage.Packages.React)

export type ScoreDisplayProps = {
	score: number,
	blockCount: number,
	isEliminated: boolean?,
}

local function ScoreDisplay(props: ScoreDisplayProps)
	local frameRef = React.useRef(nil :: Frame?)

	-- Fade out when eliminated
	React.useEffect(function()
		local frame = frameRef.current
		if not frame then
			return
		end

		if props.isEliminated then
			-- Fade out all text
			for _, child in frame:GetDescendants() do
				if child:IsA("TextLabel") then
					TweenService:Create(
						child,
						TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = 1 }
					):Play()
				end
			end
		end
	end, { props.isEliminated })

	return React.createElement("Frame", {
		ref = frameRef,
		Position = UDim2.new(0.5, 0, 0, 24),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0, 200, 0, 60),
		BackgroundTransparency = 1,
	}, {
		-- Score value
		ScoreLabel = React.createElement("TextLabel", {
			Position = UDim2.fromScale(0.5, 0.35),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundTransparency = 1,
			Text = string.format("%d", props.score),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 42,
			FontFace = Font.fromEnum(Enum.Font.GothamBlack),
		}),

		-- Blocks count
		BlocksLabel = React.createElement("TextLabel", {
			Position = UDim2.fromScale(0.5, 0.8),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = string.format("%d blocks", props.blockCount),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextTransparency = 0.3,
			TextSize = 14,
			FontFace = Font.fromEnum(Enum.Font.GothamBold),
		}),
	})
end

return ScoreDisplay
