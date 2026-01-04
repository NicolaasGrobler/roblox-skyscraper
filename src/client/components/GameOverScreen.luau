--[[
	GameOverScreen.luau
	Shows final score and restart button when game ends with fade-in animation.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local React = require(ReplicatedStorage.Packages.React)

export type GameOverScreenProps = {
	visible: boolean,
	score: number,
	blockCount: number,
	onRestart: () -> (),
}

local function GameOverScreen(props: GameOverScreenProps)
	local frameRef = React.useRef(nil :: Frame?)
	local contentRef = React.useRef(nil :: Frame?)

	-- Animate when visible changes to true
	React.useEffect(function()
		local frame = frameRef.current
		local content = contentRef.current
		if not frame or not content then
			return
		end

		if props.visible then
			-- Reset to invisible
			frame.BackgroundTransparency = 1
			frame.Visible = true

			local uiScale = content:FindFirstChild("Scale") :: UIScale?
			if uiScale then
				uiScale.Scale = 0.8
			end

			for _, child in content:GetDescendants() do
				if child:IsA("TextLabel") or child:IsA("TextButton") then
					child.TextTransparency = 1
				end
			end

			-- Fade in background
			local bgTween = TweenService:Create(
				frame,
				TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ BackgroundTransparency = 0.4 }
			)
			bgTween:Play()

			-- Scale up content
			if uiScale then
				local scaleTween = TweenService:Create(
					uiScale,
					TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Scale = 1 }
				)
				task.delay(0.15, function()
					scaleTween:Play()
				end)
			end

			-- Fade in text
			task.delay(0.2, function()
				for _, child in content:GetDescendants() do
					if child:IsA("TextLabel") then
						local targetTransparency = if child.Name == "BlocksText" then 0.3 else 0
						TweenService:Create(
							child,
							TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ TextTransparency = targetTransparency }
						):Play()
					elseif child:IsA("TextButton") then
						TweenService:Create(
							child,
							TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ TextTransparency = 0 }
						):Play()
					end
				end
			end)
		else
			frame.Visible = false
		end
	end, { props.visible })

	return React.createElement("Frame", {
		ref = frameRef,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Visible = false,
	}, {
		Content = React.createElement("Frame", {
			ref = contentRef,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(300, 200),
			BackgroundTransparency = 1,
		}, {
			Scale = React.createElement("UIScale", {
				Scale = 0.8,
			}),

			Layout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 12),
			}),

			GameOverText = React.createElement("TextLabel", {
				Name = "GameOverText",
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundTransparency = 1,
				Text = "GAME OVER",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextTransparency = 1,
				TextSize = 36,
				FontFace = Font.fromEnum(Enum.Font.GothamBlack),
			}),

			ScoreText = React.createElement("TextLabel", {
				Name = "ScoreText",
				LayoutOrder = 2,
				Size = UDim2.new(1, 0, 0, 50),
				BackgroundTransparency = 1,
				Text = string.format("%d", props.score),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextTransparency = 1,
				TextSize = 48,
				FontFace = Font.fromEnum(Enum.Font.GothamBlack),
			}),

			BlocksText = React.createElement("TextLabel", {
				Name = "BlocksText",
				LayoutOrder = 3,
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Text = string.format("%d blocks stacked", props.blockCount),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextTransparency = 1,
				TextSize = 16,
				FontFace = Font.fromEnum(Enum.Font.GothamBold),
			}),

			RestartButton = React.createElement("TextButton", {
				Name = "RestartButton",
				LayoutOrder = 4,
				Size = UDim2.new(0, 160, 0, 44),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Text = "PLAY AGAIN",
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextTransparency = 1,
				TextSize = 18,
				FontFace = Font.fromEnum(Enum.Font.GothamBlack),
				[React.Event.MouseButton1Click] = props.onRestart,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
		}),
	})
end

return GameOverScreen
