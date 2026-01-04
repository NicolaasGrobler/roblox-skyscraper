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
local GameState = require(script.Parent.Parent.state.GameState)

local BlockController = {}

local remotes: {
	RequestDrop: RemoteEvent?,
	BlockDropped: RemoteEvent?,
	BlockSpawned: RemoteEvent?,
	RestartGame: RemoteEvent?,
} = {}

local currentBlockData: Types.BlockData? = nil
local isDropping = false
local towerHeight = 0
local blockCount = 0
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
	remotes.RestartGame = remotesFolder:WaitForChild("RestartGame") :: RemoteEvent

	print("[BlockController] RemoteEvents connected")

	-- Set up restart callback for UI
	GameState.setRestartCallback(function()
		BlockController.requestRestart()
	end)

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

		-- Immediately trigger UI fade out
		GameState.setEliminated(true)

		-- Play miss sound and fade out music
		SoundController.play("miss")
		SoundController.fadeOutMusic(1.5)

		-- Zoom out to show the full tower, then show game over screen
		CameraController.zoomOutToShowTower(towerHeight, function()
			GameState.setGameOver(true)
		end)
		return
	end

	if result.isPerfect then
		print("PERFECT!")
		-- Play perfect sound with increasing pitch for combos (max 1.5x)
		local comboCount = result.comboCount or 1
		local pitch = 1 + math.min(comboCount - 1, 5) * 0.1
		SoundController.playWithPitch("perfectStack", pitch)
	else
		-- Partial stack - play chop sound
		SoundController.play("blockChop")
	end

	-- Play landing sound
	SoundController.play("blockLand")

	-- Update tower height tracking
	blockCount = blockCount + 1
	towerHeight = towerHeight + Constants.BLOCK_HEIGHT

	-- Update game state for UI
	GameState.updateScore(
		result.score or 0,
		result.comboCount or 0,
		blockCount,
		result.pointsEarned or 0,
		result.isPerfect or false
	)

	-- Update camera to follow tower
	CameraController.setTargetHeight(basePosition.Y + towerHeight)

	currentBlockData = nil
end

-- Request to restart the game
function BlockController.requestRestart()
	print("[BlockController] Restart requested")

	-- Smooth transition: fade out, reset, fade in
	CameraController.transitionWithFade(function()
		-- This runs while screen is black

		-- Reset local state
		currentBlockData = nil
		isDropping = false
		towerHeight = 0
		blockCount = 0

		-- Reset game state
		GameState.reset()

		-- Reset camera
		CameraController.init(basePosition)

		-- Tell server to restart
		if remotes.RestartGame then
			remotes.RestartGame:FireServer()
		end
	end, function()
		-- This runs after fade in completes

		-- Restart music
		SoundController.fadeInMusic(2)

		-- Re-bind input
		InputHandler.bindDropAction(function()
			BlockController.requestDrop()
		end)
	end)
end

-- Clean up
function BlockController.cleanup()
	InputHandler.unbindDropAction()
	CameraController.cleanup()
	SoundController.cleanup()
	GameState.reset()
	currentBlockData = nil
	isDropping = false
	towerHeight = 0
	blockCount = 0
end

return BlockController
