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

	-- Track if we're in portrait mode for responsive button sizing
	local isPortrait, setIsPortrait = React.useState(false)

	React.useEffect(function()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		local function updateOrientation()
			local viewport = camera.ViewportSize
			setIsPortrait(viewport.Y > viewport.X)
		end

		updateOrientation()
		local connection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateOrientation)
		return function()
			connection:Disconnect()
		end
	end, {})

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
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Visible = false,
	}, {
		Content = React.createElement("Frame", {
			ref = contentRef,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.5, 0.4),
			BackgroundTransparency = 1,
		}, {
			Scale = React.createElement("UIScale", {
				Scale = 0.8,
			}),

			Layout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0.02, 0),
			}),

			GameOverText = React.createElement("TextLabel", {
				Name = "GameOverText",
				LayoutOrder = 1,
				Size = UDim2.fromScale(1, 0.18),
				BackgroundTransparency = 1,
				Text = "GAME OVER",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextTransparency = 1,
				TextScaled = true,
				FontFace = Font.fromEnum(Enum.Font.BuilderSansExtraBold),
			}, {
				TextConstraint = React.createElement("UITextSizeConstraint", {
					MaxTextSize = 56,
					MinTextSize = 20,
				}),
			}),

			ScoreText = React.createElement("TextLabel", {
				Name = "ScoreText",
				LayoutOrder = 2,
				Size = UDim2.fromScale(1, 0.25),
				BackgroundTransparency = 1,
				Text = string.format("%d", props.score),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextTransparency = 1,
				TextScaled = true,
				FontFace = Font.fromEnum(Enum.Font.BuilderSansExtraBold),
			}, {
				TextConstraint = React.createElement("UITextSizeConstraint", {
					MaxTextSize = 72,
					MinTextSize = 28,
				}),
			}),

			BlocksText = React.createElement("TextLabel", {
				Name = "BlocksText",
				LayoutOrder = 3,
				Size = UDim2.fromScale(1, 0.1),
				BackgroundTransparency = 1,
				Text = string.format("%d blocks stacked", props.blockCount),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextTransparency = 1,
				TextScaled = true,
				FontFace = Font.fromEnum(Enum.Font.BuilderSansBold),
			}, {
				TextConstraint = React.createElement("UITextSizeConstraint", {
					MaxTextSize = 24,
					MinTextSize = 12,
				}),
			}),

			-- Spacer for extra spacing before button
			Spacer = React.createElement("Frame", {
				LayoutOrder = 4,
				Size = UDim2.fromScale(1, 0.06),
				BackgroundTransparency = 1,
			}),

			RestartButton = React.createElement("TextButton", {
				Name = "RestartButton",
				LayoutOrder = 5,
				Size = UDim2.fromScale(if isPortrait then 0.9 else 0.55, 0.18),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Text = "PLAY AGAIN",
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextTransparency = 1,
				TextScaled = true,
				FontFace = Font.fromEnum(Enum.Font.BuilderSansExtraBold),
				[React.Event.MouseButton1Click] = props.onRestart,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0.2, 0),
				}),
				TextConstraint = React.createElement("UITextSizeConstraint", {
					MaxTextSize = 28,
					MinTextSize = 12,
				}),
			}),
		}),
	})
end

return GameOverScreen
