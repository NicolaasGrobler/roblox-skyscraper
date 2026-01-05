--[[
	ComboDisplay.luau
	Clean combo display - appears below score when active.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local React = require(ReplicatedStorage.Packages.React)

export type ComboDisplayProps = {
	comboCount: number,
	isEliminated: boolean?,
}

local function ComboDisplay(props: ComboDisplayProps)
	local labelRef = React.useRef(nil :: TextLabel?)

	-- Fade out when eliminated
	React.useEffect(function()
		local label = labelRef.current
		if not label then
			return
		end

		if props.isEliminated then
			TweenService:Create(
				label,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ TextTransparency = 1 }
			):Play()
		end
	end, { props.isEliminated })

	-- Only show when combo is active
	if props.comboCount <= 0 then
		return nil
	end

	return React.createElement("TextLabel", {
		ref = labelRef,
		Position = UDim2.fromScale(0.5, 0.19),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromScale(0.3, 0.04),
		BackgroundTransparency = 1,
		Text = string.format("x%d combo", props.comboCount),
		TextColor3 = Color3.fromRGB(255, 220, 100),
		TextScaled = true,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansExtraBold),
	}, {
		TextConstraint = React.createElement("UITextSizeConstraint", {
			MaxTextSize = 32,
			MinTextSize = 12,
		}),
	})
end

return ComboDisplay
