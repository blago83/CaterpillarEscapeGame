# Caterpillar Escape - Godot Prototype

This is a small but playable Godot 4 prototype for your caterpillar maze game.

## What's included
- Cute built-in placeholder art with shoes
- Main menu
- 3 prototype levels
- Grid movement
- Caterpillar body growth when collecting leaves
- Exit opens when all leaves are collected
- Spider and mushroom hazards
- Swipe support + keyboard support
- Easy-to-edit level arrays inside `scripts/level.gd`

## Controls
- Keyboard: Arrow keys or WASD
- Mobile: swipe in the direction you want to move

## Open in Godot
1. Extract the zip
2. Open Godot 4.x
3. Import `project.godot`
4. Run the project

## Level editing
Edit the `LEVELS` array in `scripts/level.gd`

Legend:
- `#` hedge wall
- `.` empty dirt path
- `L` leaf collectible
- `S` spider hazard
- `M` mushroom hazard
- `E` exit
- `P` player start

## Good next upgrades
- Replace placeholder art with higher-res sprite sheets
- Add animation frames for head/body wiggle
- Add sound effects and juice
- Convert the maze to a TileMap
- Add world map, star scores, and shop

## Copilot prompt starter
"Expand this Godot 4 project into a polished mobile puzzle game. Keep the caterpillar segmented, preserve the grid movement, add smooth tweened movement, a level select screen, stars, coins, skins, and a better TileMap pipeline using the existing art folder."