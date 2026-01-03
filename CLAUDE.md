# Tutorial - Roblox Game Project

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
│   └── init.client.luau   (runs on each player's client)
├── server/          → ServerScriptService.Server
│   └── init.server.luau   (runs on the server)
└── shared/          → ReplicatedStorage.Shared
    └── Hello.luau         (modules accessible by both client and server)

Packages/            → ReplicatedStorage.Packages (Wally shared packages)
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
