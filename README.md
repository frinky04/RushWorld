![image](https://github.com/user-attachments/assets/98da0263-f4d8-4904-9895-ba78f0b3e8a0)

# RushWorld

A colony survival game inspired by RimWorld, built with **Love2D** and **Lua**. The twist: shorter, roguelike-style runs where you manage a group of "dudes" and try to survive as long as possible.

## Features

- Grid-based world (64x64) with A* pathfinding
- Dude AI with brain states (idle, wandering, finding food, working)
- Resource gathering (wood, stone, berries)
- Building and construction system
- Health, hunger, and needs simulation
- Camera panning and zoom
- Time scaling (1x, 2x, 8x, 32x)
- Ambient sound and SFX
- Dead simple pixel art style

## Running

Requires [Love2D](https://love2d.org/).

```
love .
```

Or use the included `run.bat`.

## Controls

| Key | Action |
|-----|--------|
| Middle mouse drag | Pan camera |
| Scroll wheel | Zoom in/out |
| Space | Place wall at cursor |
| C | Spawn dude at cursor |
| X | Destroy/damage entity at cursor |
| 1-4 | Set time scale (1x, 2x, 8x, 32x) |

## Project Structure

```
src/
├── core/           Engine (entity, component, world, util, shaders, sounds)
├── components/     Reusable components (sprite, collision, AI movement, text)
├── game/           Game-specific components and setup functions
│   └── dudes/      Dude AI, brain, and manager
├── libs/           Third-party (astar, flux, heap, vector)
└── benchmarks/     Performance benchmarks
assets/
├── sprites/        Entity sprites and clothing
├── sounds/         Ambience, music, and SFX
├── fonts/          Oxanium font family
└── ui/             UI elements
```

## Architecture

Custom ECS (Entity-Component-System) with two update loops:
- `update(dt)` — fixed timestep tick (every 0.2s) for game logic
- `tick(dt)` — every frame for rendering and smooth animation

Components extend a base `Component` class and can override `start()`, `update(dt)`, `tick(dt)`, `draw()`, and `destroy()`. Entities are configured via setup functions (e.g. `setup_tree`, `setup_dude`, `setup_wall`).

## Status

Learning project — actively in development.
