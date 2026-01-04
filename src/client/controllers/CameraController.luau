--[[
	CameraController.luau
	Manages the camera for the stacking game - fixed isometric view that follows tower height.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CameraController = {}

local camera = workspace.CurrentCamera

-- Camera settings (fixed isometric with orthographic-style projection)
local CAMERA_FOV = 15 -- Low FOV for orthographic-like effect
local CAMERA_DISTANCE = 50 -- Increased distance to compensate for low FOV
local CAMERA_HEIGHT_OFFSET = 3 -- How high above current tower top
local CAMERA_ANGLE = 45 -- Degrees from horizontal
local CAMERA_ROTATION = 45 -- Fixed rotation (isometric corner view)

local targetHeight = 5 -- Current tower height to track
local currentCameraY = 15 -- Smoothed camera Y position
local basePosition = Vector3.new(0, 5, 0)
local updateConnection: RBXScriptConnection?

-- Initialize the camera controller
function CameraController.init(arenaBasePosition: Vector3)
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
	currentCameraY = currentCameraY + (targetY - currentCameraY) * math.min(deltaTime * 5, 1)

	CameraController.updateCameraPosition()
end

-- Update the camera position and orientation
function CameraController.updateCameraPosition()
	local angleRad = math.rad(CAMERA_ANGLE)
	local rotationRad = math.rad(CAMERA_ROTATION)

	-- Calculate camera offset from tower center
	local horizontalDistance = CAMERA_DISTANCE * math.cos(angleRad)
	local verticalOffset = CAMERA_DISTANCE * math.sin(angleRad)

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
local fadeFrame: Frame? = nil

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

-- Zoom out to show the full tower (called on game over)
function CameraController.zoomOutToShowTower(towerHeight: number)
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
	local horizontalDistance = 40 -- Distance from tower center

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

		-- Phase 2: Fade back in
		local fadeInTween = TweenService:Create(
			fadeFrame,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1 }
		)

		fadeInTween.Completed:Connect(function()
			-- Phase 3: Pan from bottom to top
			CameraController.panUpTower(bottomCameraPos, topCameraPos, bottomLookAt, topLookAt, towerHeight)
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
	towerHeight: number
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

		if progress >= 1 then
			panConnection:Disconnect()

			-- Start orbiting around the tower at the top
			local horizontalDistance = 40
			CameraController.startOrbit(towerHeight, horizontalDistance)
		end
	end)
end

-- Keep camera orbiting around the tower (used after game over)
local orbitConnection: RBXScriptConnection?

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
