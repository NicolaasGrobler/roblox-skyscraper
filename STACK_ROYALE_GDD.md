# Stack Royale

## Game Design Document

**Version 1.1 • January 2026**

---

## 1. Game Overview

### 1.1 Concept

Stack Royale is a competitive multiplayer stacking game where players race to build the tallest tower by timing their block drops perfectly. Blocks swing back and forth, alternating directions as the tower grows. Misaligned drops get "chopped" to match the block below, making precision increasingly critical. The last player standing wins.

### 1.2 Key Features

- **Alternating axis movement:** Blocks swing X-axis then Z-axis, keeping gameplay fresh
- **Precision chopping:** Overhanging parts get cut off - blocks shrink with inaccuracy
- **Multiplayer competition:** 2-8 players compete simultaneously in separate arenas
- **Progressive difficulty:** Speed gradually increases as towers grow
- **Combo scoring:** Perfect stacks build multipliers for high scores

### 1.3 Target Audience

Casual Roblox players aged 8-16 who enjoy competitive mini-games, reflexes-based challenges, and playing with friends. The simple one-button mechanic makes it accessible while the skill ceiling rewards practice.

---

## 2. Core Mechanics

### 2.1 Block Movement

Each block swings horizontally **at landing height** (not above), sliding back and forth across the tower surface. This allows players to clearly see alignment before dropping. Movement alternates between axes:

1. **Block 1:** Swings along X-axis (left-right)
2. **Block 2:** Swings along Z-axis (front-back)
3. **Block 3:** X-axis again
4. Pattern continues alternating...

The swing amplitude scales with block size, keeping the swing proportional as blocks get smaller from chopping.

### 2.2 Stacking & Chopping

When a block lands, the game calculates overlap with the block below:

| Outcome | Description |
|---------|-------------|
| **Perfect Stack** | Within 0.5 stud tolerance. Block lands perfectly, no chopping. Triggers bonus points and combo. |
| **Partial Stack** | Overhang detected. The overhanging portion is "chopped" off and falls. The remaining block becomes the new landing surface. |
| **Complete Miss** | No overlap with block below. Block falls off entirely. Player is eliminated. |

**Technical note:** The chopping is calculated by finding the intersection of two axis-aligned bounding boxes (AABBs) and creating a new block part sized to the overlap region.

### 2.3 Speed Progression

Block swing speed increases gradually using the formula:

```
speed = 5.0 + (blockCount × 0.1)
```

Starting speed is 5 studs/second, increasing by 0.1 per block. This creates a smooth "boiling frog" effect where players don't notice the increasing difficulty until they're suddenly challenged.

### 2.4 Controls

Single input only - multiple options for accessibility:
- **PC:** Click, Space, or E key
- **Mobile:** Tap anywhere
- **Controller:** A button (Xbox) / X button (PlayStation)

This simplicity is intentional - the skill is purely in timing, not complex controls.

---

## 3. Game Flow

### 3.1 Core Loop

1. **Wait:** Block swings above the tower
2. **Time:** Player watches and anticipates alignment
3. **Drop:** Player clicks/taps at the right moment
4. **Result:** Block lands, chops if needed, score updates
5. **Repeat:** Next block spawns on alternating axis (or elimination)

### 3.2 Match Structure

**Format:** Last Standing - all players stack simultaneously until only one remains.

| Phase | Description |
|-------|-------------|
| **Lobby** | Players join, minimum 2 to start. Host can start early or wait for more. 60-second countdown with option to ready-up. |
| **Countdown** | 3-2-1-GO! Players teleported to individual arenas. Camera positioned. |
| **Gameplay** | Simultaneous stacking. UI shows all players' heights. Eliminated players become spectators. |
| **Victory** | Last player standing wins. Results screen shows rankings, heights, and scores. Return to lobby. |

---

## 4. Scoring System

### 4.1 Point Values

1. **Base points per block:** 100 points
2. **Perfect stack bonus:** +50 points
3. **Combo multiplier:** Consecutive perfects multiply bonus (×2, ×3, ×4... up to ×10)

### 4.2 Example Scoring

| Block | Result | Points | Running Total |
|-------|--------|--------|---------------|
| 1 | Perfect | 100 + 50 = 150 | 150 |
| 2 | Perfect (×2) | 100 + 100 = 200 | 350 |
| 3 | Partial | 100 (combo reset) | 450 |
| 4 | Perfect | 100 + 50 = 150 | 600 |

---

## 5. Multiplayer System

### 5.1 Arena Layout

Each player gets their own arena positioned in a grid layout. Arenas are spaced far enough apart to prevent visual interference but close enough for the camera to potentially show neighbors. Each arena has a base platform, invisible walls (to prevent block drift), and a skybox that allows towers to grow very tall.

### 5.2 Camera System

- **Isometric view:** Fixed 45° angle with 45° rotation, creating a classic isometric perspective
- **Orthographic-style:** Low field of view (15°) creates a flat, orthographic-like projection where blocks don't change size based on distance
- **Smooth tracking:** Camera smoothly interpolates upward as tower grows, always showing top blocks
- **Game over sequence:**
  1. Screen fades to black
  2. Camera repositions at tower base
  3. Screen fades back in
  4. Camera pans from bottom to top, revealing full tower height
  5. Camera orbits around the top of the tower
- **Opponent preview:** Small picture-in-picture views of opponent towers (future feature)

### 5.3 Matchmaking

- **Public matchmaking:** Quick Play button finds available lobbies or creates new one
- **Private games:** Create private server with shareable code for friends
- **Player capacity:** 2-8 players per match

### 5.4 Spectator Mode

Eliminated players can freely spectate remaining players. Free camera controls let them fly around and watch the action. Spectators see the same UI elements showing all players' heights.

---

## 6. User Interface

### 6.1 In-Game HUD

- **Scoreboard (top-right):** Live rankings showing all players, their current height, and status (playing/eliminated)
- **Personal stats (top-left):** Your score, current combo streak, tower height
- **Combo indicator (center):** Animated popup showing "PERFECT!" and combo count (×2, ×3, etc.)
- **Opponent previews (bottom):** Miniature 3D views of opponent towers (toggleable)

### 6.2 Menu Screens

- **Main Menu:** Play (Quick/Private), Settings, Shop (future), Leaderboards
- **Lobby:** Player list, ready status, countdown timer, chat
- **Results:** Final rankings, personal stats, Play Again / Leave buttons

---

## 7. Visual Style

### 7.1 Art Direction

**Cartoonish and colorful.** Think bright, saturated colors with soft edges and playful proportions. Blocks should look chunky and satisfying. The overall vibe is cheerful and approachable - similar to games like Fall Guys or Overcooked.

### 7.2 Block Appearance

- **Rainbow gradient:** Colors smoothly interpolate through a rainbow cycle over 30 blocks using `Color3:Lerp()`. Each game starts at a random color in the gradient.
- **Foundation pillar:** A 50-stud tall pillar extends down from the base, colored to match the starting block. This grounds the tower visually and hides in the fog below.
- **Block dimensions:** 4×1×4 studs (width × height × depth)
- **Chopped debris:** Falls with Roblox physics (unanchored), automatically cleaned up after 3 seconds
- **Landing animation:** Small bounce effect when blocks land (hop up, then settle)
- **Material:** SmoothPlastic for clean, colorful appearance

### 7.3 Environment

- **Atmosphere:** Light blue fog with density concentrated at the bottom, hiding the foundation base
- **Lighting:** Bright afternoon sun (ClockTime 14) with soft ambient lighting
- **Bloom:** Subtle bloom effect for a polished look
- **Sky:** Clean daytime skybox

---

## 8. Technical Implementation

### 8.1 Project Structure

```
src/
├── client/
│   ├── init.client.luau        # Entry point, hides character, mounts React
│   ├── controllers/
│   │   ├── BlockController.luau # Client game logic, server communication
│   │   └── CameraController.luau # Camera positioning, game over effects
│   ├── input/
│   │   └── InputHandler.luau    # Unified input (click/tap/keyboard/gamepad)
│   └── components/
│       └── App.luau             # React UI root (HUD future)
├── server/
│   ├── init.server.luau         # Entry point, environment setup, RemoteEvents
│   └── services/
│       └── BlockService.luau    # Authoritative game logic, spawning, chopping
└── shared/
    ├── Types.luau               # Type definitions (BlockData, TowerData, etc.)
    ├── Constants.luau           # Game constants, color gradient, formulas
    ├── BlockFactory.luau        # Creates styled block Parts
    └── TowerState.luau          # Tower data structure helpers
```

### 8.2 Key Modules

| Module | Purpose |
|--------|---------|
| `BlockService` | Server-authoritative block spawning, swing tweens, drop handling, overlap calculation, debris spawning |
| `BlockController` | Client-side input handling, server communication, camera updates |
| `CameraController` | Isometric camera, smooth height tracking, game over pan/orbit sequence |
| `InputHandler` | Unified input binding via UserInputService + ContextActionService |
| `BlockFactory` | Creates block Parts with rainbow gradient coloring |
| `TowerState` | Tower data structure, axis toggling, height tracking |
| `Constants` | Game tuning values, `calculateSwingSpeed()`, `getBlockColor()` |

### 8.3 Chopping Algorithm

The overlap calculation uses axis-aligned bounding boxes (AABB):

```lua
function calculateLanding(tower, blockData, dropPosition)
  -- Get bounds on current swing axis
  if axis == "X" then
    droppedMin = dropPosition.X - blockData.size.X / 2
    droppedMax = dropPosition.X + blockData.size.X / 2
    baseMin = topBlock.position.X - topBlock.size.X / 2
    baseMax = topBlock.position.X + topBlock.size.X / 2
  end

  overlapMin = math.max(droppedMin, baseMin)
  overlapMax = math.min(droppedMax, baseMax)
  overlapSize = overlapMax - overlapMin

  if overlapSize <= 0 then
    return { eliminated = true }  -- Complete miss
  end

  local isPerfect = math.abs(droppedCenter - baseCenter) <= 0.5
  -- Return new block size = overlap region
end
```

### 8.4 Network Architecture

**Server-authoritative model:**
- Server owns all game state (tower data, block positions)
- Server runs swing tweens and calculates landing results
- Clients send `RequestDrop` RemoteEvent on input
- Server responds with `BlockDropped` (result) and `BlockSpawned` (next block)
- Client handles visuals only (camera, UI)

**RemoteEvents:**
- `RequestDrop` - Client → Server: Player wants to drop current block
- `BlockDropped` - Server → Client: Landing result (success, position, size, isPerfect, eliminated)
- `BlockSpawned` - Server → Client: New block data (id, size, axis, speed)
- `GameStateUpdate` - Server → Client: Score/state sync (future)

---

## 9. Polish & Juice

### 9.1 Visual Effects (Implemented)

- **Block landing:** Small bounce animation (hop up, then settle with easing)
- **Chopped debris:** Falls with Roblox physics, auto-cleanup after 3 seconds
- **Game over camera:** Cinematic pan from base to top, then orbit around tower top
- **Screen fade:** Smooth black fade transition for game over sequence

### 9.2 Visual Effects (Planned)

- **Perfect stack:** Golden particle burst, screen flash, block briefly glows
- **Block landing:** Dust particles on impact
- **Elimination:** Tower crumbles dramatically, camera shake

### 9.3 Sound Effects (Planned)

- **Block drop:** Satisfying "thunk" sound
- **Perfect stack:** Ascending chime (pitch increases with combo)
- **Partial stack:** Neutral tap sound
- **Miss:** Buzzer/fail sound
- **Background music:** Upbeat, gradually intensifies as game progresses

### 9.4 UI Effects (Planned)

- **Combo text:** Animated "PERFECT!" with scaling combo number
- **Speed warning:** Subtle vignette or color shift when speed gets high
- **Victory celebration:** Confetti, fireworks, winner spotlight

---

## 10. Future Additions (Post-MVP)

### 10.1 Monetization

- **Block skins:** Themed block appearances (neon, wood, candy, space, etc.)
- **Trail effects:** Particle trails on falling blocks
- **Victory animations:** Custom celebrations when winning
- **VIP game pass:** 2× coins, exclusive skins, create private servers

### 10.2 Game Modes

- **Time Attack:** Highest tower in 60 seconds
- **Zen Mode:** No elimination, practice at your own pace
- **Tournament:** Bracket-style elimination across multiple rounds
- **Daily Challenge:** Special modifiers, leaderboard resets daily

### 10.3 Social Features

- **Global leaderboard:** All-time high scores
- **Friends leaderboard:** Compare with friends
- **Achievements:** Badges for milestones (100 wins, 50-block tower, etc.)
- **Replay system:** Watch and share best runs

---

## Development Checklist

### Phase 1: Core Mechanics (MVP) ✅
- [x] Block spawning and swing movement
- [x] Alternating axis logic (X ↔ Z)
- [x] Drop on input (click/tap/space/E/gamepad)
- [x] Overlap calculation (AABB)
- [x] Block chopping/resizing
- [x] Falling debris with physics
- [x] Elimination on complete miss
- [x] Landing bounce animation
- [ ] Basic scoring
- [ ] Combo system

### Phase 1.5: Visual Polish ✅
- [x] Rainbow gradient colors (smooth interpolation over 30 blocks)
- [x] Random starting color per game
- [x] Foundation pillar (50 studs, extends down)
- [x] Isometric camera (45°/45°)
- [x] Orthographic-style low FOV (15°)
- [x] Smooth camera height tracking
- [x] Game over camera sequence (fade → pan up → orbit)
- [x] Atmosphere/fog at bottom
- [x] Bloom effect
- [x] Clean sky and lighting
- [x] Character hidden and anchored

### Phase 2: Multiplayer
- [ ] Multiple arenas (grid layout)
- [ ] Player assignment to arenas
- [ ] Synchronized game start
- [ ] Real-time height tracking across players
- [ ] Elimination handling
- [ ] Victory detection (last standing)
- [ ] Spectator mode

### Phase 3: UI/UX
- [ ] Main menu
- [ ] Lobby system
- [ ] In-game HUD (score, combo, height)
- [ ] Results screen
- [ ] Matchmaking

### Phase 4: Audio & Effects
- [ ] Block drop sound
- [ ] Perfect stack chime
- [ ] Partial stack sound
- [ ] Miss/fail sound
- [ ] Background music
- [ ] Perfect stack particles
- [ ] Elimination effects

### Phase 5: Launch
- [ ] Testing & bug fixes
- [ ] Performance optimization
- [ ] Thumbnails & marketing
- [ ] Publish
