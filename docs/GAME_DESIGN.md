# 🐛 Caterpillar Escape

## Game Overview
Caterpillar Escape is a cute puzzle-maze game where the player controls a caterpillar wearing tiny shoes that must escape garden mazes.

The player navigates through a maze, collects leaves, grows longer, avoids obstacles, and reaches the exit portal.

Engine: Godot 4.x
Language: GDScript
Platform targets: Android, iOS, Desktop

---

## Core Gameplay

### Goal
Reach the exit portal in each level.

Conditions:
- Collect required leaves
- Avoid traps
- Navigate the maze

When the caterpillar reaches the exit, the level is complete.

---

## Movement System

Movement is grid-based.

Controls:
- Swipe (mobile)
- Arrow keys (desktop)

Rules:
- The head moves first
- Each body segment follows the previous position
- Similar to classic snake mechanics

Example:

Before move
H B B B

After move
. H B B B

---

## Caterpillar Growth

Collectible: 🍃 Leaf

Effects:
- Adds one body segment
- Makes navigation more challenging
- Enables puzzle mechanics

---

## Level Structure

Levels contain:

- Maze walls
- Leaves
- Obstacles
- Exit portal

Example layout:

#########
#S  L  E#
# ### ###
#       #
#########

Legend:
S = Start
L = Leaf
E = Exit

---

## Obstacles

Spider
- Causes level restart on contact

Spider Web
- Slows movement

Poison Mushroom
- Shrinks the caterpillar

Water Puddle
- Slides the player one extra tile

---

## Exit Portal

The exit portal begins closed.

Condition to open:
- All leaves collected

When open:
- Portal glows
- Player can enter to finish level

---

## Level Completion

Completion screen shows:

LEVEL COMPLETE
⭐ ⭐ ⭐

Stars based on:
- Time
- Leaves collected
- Mistakes

---

## Visual Style

Art style:
- Bright
- Cartoon
- Friendly

Main character:
Green caterpillar with tiny red shoes.

Animations:
- Body wiggle
- Shoe steps
- Blinking eyes

---

## Future Mechanics

Potential expansions:
- Switches and gates
- Teleport holes
- Moving maze walls
- Caterpillar → cocoon → butterfly transformation

---

## Summary

Caterpillar Escape is a casual puzzle maze game focused on:

- Simple controls
- Clever maze puzzles
- Charming visuals
- Satisfying caterpillar movement
