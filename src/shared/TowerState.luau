--[[
	TowerState.luau
	Tower data structure and helper functions.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Types = require(ReplicatedStorage.Shared.Types)

local TowerState = {}

-- Create a new tower data structure for a player
function TowerState.new(playerId: number, basePosition: Vector3, startingColorIndex: number): Types.TowerData
	return {
		playerId = playerId,
		blocks = {},
		basePosition = basePosition,
		currentHeight = 0,
		blockCount = 0,
		currentAxis = "X" :: Types.BlockAxis, -- First block swings on X axis
		startingColorIndex = startingColorIndex,
	}
end

-- Get the axis for the next block to swing on
function TowerState.getNextBlockAxis(tower: Types.TowerData): Types.BlockAxis
	return tower.currentAxis
end

-- Toggle the axis (X -> Z, Z -> X)
function TowerState.toggleAxis(tower: Types.TowerData)
	tower.currentAxis = if tower.currentAxis == "X" then "Z" else "X"
end

-- Get the size of the top block (or default if no blocks placed)
function TowerState.getTopBlockSize(tower: Types.TowerData): Vector3
	if #tower.blocks == 0 then
		return Constants.DEFAULT_BLOCK_SIZE
	end
	return tower.blocks[#tower.blocks].size
end

-- Calculate where to spawn the next block
function TowerState.getSpawnPosition(tower: Types.TowerData): Vector3
	local baseY = tower.basePosition.Y + tower.currentHeight + Constants.SPAWN_HEIGHT_OFFSET
	return Vector3.new(tower.basePosition.X, baseY, tower.basePosition.Z)
end

-- Add a landed block to the tower
function TowerState.addBlock(tower: Types.TowerData, block: Types.BlockData)
	table.insert(tower.blocks, block)
	tower.blockCount = tower.blockCount + 1
	tower.currentHeight = tower.currentHeight + Constants.BLOCK_HEIGHT
	TowerState.toggleAxis(tower)
end

return TowerState
