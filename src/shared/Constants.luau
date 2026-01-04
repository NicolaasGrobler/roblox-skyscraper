--[[
	Constants.luau
	Game constants and formulas for Stack Royale.
]]

local Constants = {
	-- Block dimensions
	DEFAULT_BLOCK_SIZE = Vector3.new(4, 1, 4),
	BLOCK_HEIGHT = 1,

	-- Swing mechanics
	BASE_SWING_SPEED = 5.0, -- Studs per second at start (faster)
	SPEED_INCREMENT = 0.1, -- Speed added per block
	SWING_AMPLITUDE = 8, -- Distance from center to edge of swing

	-- Tolerances
	PERFECT_TOLERANCE = 0.5, -- Studs offset for "perfect" stack (increased for easier gameplay)

	-- Spawn positions
	SPAWN_HEIGHT_OFFSET = 5, -- How high above tower to spawn block

	-- Colors (rainbow gradient keypoints)
	BLOCK_COLORS = {
		Color3.fromRGB(255, 89, 94), -- Red
		Color3.fromRGB(255, 146, 76), -- Orange
		Color3.fromRGB(255, 217, 61), -- Yellow
		Color3.fromRGB(138, 201, 38), -- Green
		Color3.fromRGB(25, 167, 206), -- Cyan
		Color3.fromRGB(106, 76, 219), -- Purple
		Color3.fromRGB(255, 89, 94), -- Back to Red (for seamless loop)
	},

	-- How many blocks before the gradient fully cycles
	GRADIENT_CYCLE_LENGTH = 30,
}

-- Calculate swing speed based on block count (from GDD formula)
function Constants.calculateSwingSpeed(blockCount: number): number
	return Constants.BASE_SWING_SPEED + (blockCount * Constants.SPEED_INCREMENT)
end

-- Get block color based on block index (smooth gradient interpolation)
function Constants.getBlockColor(blockIndex: number): Color3
	local colors = Constants.BLOCK_COLORS
	local numColors = #colors - 1 -- Subtract 1 because last color is same as first (for looping)
	local cycleLength = Constants.GRADIENT_CYCLE_LENGTH

	-- Calculate position in the gradient (0 to 1, then loops)
	local progress = ((blockIndex - 1) % cycleLength) / cycleLength

	-- Map progress to color index
	local scaledProgress = progress * numColors
	local colorIndex = math.floor(scaledProgress) + 1
	local t = scaledProgress - math.floor(scaledProgress) -- Interpolation factor (0 to 1)

	-- Get the two colors to interpolate between
	local color1 = colors[colorIndex]
	local color2 = colors[colorIndex + 1] or colors[1]

	-- Smooth interpolation using Lerp
	return color1:Lerp(color2, t)
end

return Constants
