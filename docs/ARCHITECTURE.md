# 🐛 Caterpillar Escape – Architecture

This document describes the technical structure of the Caterpillar Escape game.

Engine: Godot 4.x
Language: GDScript

---

## Project Folder Structure

caterpillar_escape/
│
├── assets/
│   ├── characters/
│   ├── tiles/
│   ├── obstacles/
│   ├── collectibles/
│   └── ui/
│
├── scenes/
│   ├── MainMenu.tscn
│   ├── Level.tscn
│   ├── Caterpillar.tscn
│   ├── Leaf.tscn
│   ├── Spider.tscn
│   └── ExitPortal.tscn
│
├── scripts/
│   ├── game_manager.gd
│   ├── caterpillar.gd
│   ├── segment.gd
│   ├── leaf.gd
│   ├── spider.gd
│   └── exit_portal.gd
│
├── levels/
│   ├── level_01.tscn
│   ├── level_02.tscn
│   └── level_03.tscn
│
└── docs/
    ├── GAME_DESIGN.md
    └── ARCHITECTURE.md

---

## Scene Architecture

MainMenu
 ├── Background
 ├── TitleLabel
 ├── PlayButton
 ├── SettingsButton
 └── QuitButton

Purpose:
Start the game and load the first level.

---

## Level Scene

Level
 ├── TileMap
 ├── Caterpillar
 ├── Objects
 │   ├── Leaves
 │   ├── Spiders
 │   └── Mushrooms
 ├── ExitPortal
 └── UI

Responsibilities:
- Manage level state
- Detect completion
- Spawn objects

---

## Caterpillar Scene

Caterpillar
 ├── Head
 ├── BodySegments
 └── Tail

Script: caterpillar.gd

Responsibilities:
- Movement
- Growth
- Body follow logic
- Collision detection

---

## Movement System

Grid-based movement.

Example grid size:
tile_size = 64

Movement process:
1. Player presses direction
2. Head moves one grid tile
3. Previous head position stored
4. Body segments follow previous positions

---

## Collectibles

Leaf Scene

Leaf
 ├── Sprite2D
 └── CollisionShape2D

Signal used:
body_entered

Effect:
player.grow()

---

## Exit Portal

ExitPortal
 ├── Sprite
 └── CollisionShape

States:
closed
open

Open condition:
if leaves_remaining == 0

---

## Game Manager

Script: game_manager.gd

Responsibilities:
- Level loading
- Score tracking
- Restart logic
- Progression

Example functions:
load_level(level_id)
restart_level()
level_complete()

---

## TileMap System

Maze built with TileMap.

Tile types:
- ground
- hedge_wall
- corner_wall
- junction_wall

Tile size: 64x64

Walls use collision.

---

## UI System

UI Elements:
- Timer
- Leaf counter
- Pause button
- Restart button

Uses CanvasLayer.

---

## Future Systems

- Procedural maze generation
- Daily maze challenge
- Caterpillar skins
- Butterfly transformation levels

---

## Development Goals

1. Smooth grid movement
2. Satisfying body following
3. Cute animation style
4. Fast level creation
