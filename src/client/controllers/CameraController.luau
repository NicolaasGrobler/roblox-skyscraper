--[[
	CameraController.luau
	Manages the camera for the stacking game - fixed isometric view that follows tower height.
]]

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local CameraController = {}

local camera = workspace.CurrentCamera

-- Camera settings (fixed isometric with orthographic-style projection)
local CAMERA_FOV = 28 -- Wider FOV for snappier feel
local CAMERA_DISTANCE = 28 -- Closer camera with wider FOV
local CAMERA_DISTANCE_PORTRAIT = 40 -- Extra distance for portrait mode on mobile
local CAMERA_HEIGHT_OFFSET = 3 -- How high above current tower top
local CAMERA_ANGLE = 45 -- Degrees from horizontal
local CAMERA_ROTATION = 45 -- Fixed rotation (isometric corner view)

-- Atmosphere color gradient based on height (cycles through colors as you go higher)
-- Colors are saturated enough for good contrast with white text on buttons
local ATMOSPHERE_COLORS = {
	{ height = 0, color = Color3.fromRGB(230, 180, 100) },   -- Warm amber (start)
	{ height = 20, color = Color3.fromRGB(220, 120, 150) },  -- Rose pink
	{ height = 40, color = Color3.fromRGB(160, 130, 220) },  -- Lavender
	{ height = 60, color = Color3.fromRGB(100, 160, 220) },  -- Sky blue
	{ height = 80, color = Color3.fromRGB(120, 200, 160) },  -- Mint green
	{ height = 100, color = Color3.fromRGB(220, 160, 100) }, -- Peach/orange
	{ height = 120, color = Color3.fromRGB(180, 100, 220) }, -- Purple
	{ height = 140, color = Color3.fromRGB(100, 180, 220) }, -- Cyan
}

-- Get atmosphere color based on current height
local function getAtmosphereColor(height: number): Color3
	local colors = ATMOSPHERE_COLORS

	-- Find the two colors to interpolate between
	local lowerColor = colors[1]
	local upperColor = colors[#colors]

	for i = 1, #colors - 1 do
		if height >= colors[i].height and height < colors[i + 1].height then
			lowerColor = colors[i]
			upperColor = colors[i + 1]
			break
		elseif height >= colors[#colors].height then
			-- Loop back to beginning for very tall towers
			local loopHeight = height % colors[#colors].height
			return getAtmosphereColor(loopHeight)
		end
	end

	-- Interpolate between the two colors
	local t = (height - lowerColor.height) / (upperColor.height - lowerColor.height)
	t = math.clamp(t, 0, 1)
	return lowerColor.color:Lerp(upperColor.color, t)
end

-- Update atmosphere based on current height
local function updateAtmosphere(height: number, lerpSpeed: number?)
	local speed = lerpSpeed or 0.05
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		local targetColor = getAtmosphereColor(height)
		-- Smoothly transition (atmosphere color updates each frame)
		atmosphere.Color = atmosphere.Color:Lerp(targetColor, speed)
		atmosphere.Decay = atmosphere.Decay:Lerp(targetColor:Lerp(Color3.new(0.5, 0.5, 0.5), 0.3), speed)
	end
end

-- Instantly reset atmosphere to starting color (called during restart fade)
local function resetAtmosphere()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		local startColor = ATMOSPHERE_COLORS[1].color
		atmosphere.Color = startColor
		atmosphere.Decay = startColor:Lerp(Color3.new(0.5, 0.5, 0.5), 0.3)
	end
end

-- Check if viewport is in portrait mode
local function isPortraitMode(): boolean
	local viewport = camera.ViewportSize
	return viewport.Y > viewport.X
end

-- Get camera distance based on orientation
local function getCameraDistance(): number
	return if isPortraitMode() then CAMERA_DISTANCE_PORTRAIT else CAMERA_DISTANCE
end

local targetHeight = 5 -- Current tower height to track
local currentCameraY = 15 -- Smoothed camera Y position
local basePosition = Vector3.new(0, 5, 0)
local updateConnection: RBXScriptConnection?
local orbitConnection: RBXScriptConnection?
local fadeFrame: Frame? = nil

-- Initialize the camera controller
function CameraController.init(arenaBasePosition: Vector3)
	-- Clean up any existing connections first (important for restart)
	if updateConnection then
		updateConnection:Disconnect()
		updateConnection = nil
	end
	if orbitConnection then
		orbitConnection:Disconnect()
		orbitConnection = nil
	end
	-- Clean up fade overlay
	if fadeFrame and fadeFrame.Parent then
		fadeFrame.Parent:Destroy()
		fadeFrame = nil
	end

	basePosition = arenaBasePosition

	-- Set camera to Scriptable so we have full control
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = CAMERA_FOV

	-- Calculate initial camera position
	targetHeight = basePosition.Y
	currentCameraY = targetHeight + CAMERA_HEIGHT_OFFSET

	-- Start update loop
	updateConnection = RunService.RenderStepped:Connect(function(deltaTime)
		CameraController.update(deltaTime)
	end)

	-- Initial position
	CameraController.updateCameraPosition()

	print("[CameraController] Initialized (fixed isometric)")
end

-- Update camera each frame
function CameraController.update(deltaTime: number)
	-- Smoothly interpolate camera height to follow tower
	local targetY = targetHeight + CAMERA_HEIGHT_OFFSET
	currentCameraY = currentCameraY + (targetY - currentCameraY) * math.min(deltaTime * 15, 1)

	CameraController.updateCameraPosition()

	-- Update atmosphere color based on tower height
	updateAtmosphere(targetHeight)
end

-- Update the camera position and orientation
function CameraController.updateCameraPosition()
	local angleRad = math.rad(CAMERA_ANGLE)
	local rotationRad = math.rad(CAMERA_ROTATION)
	local cameraDistance = getCameraDistance()

	-- Calculate camera offset from tower center
	local horizontalDistance = cameraDistance * math.cos(angleRad)
	local verticalOffset = cameraDistance * math.sin(angleRad)

	local offsetX = horizontalDistance * math.cos(rotationRad)
	local offsetZ = horizontalDistance * math.sin(rotationRad)

	-- Camera position
	local cameraPosition = Vector3.new(
		basePosition.X + offsetX,
		currentCameraY + verticalOffset,
		basePosition.Z + offsetZ
	)

	-- Look at point (center of tower at current height)
	local lookAtPoint = Vector3.new(
		basePosition.X,
		currentCameraY,
		basePosition.Z
	)

	camera.CFrame = CFrame.lookAt(cameraPosition, lookAtPoint)
end

-- Update the target height (call this when tower grows)
function CameraController.setTargetHeight(height: number)
	targetHeight = height
end

-- Create fade overlay for transitions
local function createFadeOverlay(): Frame
	local Players = game:GetService("Players")
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FadeOverlay"
	screenGui.DisplayOrder = 999
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "Fade"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	return frame
end

-- Transition with fade to black, callback, then fade back in
function CameraController.transitionWithFade(onDuringBlack: () -> (), onComplete: (() -> ())?)
	local TweenService = game:GetService("TweenService")

	-- Create a local fade overlay (separate from module fadeFrame)
	local transitionFade = createFadeOverlay()

	-- Fade to black
	local fadeOutTween = TweenService:Create(
		transitionFade,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0 }
	)

	fadeOutTween.Completed:Connect(function()
		-- Reset atmosphere instantly while screen is black
		resetAtmosphere()

		-- Do the work while screen is black
		onDuringBlack()

		-- Small delay to let things settle
		task.delay(0.1, function()
			-- Fade back in
			if not transitionFade or not transitionFade.Parent then
				if onComplete then
					onComplete()
				end
				return
			end

			local fadeInTween = TweenService:Create(
				transitionFade,
				TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ BackgroundTransparency = 1 }
			)

			fadeInTween.Completed:Connect(function()
				-- Clean up fade overlay
				if transitionFade and transitionFade.Parent then
					transitionFade.Parent:Destroy()
				end

				if onComplete then
					onComplete()
				end
			end)

			fadeInTween:Play()
		end)
	end)

	fadeOutTween:Play()
end

-- Zoom out to show the full tower (called on game over)
-- onComplete callback is called when the animation finishes
function CameraController.zoomOutToShowTower(towerHeight: number, onComplete: (() -> ())?)
	local TweenService = game:GetService("TweenService")

	-- Stop the normal update loop
	if updateConnection then
		updateConnection:Disconnect()
		updateConnection = nil
	end

	-- Create fade overlay
	fadeFrame = createFadeOverlay()

	-- Calculate camera positions for the pan
	local towerTopHeight = basePosition.Y + towerHeight
	local horizontalDistance = if isPortraitMode() then CAMERA_DISTANCE_PORTRAIT else CAMERA_DISTANCE -- Distance from tower center

	local rotationRad = math.rad(CAMERA_ROTATION)
	local offsetX = horizontalDistance * math.cos(rotationRad)
	local offsetZ = horizontalDistance * math.sin(rotationRad)

	-- Bottom position (looking at base)
	local bottomCameraPos = Vector3.new(
		basePosition.X + offsetX,
		basePosition.Y,
		basePosition.Z + offsetZ
	)
	local bottomLookAt = Vector3.new(basePosition.X, basePosition.Y, basePosition.Z)

	-- Top position (looking at top of tower)
	local topCameraPos = Vector3.new(
		basePosition.X + offsetX,
		towerTopHeight + 5,
		basePosition.Z + offsetZ
	)
	local topLookAt = Vector3.new(basePosition.X, towerTopHeight, basePosition.Z)

	-- Phase 1: Fade to black
	local fadeOutTween = TweenService:Create(
		fadeFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0 }
	)

	fadeOutTween.Completed:Connect(function()
		-- Reposition camera at bottom while screen is black
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = CAMERA_FOV
		camera.CFrame = CFrame.lookAt(bottomCameraPos, bottomLookAt)

		-- Reset atmosphere to bottom color while screen is black
		resetAtmosphere()

		-- Phase 2: Fade back in
		local fadeInTween = TweenService:Create(
			fadeFrame,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1 }
		)

		fadeInTween.Completed:Connect(function()
			-- Phase 3: Pan from bottom to top
			CameraController.panUpTower(bottomCameraPos, topCameraPos, bottomLookAt, topLookAt, towerHeight, onComplete)
		end)

		fadeInTween:Play()
	end)

	fadeOutTween:Play()
end

-- Pan the camera from bottom to top of tower
function CameraController.panUpTower(
	startPos: Vector3,
	endPos: Vector3,
	startLookAt: Vector3,
	endLookAt: Vector3,
	towerHeight: number,
	onComplete: (() -> ())?
)
	-- Calculate pan time based on tower height (taller = longer pan)
	local panTime = math.clamp(towerHeight / 10, 2, 5)
	local elapsed = 0

	local panConnection
	panConnection = game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
		elapsed = elapsed + deltaTime
		local progress = math.min(elapsed / panTime, 1)

		-- Smooth easing
		local easedProgress = 1 - math.pow(1 - progress, 3) -- Ease out cubic

		-- Keep camera in scriptable mode
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = CAMERA_FOV

		-- Interpolate position and look-at
		local currentPos = startPos:Lerp(endPos, easedProgress)
		local currentLookAt = startLookAt:Lerp(endLookAt, easedProgress)
		camera.CFrame = CFrame.lookAt(currentPos, currentLookAt)

		-- Update atmosphere color as we pan up (faster lerp for more visible change)
		local currentHeight = currentLookAt.Y - basePosition.Y
		updateAtmosphere(currentHeight, 0.15)

		if progress >= 1 then
			panConnection:Disconnect()

			-- Call completion callback
			if onComplete then
				onComplete()
			end

			-- Start orbiting around the tower at the top
			local orbitDistance = if isPortraitMode() then CAMERA_DISTANCE_PORTRAIT else CAMERA_DISTANCE
			CameraController.startOrbit(towerHeight, orbitDistance)
		end
	end)
end

-- Keep camera orbiting around the tower (used after game over)
function CameraController.startOrbit(towerHeight: number, distance: number)
	-- Clean up any existing orbit
	if orbitConnection then
		orbitConnection:Disconnect()
	end

	local towerTopHeight = basePosition.Y + towerHeight
	local orbitAngle = math.rad(CAMERA_ROTATION) -- Start from current rotation
	local orbitSpeed = 0.3 -- Radians per second (slow rotation)
	local cameraY = towerTopHeight + 5 -- Orbit at top of tower

	-- Continuously orbit around the tower at the top
	orbitConnection = game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = CAMERA_FOV

		-- Update orbit angle
		orbitAngle = orbitAngle + orbitSpeed * deltaTime

		-- Calculate camera position on orbit
		local offsetX = distance * math.cos(orbitAngle)
		local offsetZ = distance * math.sin(orbitAngle)

		local cameraPosition = Vector3.new(
			basePosition.X + offsetX,
			cameraY,
			basePosition.Z + offsetZ
		)

		-- Look at top of tower
		local lookAtPoint = Vector3.new(
			basePosition.X,
			towerTopHeight,
			basePosition.Z
		)

		camera.CFrame = CFrame.lookAt(cameraPosition, lookAtPoint)
	end)
end

-- Clean up
function CameraController.cleanup()
	if updateConnection then
		updateConnection:Disconnect()
		updateConnection = nil
	end
	if orbitConnection then
		orbitConnection:Disconnect()
		orbitConnection = nil
	end
	-- Clean up fade overlay
	if fadeFrame and fadeFrame.Parent then
		fadeFrame.Parent:Destroy()
		fadeFrame = nil
	end
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70 -- Reset to default FOV
end

return CameraController
