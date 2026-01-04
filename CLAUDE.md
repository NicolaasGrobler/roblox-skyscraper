# Tutorial - Roblox Game Project

## Preferences
- Do not mention Claude or AI in git commits, PR descriptions, or code comments

## Overview
This is a Roblox game project using modern external tooling for development. The game is developed outside of Roblox Studio using Luau files, then synced to Studio via Rojo.

## Toolchain
Managed via **Rokit** (toolchain manager for Roblox projects):
- **Rojo v7.6.1** - Syncs external files to Roblox Studio in real-time
- **Wally v0.3.2** - Package manager for Roblox (like npm for Roblox)
- **wally-package-types v1.6.2** - Generates type definitions for Wally packages
- **Selene** - Lua/Luau linter (config in selene.toml)

## Project Structure
```
src/
├── client/          → StarterPlayer.StarterPlayerScripts.Client
│   ├── init.client.luau   (entry point - mounts React app)
│   └── components/        (React components)
│       ├── App.luau       (root component)
│       └── MainFrame.luau (reusable UI components)
├── server/          → ServerScriptService.Server
│   └── init.server.luau   (runs on the server)
├── shared/          → ReplicatedStorage.Shared
│   └── Hello.luau         (modules accessible by both client and server)
└── stories/         → ReplicatedStorage.Stories (UI Labs stories)
    ├── Storybook.storybook.luau  (storybook config)
    └── *.story.luau              (component stories)

Packages/            → ReplicatedStorage.Packages (Wally shared packages)
DevPackages/         → ReplicatedStorage.DevPackages (Wally dev packages)
ServerPackages/      → ServerScriptService.ServerPackages (Wally server-only packages)
```

## File Naming Conventions
- `*.client.luau` - Client scripts (run on player's machine)
- `*.server.luau` - Server scripts (run on Roblox servers)
- `*.luau` - Modules (can be required by other scripts)
- `init.*.luau` - Entry point for a folder (folder becomes the module)

## Common Commands
```bash
# Build the place file
rojo build -o "Tutorial.rbxlx"

# Start live sync server (connect from Studio with Rojo plugin)
rojo serve

# Install Wally packages
wally install

# Generate types for installed packages
wally-package-types --sourcemap sourcemap.json Packages/
```

## Development Workflow
1. Edit `.luau` files in this directory
2. Run `rojo serve` to start the sync server
3. Open Roblox Studio and connect via the Rojo plugin
4. Changes sync automatically to Studio
5. Test in Studio (F5 to play)

## Adding Packages
1. Find packages at https://wally.run
2. Add to `wally.toml` under `[dependencies]` or `[server-dependencies]`
3. Run `wally install`
4. Require via `require(ReplicatedStorage.Packages.PackageName)`

## React UI (jsdotlua/react-lua)

### Packages
- `React` - Core React library (createElement, hooks, etc.)
- `ReactRoblox` - Roblox-specific renderer (createRoot, createPortal)

### Project Structure
```
src/client/
├── init.client.luau       # Entry point - mounts React app
└── components/
    └── App.luau           # Root component
```

### Creating Components
Components are functions that return React elements:

```luau
local React = require(ReplicatedStorage.Packages.React)

local function MyComponent(props)
    return React.createElement("TextLabel", {
        Text = props.text,
        Size = UDim2.fromScale(1, 1),
    })
end

return MyComponent
```

### Mounting the App
```luau
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local App = require(script.components.App)

-- Create container (React takes ownership, don't use PlayerGui directly)
local container = Instance.new("Folder")
container.Parent = playerGui

local root = ReactRoblox.createRoot(container)
root:render(React.createElement(App))
```

### Common Patterns

**Event handling:**
```luau
React.createElement("TextButton", {
    [React.Event.MouseButton1Click] = function(rbx)
        print("Clicked!")
    end,
})
```

**Using hooks:**
```luau
local function Counter()
    local count, setCount = React.useState(0)

    return React.createElement("TextButton", {
        Text = "Count: " .. count,
        [React.Event.MouseButton1Click] = function()
            setCount(count + 1)
        end,
    })
end
```

**Children with keys:**
```luau
React.createElement("Frame", {}, {
    Header = React.createElement("TextLabel", { Text = "Header" }),
    Body = React.createElement("TextLabel", { Text = "Body" }),
})
```

### Best Practices
- One component per file in `src/client/components/`
- Use PascalCase for component names
- Keep components small and focused
- Use `ResetOnSpawn = false` on ScreenGuis to persist UI across respawns

## UI Labs (Component Storybook)

UI Labs is a Storybook-like plugin for visualizing and testing React components in isolation.

### Setup
1. Install the UI Labs plugin in Roblox Studio
2. Stories are in `src/stories/` and sync to `ReplicatedStorage.Stories`
3. Open the UI Labs widget in Studio to browse components

### File Naming
- `*.storybook.luau` - Storybook configuration (defines where to find stories)
- `*.story.luau` - Individual component stories

### Creating a Story
```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local MyComponent = require(StarterPlayer.StarterPlayerScripts.Client.components.MyComponent)

local controls = {
    text = "Default text",      -- String control
    visible = true,             -- Boolean control
    count = 5,                  -- Number control
}

local story = {
    react = React,
    reactRoblox = ReactRoblox,
    controls = controls,
    story = function(props)
        return React.createElement(MyComponent, {
            text = props.controls.text,
            visible = props.controls.visible,
        })
    end,
}

return story
```

### Controls
Controls appear in UI Labs and let you tweak props in real-time:
- `string` - Text input
- `boolean` - Checkbox toggle
- `number` - Number slider
- `Color3` - Color picker

### Best Practices
- Create a story for each reusable component
- Keep components independent of ScreenGui (pass props instead)
- Use controls to test different states and edge cases
