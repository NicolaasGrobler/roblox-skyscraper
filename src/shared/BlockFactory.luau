--[[
	BlockFactory.luau
	Creates block Part instances with proper visual styling.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Types = require(ReplicatedStorage.Shared.Types)

local BlockFactory = {}

-- Create a styled block Part from BlockData
function BlockFactory.createBlock(data: Types.BlockData, colorIndex: number): Part
	local block = Instance.new("Part")
	block.Name = "Block_" .. data.id
	block.Size = data.size
	block.Position = data.position
	block.Anchored = true
	block.CanCollide = false -- We handle collision manually

	-- Visual styling
	block.Color = Constants.getBlockColor(colorIndex)
	block.Material = Enum.Material.SmoothPlastic

	return block
end

-- Create a new swinging block with generated ID and data
function BlockFactory.createSwingingBlock(
	axis: Types.BlockAxis,
	size: Vector3,
	centerPosition: Vector3,
	colorIndex: number,
	blockCount: number?
): (Part, Types.BlockData)
	local blockId = HttpService:GenerateGUID(false)

	-- Use blockCount for speed if provided, otherwise derive from colorIndex
	local speedBlockCount = blockCount or colorIndex

	local data: Types.BlockData = {
		id = blockId,
		size = size,
		position = centerPosition,
		axis = axis,
		swingSpeed = Constants.calculateSwingSpeed(speedBlockCount),
	}

	local block = BlockFactory.createBlock(data, colorIndex)

	return block, data
end

return BlockFactory
