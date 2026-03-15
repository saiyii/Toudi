# Toudi

Toudi is a 2D sandbox game inspired by Terraria, built from scratch with LOVE (Love2D).  
You can explore an infinite world, dig and place blocks, and see procedural terrain with trees.

## Current Features
- Infinite horizontal world with chunks and noise-based terrain.
- Procedural trees (wood + leaves) that render as background.
- Collision, gravity, jump (with coyote time + jump buffer), and Terraria-like movement friction.
- Dig and place blocks with reach limit and durability-based break time.
- Procedural pixel textures (no external images required).

## Controls
- Toggle layout: `F1` (AZERTY <-> QWERTY)
- Move left/right: `Q/D` (AZERTY) or `A/D` (QWERTY) or `Left/Right`
- Jump: `Z` (AZERTY) or `W` (QWERTY) or `Up` or `Space`
- Dig: Left click
- Place block: Right click

## Requirements
- LOVE (Love2D) 11.x or newer

## How To Run (Windows)
1. Install LOVE from the official site:
```
https://love2d.org/
```
2. Open PowerShell and run:
```
cd <your-path>\Toudi
& "C:\Program Files\LOVE\love.exe" .
```

## How To Run (macOS)
1. Install LOVE:
```
https://love2d.org/
```
2. Run from Terminal:
```
cd /path/to/Toudi
open -n -a love .
```

## How To Run (Linux)
1. Install LOVE with your package manager.
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
