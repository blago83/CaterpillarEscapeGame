# Caterpillar Escape - Godot Prototype

A portrait 3D caterpillar maze game for Godot 4.

## How to play
**Goal:** eat the fruit, then crawl into the glowing finish gate, set into the top wall near the right corner.

- The green banner at the top always shows the current goal ("GOAL: Eat 3 more fruits", then "GOAL: Crawl into the glowing portal!").
- A floating arrow above the caterpillar points to the nearest fruit (yellow), then to the open portal (green).
- The finish gate is barred shut until the goal is met; the bars lift and it glows once you can go through.
- Each level opens with a short card that explains the goal, the star time and new hazards. The timer and spiders wait until you start.
- Stars: 1 for escaping, +1 for beating the star time, +1 for never getting hurt. The win screen tells you how to get the missing stars.

## Features
- Clean, flat look: solid garden colours, simple rounded blocks (green bushes, grey rocks), no textures and no fog, so the whole maze is visible
- Turning bush rings (level 7): square, orange rings of bushes sit in a clearing inside a maze. Each ring steps one cell at a time like a conveyor belt; wait until the gaps line up, then crawl in and out again. Arrows on the blocks show which way each ring moves, the floor under every gap glows, and when gaps in two rings line up across the track the whole passage pulses blue with a chime (rings next to you tick as they step). If you wait inside a gap, the ring carries you along (crawl out whenever you like). Rings never stop, so you can't get trapped. Biting a ring holds it still for a moment, and three bites chew a new gap
- Fruit objectives (some levels ask for specific fruit types)
- Combos: eat fruit quickly in a row for double points and a speed boost
- Golden fruit drops near the caterpillar every few seconds; grab it before it fades for +500 and a speed boost
- Spiders that hunt you when you come close (with a warning pop-up), spikes that shorten you, mushrooms that make you dizzy
- Bite through bushes (rocks cannot be bitten), wormholes and sneakers
- Score, timer and fruit progress in the HUD; short pop-up messages explain what just happened

## Level picker
On the main menu, **Choose Level** lists every level so you can jump straight into any of them.

## Controls
- Keyboard: Arrow keys or WASD to crawl, Space to bite a bush
- Mobile: swipe, or use the on-screen arrow pad and BITE button

## Open in Godot
1. Open Godot 4.6
2. Import `project.godot`
3. Run the project

## Regression checks
Run these commands from the project directory:

```
godot --headless --path . --script res://tests/caterpillar_camera_test.gd
godot --headless --path . --script res://tests/walking_audio_test.gd
godot --headless --path . --script res://tests/gameplay_goals_test.gd
godot --headless --path . --script res://tests/spin_rings_test.gd
godot --headless --path . --script res://tests/level_picker_test.gd
```

## Level editing
Edit the `LEVELS` array in `scripts/level_3d.gd`.

Legend:
- `#` wall (bush or rock)
- `.` empty path
- `L` fruit
- `S` spider (spiders placed close to the start are moved away automatically)
- `^` spikes
- `P` player start
- `E` ignored; the finish gate is always a doorway in the top wall near the right corner

### Bush shapes
`scripts/bush_shapes.gd` generates wall formations from small specs, so shapes do not have to be drawn by hand. Add them per level in `LEVEL_FORMATIONS` (keyed by level index) in `scripts/level_3d.gd`:

```gdscript
{"shape": "diamond", "at": Vector2i(5, 26), "radius": 2}                  # bush (biteable) by default
{"shape": "line", "at": Vector2i(1, 15), "to": Vector2i(3, 15), "wall": "rock"}
{"shape": "pattern", "at": Vector2i(2, 3), "rows": ["#.#", ".#.", "#.#"]}
{"shape": "rect", "at": Vector2i(4, 4), "size": Vector2i(3, 2), "carve": true}  # clears cells instead
```

Shapes: `line`, `rect` (filled), `box` (hollow), `disc`, `ring` (with `gaps` in degrees), `arc`, `cross`, `diamond`, `spiral`, `zigzag`, `pattern`. Angles start at the right and go clockwise on screen. Formations never cover the start, the portal area, fruit or hazards.

### Spinning rings
Add rings in `LEVEL_SPINNERS`. Each group has a centre cell and a list of rings:

```gdscript
{"at": Vector2i(10, 15), "rings": [
	{"size": 2, "dir": 1, "step_time": 0.5, "gaps": [2, 10], "gap_cells": 2},
	{"size": 4, "dir": -1, "step_time": 0.7, "gaps": [3, 14, 25], "gap_cells": 2},
]}
```

`size` is the ring's distance from the centre in cells (a size-2 ring is a 5x5 square). Keep sizes 2 apart (2, 4, 6) so there is a 1-cell track between rings. `dir` is 1 for clockwise and -1 for anticlockwise, `step_time` is the number of seconds per one-cell step, and `gaps` are positions along the ring counted clockwise from the top-left corner (a ring has `8 * size` cells). `gap_cells` is the gap width and `start` sets the starting offset. Put gaps on the sides, not the corners, so they line up with the tracks. `LEVEL_OPTIONS` turns off random spikes, wormholes, wide roads or mushrooms for a level.

## Good next upgrades
- Add dedicated sprite art for leaf, spider, and exit portal
- Add animation frames for head/body wiggle
- Add sound effects and juice
- Convert the maze to a TileMap
- Add world map and shop

## Copilot prompt starter
"Expand this Godot 4 project into a polished mobile puzzle game. Keep the caterpillar segmented, preserve the grid movement, add smooth tweened movement, a level select screen, stars, coins, skins, and a better TileMap pipeline using the existing art folder."