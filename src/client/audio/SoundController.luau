--[[
	SoundController.luau
	Handles all game audio - sound effects and background music.
]]

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SoundController = {}

-- Sound configuration (Roblox asset IDs)
local SOUNDS = {
	-- Block sounds
	blockLand = "rbxassetid://94566034867455", -- Soft thud
	perfectStack = "rbxassetid://94579271121222", -- Success chime
	blockChop = "rbxassetid://109901832456738", -- Slice/cut sound
	miss = "rbxassetid://101801407522720", -- Fail buzzer

	-- UI sounds
	buttonClick = "rbxassetid://6895079853", -- Click
}

-- Background music tracks (one is randomly selected each game)
local MUSIC_TRACKS = {
	"rbxassetid://125307653016421",
	"rbxassetid://115020282139088",
}

-- Volume levels
local VOLUMES = {
	blockLand = 0.5,
	perfectStack = 0.7,
	blockChop = 0.4,
	miss = 0.6,
	buttonClick = 0.3,
	backgroundMusic = 0.3,
}

-- Sound instances cache
local soundInstances: { [string]: Sound } = {}
local musicInstance: Sound? = nil

-- Create a sound instance
local function createSound(name: string, id: string, volume: number): Sound
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Volume = volume
	sound.Parent = SoundService
	return sound
end

-- Initialize all sounds
function SoundController.init()
	-- Create sound effect instances
	for name, id in pairs(SOUNDS) do
		soundInstances[name] = createSound(name, id, VOLUMES[name] or 0.5)
	end

	-- Randomly select a music track
	local trackIndex = math.random(1, #MUSIC_TRACKS)
	local randomTrack = MUSIC_TRACKS[trackIndex]

	-- Create music instance (loops)
	musicInstance = createSound("BackgroundMusic", randomTrack, VOLUMES.backgroundMusic)
	musicInstance.Looped = true

	print("[SoundController] Initialized with track", trackIndex)
end

-- Play a sound effect
function SoundController.play(soundName: string)
	local sound = soundInstances[soundName]
	if sound then
		-- Clone and play for overlapping sounds
		local clone = sound:Clone()
		clone.Parent = SoundService
		clone:Play()

		-- Clean up after playing
		clone.Ended:Connect(function()
			clone:Destroy()
		end)
	else
		warn("[SoundController] Sound not found:", soundName)
	end
end

-- Play sound with pitch variation (for combos)
function SoundController.playWithPitch(soundName: string, pitch: number)
	local sound = soundInstances[soundName]
	if sound then
		local clone = sound:Clone()
		clone.PlaybackSpeed = pitch
		clone.Parent = SoundService
		clone:Play()

		clone.Ended:Connect(function()
			clone:Destroy()
		end)
	end
end

-- Start background music
function SoundController.startMusic()
	if musicInstance and not musicInstance.Playing then
		musicInstance:Play()
		print("[SoundController] Music started")
	end
end

-- Stop background music
function SoundController.stopMusic()
	if musicInstance and musicInstance.Playing then
		musicInstance:Stop()
	end
end

-- Fade music in
function SoundController.fadeInMusic(duration: number?)
	if not musicInstance then
		return
	end

	local fadeTime = duration or 2
	musicInstance.Volume = 0
	musicInstance:Play()

	local tween = TweenService:Create(
		musicInstance,
		TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Volume = VOLUMES.backgroundMusic }
	)
	tween:Play()
end

-- Fade music out
function SoundController.fadeOutMusic(duration: number?)
	if not musicInstance or not musicInstance.Playing then
		return
	end

	local fadeTime = duration or 1
	local tween = TweenService:Create(
		musicInstance,
		TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Volume = 0 }
	)
	tween:Play()
	tween.Completed:Connect(function()
		musicInstance:Stop()
		musicInstance.Volume = VOLUMES.backgroundMusic
	end)
end

-- Set master volume (0-1)
function SoundController.setMasterVolume(volume: number)
	for _, sound in pairs(soundInstances) do
		sound.Volume = (VOLUMES[sound.Name] or 0.5) * volume
	end
	if musicInstance then
		musicInstance.Volume = VOLUMES.backgroundMusic * volume
	end
end

-- Cleanup
function SoundController.cleanup()
	for _, sound in pairs(soundInstances) do
		sound:Destroy()
	end
	soundInstances = {}

	if musicInstance then
		musicInstance:Stop()
		musicInstance:Destroy()
		musicInstance = nil
	end
end

return SoundController
