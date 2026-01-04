--[[
	Types.luau
	Shared type definitions for Stack Royale.
]]

export type BlockAxis = "X" | "Z"

export type BlockData = {
	id: string,
	size: Vector3,
	position: Vector3,
	axis: BlockAxis,
	swingSpeed: number,
}

export type TowerData = {
	playerId: number,
	blocks: { BlockData },
	basePosition: Vector3,
	currentHeight: number,
	blockCount: number,
	currentAxis: BlockAxis,
	startingColorIndex: number,
	-- Scoring
	score: number,
	comboCount: number,
	maxCombo: number,
}

export type DropResult = {
	success: boolean,
	landedPosition: Vector3?,
	newBlockSize: Vector3?,
	isPerfect: boolean?,
	eliminated: boolean?,
	-- Scoring
	score: number?,
	comboCount: number?,
	pointsEarned: number?,
}

export type GameStats = {
	score: number,
	comboCount: number,
	blockCount: number,
	maxCombo: number,
}

return nil
