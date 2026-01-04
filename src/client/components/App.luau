--[[
	App.luau
	Root component for the client UI.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

local function App()
	return React.createElement("ScreenGui", {
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		MainFrame = React.createElement("Frame", {
			Size = UDim2.fromScale(0.3, 0.2),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			BorderSizePixel = 0,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			Label = React.createElement("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				Text = "Hello from React!",
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 24,
				Font = Enum.Font.GothamBold,
				BackgroundTransparency = 1,
			}),
		}),
	})
end

return App
