--[[
	PerfectPopup.luau
	Clean animated popup for perfect stacks with smooth tweening.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local React = require(ReplicatedStorage.Packages.React)

export type PerfectPopupProps = {
	visible: boolean,
	comboCount: number,
	pointsEarned: number,
}

local function PerfectPopup(props: PerfectPopupProps)
	local frameRef = React.useRef(nil :: Frame?)

	-- Animate when visible changes
	React.useEffect(function()
		local frame = frameRef.current
		if not frame then
			return
		end

		local uiScale = frame:FindFirstChild("Scale") :: UIScale?
		if not uiScale then
			return
		end

		if props.visible then
			-- Reset
			uiScale.Scale = 0
			frame.Visible = true

			-- Smooth scale up
			local scaleUp = TweenService:Create(
				uiScale,
				TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			)
			scaleUp:Play()

			-- Fade out after delay
			task.delay(0.6, function()
				if frame and frame.Parent then
					local fadeOut = TweenService:Create(
						uiScale,
						TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{ Scale = 0 }
					)
					fadeOut:Play()
					fadeOut.Completed:Once(function()
						if frame then
							frame.Visible = false
						end
					end)
				end
			end)
		end
	end, { props.visible, props.comboCount })

	return React.createElement("Frame", {
		ref = frameRef,
		Position = UDim2.fromScale(0.5, 0.28),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(200, 50),
		BackgroundTransparency = 1,
		Visible = false,
	}, {
		Scale = React.createElement("UIScale", {
			Scale = 0,
		}),

		PerfectText = React.createElement("TextLabel", {
			Position = UDim2.fromScale(0.5, 0.35),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(1, 0.6),
			BackgroundTransparency = 1,
			Text = "PERFECT",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 32,
			FontFace = Font.fromEnum(Enum.Font.GothamBlack),
		}),

		PointsText = React.createElement("TextLabel", {
			Position = UDim2.fromScale(0.5, 0.85),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(1, 0.35),
			BackgroundTransparency = 1,
			Text = string.format("+%d", props.pointsEarned),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			FontFace = Font.fromEnum(Enum.Font.GothamBlack),
		}),
	})
end

return PerfectPopup
