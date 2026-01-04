--[[
	BlockController.luau
	Client-side block visualization and server communication.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Constants = require(ReplicatedStorage.Shared.Constants)
local InputHandler = require(script.Parent.Parent.input.InputHandler)
local CameraController = require(script.Parent.CameraController)
local SoundController = require(script.Parent.Parent.audio.SoundController)

local BlockController = {}

local remotes: {
	RequestDrop: RemoteEvent?,
	BlockDropped: RemoteEvent?,
	BlockSpawned: RemoteEvent?,
} = {}

local currentBlockData: Types.BlockData? = nil
local isDropping = false
local towerHeight = 0
local blockCount = 0
local comboCount = 0
local basePosition = Vector3.new(0, 5, 0)

-- Initialize the controller
function BlockController.init(remotesFolder: Folder, arenaBasePosition: Vector3?)
	print("[BlockController] Initializing...")

	if arenaBasePosition then
		basePosition = arenaBasePosition
	end

	remotes.RequestDrop = remotesFolder:WaitForChild("RequestDrop") :: RemoteEvent
	remotes.BlockDropped = remotesFolder:WaitForChild("BlockDropped") :: RemoteEvent
	remotes.BlockSpawned = remotesFolder:WaitForChild("BlockSpawned") :: RemoteEvent

	print("[BlockController] RemoteEvents connected")

	-- Initialize camera
	CameraController.init(basePosition)

	-- Initialize audio and start music
	SoundController.init()
	SoundController.fadeInMusic(2)

	-- Listen for server events
	remotes.BlockSpawned.OnClientEvent:Connect(function(blockData: Types.BlockData)
		print("[BlockController] Block spawned:", blockData.id, "axis:", blockData.axis)
		currentBlockData = blockData
		isDropping = false
	end)

	remotes.BlockDropped.OnClientEvent:Connect(function(result: Types.DropResult)
		print("[BlockController] Block dropped, result:", result.success, "perfect:", result.isPerfect)
		BlockController.handleDropResult(result)
	end)

	-- Bind input
	InputHandler.bindDropAction(function()
		BlockController.requestDrop()
	end)

	print("[BlockController] Initialized successfully!")
end

-- Request to drop the current block
function BlockController.requestDrop()
	print("[BlockController] Drop requested, isDropping:", isDropping, "hasBlock:", currentBlockData ~= nil)

	if isDropping then
		print("[BlockController] Already dropping, ignoring")
		return
	end

	if not currentBlockData then
		print("[BlockController] No current block, ignoring")
		return
	end

	isDropping = true

	if remotes.RequestDrop then
		print("[BlockController] Firing RequestDrop to server")
		remotes.RequestDrop:FireServer()
	end
end

-- Handle the result of a drop from the server
function BlockController.handleDropResult(result: Types.DropResult)
	if result.eliminated then
		-- Handle elimination
		InputHandler.unbindDropAction()
		print("Game Over! You stacked " .. blockCount .. " blocks!")

		-- Play miss sound and fade out music
		SoundController.play("miss")
		SoundController.fadeOutMusic(1.5)

		-- Zoom out to show the full tower
		CameraController.zoomOutToShowTower(towerHeight)
		return
	end

	if result.isPerfect then
		print("PERFECT!")
		comboCount = comboCount + 1
		-- Play perfect sound with increasing pitch for combos (max 1.5x)
		local pitch = 1 + math.min(comboCount - 1, 5) * 0.1
		SoundController.playWithPitch("perfectStack", pitch)
	else
		-- Partial stack - play chop sound
		comboCount = 0
		SoundController.play("blockChop")
	end

	-- Play landing sound
	SoundController.play("blockLand")

	-- Update tower height tracking
	blockCount = blockCount + 1
	towerHeight = towerHeight + Constants.BLOCK_HEIGHT

	-- Update camera to follow tower
	CameraController.setTargetHeight(basePosition.Y + towerHeight)

	currentBlockData = nil
end

-- Clean up
function BlockController.cleanup()
	InputHandler.unbindDropAction()
	CameraController.cleanup()
	SoundController.cleanup()
	currentBlockData = nil
	isDropping = false
	towerHeight = 0
	blockCount = 0
	comboCount = 0
end

return BlockController
