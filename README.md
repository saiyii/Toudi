# Toudi

Toudi is a 2D sandbox game inspired by Terraria, built from scratch with LÖVE (Love2D).  
You can explore an infinite world, dig and place blocks, and see procedural terrain with trees.

## Current Features
- Infinite horizontal world with chunks and noise-based terrain.
- Procedural trees (wood + leaves) that render as background.
- Collision, gravity, jump (with coyote time + jump buffer), and Terraria-like movement friction.
- Dig and place blocks with reach limit and durability-based break time.
- Inventory + hotbar (1-9) with basic counts.
- Inventory window (toggle with `I`) with a Minecraft-like grid + hotbar row; click to assign items to the selected hotbar slot.
- Crafting UI (3x3) with 20 recipes.
- Friendly mobs (bring food and avoid you) + hostile mobs (chase and hurt you).
- Health + hunger bars, with food you can eat instantly.
- Basic combat: click a mob to hit it (within range).
- Save/load world edits (F5/F9).
- Procedural pixel textures for all tiles (no external images required).

## Controls
- Toggle layout: `F1` (AZERTY <-> QWERTY)
- Open/close crafting: `E`
- Open/close inventory: `I` (click an item to assign it to the selected hotbar slot)
- Hotbar select: `1` to `9`
- Move left/right: `Q/D` (AZERTY) or `A/D` (QWERTY) or `Left/Right`
- Jump: `Z` (AZERTY) or `W` (QWERTY) or `Up` or `Space`
- Attack mob: Left click on it (within range)
- Eat food: `F` (when food is selected in the hotbar)
- Dig: Left click (hold to break)
- Place block: Right click
- Save: `F5`
- Load: `F9`

## Crafting (3x3 ASCII)
Legend: `W`=Wood, `P`=Planks, `K`=Stick, `D`=Dirt, `S`=Stone

1. Planks x4
```
[ ][ ][ ]
[ ][W][ ]
[ ][ ][ ]
```
2. Sticks x4
```
[ ][P][ ]
[ ][P][ ]
[ ][ ][ ]
```
3. Crafting Table x1
```
[P][P][ ]
[P][P][ ]
[ ][ ][ ]
```
4. Chest x1
```
[P][P][P]
[P][ ][P]
[P][P][P]
```
5. Furnace x1
```
[S][S][S]
[S][ ][S]
[S][S][S]
```
6. Wood Slab x6
```
[P][P][P]
[ ][ ][ ]
[ ][ ][ ]
```
7. Stone Brick x4
```
[S][S][S]
[ ][ ][ ]
[ ][ ][ ]
```
8. Dirt Brick x4
```
[D][D][ ]
[D][D][ ]
[ ][ ][ ]
```
9. Wood Wall x4
```
[W][W][ ]
[W][W][ ]
[ ][ ][ ]
```
10. Stone Wall x4
```
[S][S][ ]
[S][S][ ]
[ ][ ][ ]
```
11. Ladder x3
```
[ ][K][ ]
[ ][K][ ]
[ ][K][ ]
```
12. Door x3
```
[ ][P][ ]
[ ][P][ ]
[ ][P][ ]
```
13. Torch x4
```
[ ][W][ ]
[ ][K][ ]
[ ][ ][ ]
```
14. Glass x2
```
[S][ ][S]
[ ][K][ ]
[S][ ][S]
```
15. Mossy Stone x4
```
[S][ ][S]
[ ][D][ ]
[S][ ][S]
```
16. Dark Planks x6
```
[P][ ][ ]
[P][ ][ ]
[P][ ][ ]
```
17. Light Planks x6
```
[ ][ ][P]
[ ][ ][P]
[ ][ ][P]
```
18. Path x6
```
[D][D][D]
[ ][ ][ ]
[ ][ ][ ]
```
19. Brick Red x4
```
[D][ ][D]
[ ][D][ ]
[D][ ][D]
```
20. Rock x4
```
[ ][S][ ]
[S][ ][S]
[ ][S][ ]
```
```
[W][ ]    ->   4x Planks
[ ][ ]

W = Wood
```

## Requirements
- LÖVE (Love2D) 11.x or newer

## How To Run (Windows)
1. Install LÖVE from the official site:
```
https://love2d.org/
```
2. Open PowerShell in the project folder and run:
```
cd <your-path>\Toudi
& "C:\Program Files\LOVE\love.exe" .
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
- More crafting recipes
- Enemies + basic combat
- UI polish + effects

## Notes
This README is a starting point and will evolve as the game grows.
