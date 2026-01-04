--[[
	GameState.luau
	Shared game state that can be subscribed to by React components.
]]

local GameState = {}

-- Current state
local state = {
	score = 0,
	comboCount = 0,
	blockCount = 0,
	showPerfect = false,
	pointsEarned = 0,
	isGameOver = false,
	isEliminated = false, -- Set immediately on loss (for fade out animation)
}

-- Subscribers
local subscribers: { () -> () } = {}

-- Restart callback (set by BlockController)
local restartCallback: (() -> ())? = nil

-- Subscribe to state changes
function GameState.subscribe(callback: () -> ()): () -> ()
	table.insert(subscribers, callback)

	-- Return unsubscribe function
	return function()
		local index = table.find(subscribers, callback)
		if index then
			table.remove(subscribers, index)
		end
	end
end

-- Notify all subscribers
local function notifySubscribers()
	for _, callback in subscribers do
		callback()
	end
end

-- Get current state (returns shallow copy for React change detection)
function GameState.getState()
	return {
		score = state.score,
		comboCount = state.comboCount,
		blockCount = state.blockCount,
		showPerfect = state.showPerfect,
		pointsEarned = state.pointsEarned,
		isGameOver = state.isGameOver,
		isEliminated = state.isEliminated,
	}
end

-- Update score and combo
function GameState.updateScore(score: number, comboCount: number, blockCount: number, pointsEarned: number, isPerfect: boolean)
	state.score = score
	state.comboCount = comboCount
	state.blockCount = blockCount
	state.pointsEarned = pointsEarned

	if isPerfect then
		state.showPerfect = true
		-- Hide perfect popup after a delay
		task.delay(1, function()
			state.showPerfect = false
			notifySubscribers()
		end)
	end

	notifySubscribers()
end

-- Set eliminated (triggers fade out animation)
function GameState.setEliminated(isEliminated: boolean)
	state.isEliminated = isEliminated
	notifySubscribers()
end

-- Set game over
function GameState.setGameOver(isGameOver: boolean)
	state.isGameOver = isGameOver
	notifySubscribers()
end

-- Reset state for new game
function GameState.reset()
	state.score = 0
	state.comboCount = 0
	state.blockCount = 0
	state.showPerfect = false
	state.pointsEarned = 0
	state.isGameOver = false
	state.isEliminated = false
	notifySubscribers()
end

-- Set the restart callback (called by BlockController)
function GameState.setRestartCallback(callback: () -> ())
	restartCallback = callback
end

-- Request restart (called by UI)
function GameState.requestRestart()
	if restartCallback then
		restartCallback()
	end
end

return GameState
