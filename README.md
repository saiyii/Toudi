# Toudi

Toudi is a 2D sandbox game inspired by Terraria, built from scratch with LÖVE (Love2D).  
You can explore an infinite world, dig and place blocks, and see procedural terrain with trees.

## Current Features
- Infinite horizontal world with chunks and noise-based terrain.
- Procedural trees (wood + leaves) that render as background.
- Collision, gravity, jump (with coyote time + jump buffer).
- Dig and place blocks.
- Procedural pixel textures (no external images required).

## Controls
- Toggle layout: `F1` (AZERTY <-> QWERTY)
- Move left/right: `Q/D` (AZERTY) or `A/D` (QWERTY) or `Left/Right`
- Jump: `Z` (AZERTY) or `W` (QWERTY) or `Up` or `Space`
- Dig: Left click
- Place block: Right click

## Requirements
- LÖVE (Love2D) 11.x or newer

## How To Run (Windows)
1. Install LÖVE from the official site:
```
https://love2d.org/
```
2. Open PowerShell and run:
```
cd d:\repos\Terra2D\toudi
& "C:\Program Files\LOVE\love.exe" "d:\repos\Terra2D\toudi"
```

## How To Run (macOS)
1. Install LÖVE:
```
https://love2d.org/
```
2. Run from Terminal:
```
cd /path/to/Toudi
open -n -a love .
```

## How To Run (Linux)
1. Install LÖVE with your package manager.
2. Run:
```
cd /path/to/Toudi
love .
```

## Project Structure
- `main.lua`: main game loop, world generation, player logic, rendering
- `assets/`: optional assets (not required for current version)

## Roadmap (Next)
- Inventory + hotbar
- Crafting system
- Enemies + basic combat
- Saving/loading world edits

## Notes
This README is a starting point and will evolve as the game grows.
