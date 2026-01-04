--[[
	InputHandler.luau
	Unified input handling for click, tap, and gamepad button.
]]

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local InputHandler = {}

local ACTION_NAME = "DropBlock"
local dropCallback: (() -> ())?
local inputConnection: RBXScriptConnection?

-- Bind the drop action to all input types
function InputHandler.bindDropAction(callback: () -> ())
	dropCallback = callback

	print("[InputHandler] Binding drop action...")

	-- Use UserInputService for keyboard/mouse/touch (more reliable)
	inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- Skip if input was processed by UI (like chat)
		if gameProcessed then
			return
		end

		local validInputs = {
			[Enum.UserInputType.MouseButton1] = true,
			[Enum.UserInputType.Touch] = true,
			[Enum.KeyCode.Space] = true,
			[Enum.KeyCode.E] = true, -- Alternative key
		}

		local inputKey = input.KeyCode
		if inputKey == Enum.KeyCode.Unknown then
			inputKey = input.UserInputType
		end

		if validInputs[inputKey] then
			print("[InputHandler] Input detected:", tostring(inputKey))
			if dropCallback then
				dropCallback()
			end
		end
	end)

	-- Also bind gamepad via ContextActionService (Xbox controller)
	ContextActionService:BindActionAtPriority(
		ACTION_NAME,
		function(_actionName, inputState, _inputObject)
			if inputState == Enum.UserInputState.Begin then
				print("[InputHandler] Gamepad input detected")
				if dropCallback then
					dropCallback()
				end
			end
			return Enum.ContextActionResult.Sink
		end,
		false, -- No touch button (we handle touch via UserInputService)
		1000, -- High priority (higher number = more priority)
		Enum.KeyCode.ButtonA, -- Xbox A / PlayStation X
		Enum.KeyCode.ButtonX -- Xbox X
	)

	print("[InputHandler] Drop action bound! Press Space, Click, or Tap to drop.")
end

-- Unbind the drop action
function InputHandler.unbindDropAction()
	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end
	ContextActionService:UnbindAction(ACTION_NAME)
	dropCallback = nil
	print("[InputHandler] Drop action unbound")
end

return InputHandler
