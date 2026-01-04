--[[
	BlockService.luau
	Server-authoritative block spawning, validation, and dropping.
	Blocks slide at landing height for easy alignment visualization.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Types = require(ReplicatedStorage.Shared.Types)
local BlockFactory = require(ReplicatedStorage.Shared.BlockFactory)
local TowerState = require(ReplicatedStorage.Shared.TowerState)

local BlockService = {}

-- Storage for active games
local playerTowers: { [Player]: Types.TowerData } = {}
local activeBlocks: { [Player]: { part: Part, data: Types.BlockData, swingTween: Tween } } = {}

-- RemoteEvents (set during init)
local remotes: {
	RequestDrop: RemoteEvent?,
	BlockDropped: RemoteEvent?,
	BlockSpawned: RemoteEvent?,
	GameStateUpdate: RemoteEvent?,
	RestartGame: RemoteEvent?,
} = {}

-- Get or create the Blocks folder in workspace
local function getBlocksFolder(): Folder
	local blocksFolder = workspace:FindFirstChild("Blocks")
	if not blocksFolder then
		blocksFolder = Instance.new("Folder")
		blocksFolder.Name = "Blocks"
		blocksFolder.Parent = workspace
	end
	return blocksFolder :: Folder
end

-- Initialize the service with RemoteEvents
function BlockService.init(remotesFolder: Folder)
	remotes.RequestDrop = remotesFolder:WaitForChild("RequestDrop") :: RemoteEvent
	remotes.BlockDropped = remotesFolder:WaitForChild("BlockDropped") :: RemoteEvent
	remotes.BlockSpawned = remotesFolder:WaitForChild("BlockSpawned") :: RemoteEvent
	remotes.GameStateUpdate = remotesFolder:WaitForChild("GameStateUpdate") :: RemoteEvent
	remotes.RestartGame = remotesFolder:WaitForChild("RestartGame") :: RemoteEvent

	-- Handle drop requests from clients
	remotes.RequestDrop.OnServerEvent:Connect(function(player)
		BlockService.handleDropRequest(player)
	end)

	-- Handle restart requests from clients
	remotes.RestartGame.OnServerEvent:Connect(function(player)
		BlockService.restartGame(player)
	end)
end

-- Start a new game for a player at the specified base position
function BlockService.startGameForPlayer(player: Player, basePosition: Vector3)
	-- Randomize starting color (1 to GRADIENT_CYCLE_LENGTH)
	local startingColorIndex = math.random(1, Constants.GRADIENT_CYCLE_LENGTH)

	-- Initialize tower with random starting color
	playerTowers[player] = TowerState.new(player.UserId, basePosition, startingColorIndex)

	-- Create foundation pillar (acts as base to stack on)
	BlockService.createFoundation(player, basePosition, startingColorIndex)

	-- Spawn first block
	BlockService.spawnNextBlock(player)
end

-- Create foundation pillar for the player (acts as the base to stack on)
function BlockService.createFoundation(player: Player, basePosition: Vector3, startingColorIndex: number)
	local blocksFolder = getBlocksFolder()

	-- Create foundation pillar that extends down from base position
	local pillarHeight = 50
	local pillarWidth = Constants.DEFAULT_BLOCK_SIZE.X
	local foundation = Instance.new("Part")
	foundation.Name = "Foundation_" .. player.UserId
	foundation.Size = Vector3.new(pillarWidth, pillarHeight, pillarWidth)
	-- Position so top of pillar is at basePosition
	foundation.Position = Vector3.new(
		basePosition.X,
		basePosition.Y - pillarHeight / 2 + Constants.BLOCK_HEIGHT / 2,
		basePosition.Z
	)
	foundation.Anchored = true
	foundation.CanCollide = false
	foundation.Color = Constants.getBlockColor(startingColorIndex)
	foundation.Material = Enum.Material.SmoothPlastic
	foundation.Parent = blocksFolder
end

-- Spawn the next swinging block for a player (at landing height, slides horizontally)
function BlockService.spawnNextBlock(player: Player)
	local tower = playerTowers[player]
	if not tower then
		return
	end

	local axis = TowerState.getNextBlockAxis(tower)
	local size = TowerState.getTopBlockSize(tower)

	-- Get the center position of the top block (or base if no blocks yet)
	local centerX, centerZ
	if #tower.blocks > 0 then
		local topBlock = tower.blocks[#tower.blocks]
		centerX = topBlock.position.X
		centerZ = topBlock.position.Z
	else
		centerX = tower.basePosition.X
		centerZ = tower.basePosition.Z
	end

	-- Spawn at landing height (on top of the base/tower, not intersecting)
	local landingY = tower.basePosition.Y + Constants.BLOCK_HEIGHT / 2 + tower.currentHeight + Constants.BLOCK_HEIGHT / 2
	local spawnPos = Vector3.new(centerX, landingY, centerZ)

	-- Create block (color index = starting color + blocks stacked so far + 1)
	local colorIndex = tower.startingColorIndex + tower.blockCount + 1
	local blockPart, blockData = BlockFactory.createSwingingBlock(axis, size, spawnPos, colorIndex, tower.blockCount + 1)

	-- Disable collision so it can slide through the tower
	blockPart.CanCollide = false

	-- Parent to workspace
	blockPart.Parent = getBlocksFolder()

	-- Create swing animation (horizontal slide at landing height, centered on top block)
	local swingCenter = Vector3.new(centerX, landingY, centerZ)
	local swingTween = BlockService.createSwingTween(blockPart, blockData, swingCenter)

	-- Store active block
	activeBlocks[player] = {
		part = blockPart,
		data = blockData,
		swingTween = swingTween,
	}

	-- Notify client
	if remotes.BlockSpawned then
		remotes.BlockSpawned:FireClient(player, blockData)
	end

	-- Start the swing
	swingTween:Play()
end

-- Create a ping-pong swing tween for the block (horizontal slide centered on swingCenter)
function BlockService.createSwingTween(blockPart: Part, blockData: Types.BlockData, swingCenter: Vector3): Tween
	-- Scale amplitude based on block size (swing a bit wider than the block itself)
	local blockWidth = if blockData.axis == "X" then blockData.size.X else blockData.size.Z
	local amplitude = blockWidth + 2 -- Block width plus small padding
	local swingTime = (amplitude * 2) / blockData.swingSpeed

	local startPos, endPos
	if blockData.axis == "X" then
		startPos = Vector3.new(swingCenter.X - amplitude, swingCenter.Y, swingCenter.Z)
		endPos = Vector3.new(swingCenter.X + amplitude, swingCenter.Y, swingCenter.Z)
	else
		startPos = Vector3.new(swingCenter.X, swingCenter.Y, swingCenter.Z - amplitude)
		endPos = Vector3.new(swingCenter.X, swingCenter.Y, swingCenter.Z + amplitude)
	end

	-- Position at start
	blockPart.Position = startPos

	local tweenInfo = TweenInfo.new(
		swingTime,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1, -- Repeat forever
		true -- Reverse (ping-pong)
	)

	return TweenService:Create(blockPart, tweenInfo, { Position = endPos })
end

-- Handle a drop request from a player
function BlockService.handleDropRequest(player: Player)
	local active = activeBlocks[player]
	local tower = playerTowers[player]

	if not active or not tower then
		return
	end

	-- Stop swing
	active.swingTween:Cancel()

	-- Get current position at moment of drop
	local dropPosition = active.part.Position

	-- Calculate landing result
	local result = BlockService.calculateLanding(tower, active.data, dropPosition)

	if result.eliminated then
		-- Handle elimination - block falls away
		BlockService.animateBlockFallOff(active.part)
		activeBlocks[player] = nil

		-- Include final stats in elimination result
		result.score = tower.score
		result.comboCount = 0
		result.pointsEarned = 0

		if remotes.BlockDropped then
			remotes.BlockDropped:FireClient(player, result)
		end
		return
	end

	-- Update combo
	if result.isPerfect then
		tower.comboCount = tower.comboCount + 1
		tower.maxCombo = math.max(tower.maxCombo, tower.comboCount)
	else
		tower.comboCount = 0
	end

	-- Calculate points
	local pointsEarned = Constants.calculatePoints(result.isPerfect, tower.comboCount)
	tower.score = tower.score + pointsEarned

	-- Add scoring to result
	result.score = tower.score
	result.comboCount = tower.comboCount
	result.pointsEarned = pointsEarned

	-- Calculate final position
	local landPosition = Vector3.new(
		result.landedPosition.X,
		active.part.Position.Y, -- Already at correct height
		result.landedPosition.Z
	)

	-- FIRST: Immediately resize and reposition the block (chop happens instantly)
	if result.newBlockSize then
		active.part.Size = result.newBlockSize
	end
	active.part.Position = landPosition

	-- SECOND: Spawn falling debris after the chop
	if not result.isPerfect and result.newBlockSize then
		BlockService.spawnFallingDebris(active.part, active.data, dropPosition, result)
	end

	-- THIRD: Small bounce animation on the chopped piece
	BlockService.animateBounce(active.part, landPosition, function()
		-- Update tower state after animation
		local landedBlock: Types.BlockData = {
			id = active.data.id,
			size = result.newBlockSize or active.data.size,
			position = landPosition,
			axis = active.data.axis,
			swingSpeed = active.data.swingSpeed,
		}
		TowerState.addBlock(tower, landedBlock)

		-- Notify client
		if remotes.BlockDropped then
			remotes.BlockDropped:FireClient(player, result)
		end

		-- Clear active and spawn next
		activeBlocks[player] = nil
		BlockService.spawnNextBlock(player)
	end)
end

-- Animate a small vertical bounce after block is placed
function BlockService.animateBounce(blockPart: Part, restPosition: Vector3, onComplete: () -> ())
	-- Small hop up
	local bounceHeight = 0.3
	local hopPosition = restPosition + Vector3.new(0, bounceHeight, 0)

	local hopTween = TweenService:Create(
		blockPart,
		TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = hopPosition }
	)

	hopTween.Completed:Connect(function()
		-- Fall back down
		local dropTween = TweenService:Create(
			blockPart,
			TweenInfo.new(0.1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
			{ Position = restPosition }
		)

		dropTween.Completed:Connect(function()
			onComplete()
		end)

		dropTween:Play()
	end)

	hopTween:Play()
end

-- Animate block falling off when player misses
function BlockService.animateBlockFallOff(blockPart: Part)
	local fallTween = TweenService:Create(
		blockPart,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Position = blockPart.Position - Vector3.new(0, 50, 0),
			Transparency = 1
		}
	)

	fallTween.Completed:Connect(function()
		blockPart:Destroy()
	end)

	fallTween:Play()
end

-- Spawn the cut-off debris that falls with gravity
function BlockService.spawnFallingDebris(originalPart: Part, blockData: Types.BlockData, dropPosition: Vector3, result: Types.DropResult)
	local axis = blockData.axis
	local originalSize = blockData.size
	local newSize = result.newBlockSize

	if not newSize then return end

	-- Calculate debris size (the part that was cut off)
	local debrisSize: Vector3
	local debrisPosition: Vector3

	if axis == "X" then
		-- Cut was on X axis
		local cutAmount = originalSize.X - newSize.X
		if cutAmount <= 0 then return end

		debrisSize = Vector3.new(cutAmount, originalSize.Y, originalSize.Z)

		-- Determine which side was cut (compare drop position to landed position)
		if dropPosition.X > result.landedPosition.X then
			-- Overhang was on the positive X side (right)
			debrisPosition = Vector3.new(
				result.landedPosition.X + newSize.X / 2 + cutAmount / 2,
				dropPosition.Y,
				result.landedPosition.Z
			)
		else
			-- Overhang was on the negative X side (left)
			debrisPosition = Vector3.new(
				result.landedPosition.X - newSize.X / 2 - cutAmount / 2,
				dropPosition.Y,
				result.landedPosition.Z
			)
		end
	else
		-- Cut was on Z axis
		local cutAmount = originalSize.Z - newSize.Z
		if cutAmount <= 0 then return end

		debrisSize = Vector3.new(originalSize.X, originalSize.Y, cutAmount)

		-- Determine which side was cut
		if dropPosition.Z > result.landedPosition.Z then
			-- Overhang was on the positive Z side (back)
			debrisPosition = Vector3.new(
				result.landedPosition.X,
				dropPosition.Y,
				result.landedPosition.Z + newSize.Z / 2 + cutAmount / 2
			)
		else
			-- Overhang was on the negative Z side (front)
			debrisPosition = Vector3.new(
				result.landedPosition.X,
				dropPosition.Y,
				result.landedPosition.Z - newSize.Z / 2 - cutAmount / 2
			)
		end
	end

	-- Create debris part
	local debris = Instance.new("Part")
	debris.Name = "Debris"
	debris.Size = debrisSize
	debris.Position = debrisPosition
	debris.Color = originalPart.Color
	debris.Material = Enum.Material.SmoothPlastic
	debris.Anchored = false -- Falls with gravity!
	debris.CanCollide = false -- Don't collide with tower
	debris.Parent = getBlocksFolder()

	-- Clean up debris after a few seconds
	task.delay(3, function()
		if debris and debris.Parent then
			debris:Destroy()
		end
	end)
end

-- Calculate the landing result (overlap, chopping, etc.)
function BlockService.calculateLanding(
	tower: Types.TowerData,
	blockData: Types.BlockData,
	dropPosition: Vector3
): Types.DropResult
	-- First block always lands on the base platform
	if tower.blockCount == 0 then
		return {
			success = true,
			landedPosition = Vector3.new(
				tower.basePosition.X,
				dropPosition.Y,
				tower.basePosition.Z
			),
			newBlockSize = blockData.size,
			isPerfect = true,
			eliminated = false,
		}
	end

	local topBlock = tower.blocks[#tower.blocks]
	local axis = blockData.axis

	-- Calculate overlap on the swing axis
	local droppedMin, droppedMax, baseMin, baseMax

	if axis == "X" then
		local halfWidth = blockData.size.X / 2
		local baseHalfWidth = topBlock.size.X / 2

		droppedMin = dropPosition.X - halfWidth
		droppedMax = dropPosition.X + halfWidth
		baseMin = topBlock.position.X - baseHalfWidth
		baseMax = topBlock.position.X + baseHalfWidth
	else
		local halfDepth = blockData.size.Z / 2
		local baseHalfDepth = topBlock.size.Z / 2

		droppedMin = dropPosition.Z - halfDepth
		droppedMax = dropPosition.Z + halfDepth
		baseMin = topBlock.position.Z - baseHalfDepth
		baseMax = topBlock.position.Z + baseHalfDepth
	end

	-- Calculate overlap
	local overlapMin = math.max(droppedMin, baseMin)
	local overlapMax = math.min(droppedMax, baseMax)
	local overlapSize = overlapMax - overlapMin

	-- Complete miss - no overlap
	if overlapSize <= 0 then
		return {
			success = false,
			eliminated = true,
		}
	end

	-- Check for perfect stack (within tolerance)
	local droppedCenter = (droppedMin + droppedMax) / 2
	local baseCenter = (baseMin + baseMax) / 2
	local offset = math.abs(droppedCenter - baseCenter)
	local isPerfect = offset <= Constants.PERFECT_TOLERANCE

	-- Calculate new block size and position
	local newSize = blockData.size
	local landedCenter = dropPosition

	if not isPerfect then
		-- Partial stack - chop overhang
		local overlapCenter = (overlapMin + overlapMax) / 2

		if axis == "X" then
			newSize = Vector3.new(overlapSize, blockData.size.Y, blockData.size.Z)
			landedCenter = Vector3.new(overlapCenter, dropPosition.Y, topBlock.position.Z)
		else
			newSize = Vector3.new(blockData.size.X, blockData.size.Y, overlapSize)
			landedCenter = Vector3.new(topBlock.position.X, dropPosition.Y, overlapCenter)
		end
	else
		-- Perfect stack - align with block below
		landedCenter = Vector3.new(topBlock.position.X, dropPosition.Y, topBlock.position.Z)
	end

	return {
		success = true,
		landedPosition = landedCenter,
		newBlockSize = newSize,
		isPerfect = isPerfect,
		eliminated = false,
	}
end

-- Restart game for a player
function BlockService.restartGame(player: Player)
	local tower = playerTowers[player]
	local basePosition = if tower then tower.basePosition else Vector3.new(0, 5, 0)

	-- Clean up existing blocks
	BlockService.cleanupPlayerBlocks(player)

	-- Start fresh game
	BlockService.startGameForPlayer(player, basePosition)
end

-- Clean up all blocks for a player
function BlockService.cleanupPlayerBlocks(player: Player)
	-- Cancel active block
	local active = activeBlocks[player]
	if active then
		if active.swingTween then
			active.swingTween:Cancel()
		end
		if active.part then
			active.part:Destroy()
		end
		activeBlocks[player] = nil
	end

	-- Remove tower blocks
	local tower = playerTowers[player]
	if tower then
		local blocksFolder = getBlocksFolder()

		-- Remove foundation
		local foundation = blocksFolder:FindFirstChild("Foundation_" .. player.UserId)
		if foundation then
			foundation:Destroy()
		end

		-- Remove all stacked blocks for this tower
		for _, block in tower.blocks do
			local blockPart = blocksFolder:FindFirstChild("Block_" .. block.id)
			if blockPart then
				blockPart:Destroy()
			end
		end
	end

	playerTowers[player] = nil
end

-- Clean up when a player leaves
function BlockService.cleanup(player: Player)
	BlockService.cleanupPlayerBlocks(player)
end

return BlockService
