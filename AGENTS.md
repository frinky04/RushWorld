# Agent Instructions

> Start here: read `STRUCTURE.md` before making code changes. It has the current file map, engine flow, and the important globals this project relies on. If your work changes architecture or code organization, update `STRUCTURE.md` too.

## Runtime
- Love2D game built with Lua
- Run: `love .` or `run.bat`
- Entry points: `main.lua`, `conf.lua`

## Validation
- There is no formal automated test suite in this repo.
- Validate changes by running the game and exercising the affected systems in-engine.
- If you touch AI, pathfinding, movement, or construction, test at multiple time scales (`1`, `2`, `8`, `32`) because logic runs on a fixed step and visuals run per-frame.

## Architecture
- Custom ECS in `src/core/`: `Entity`, `Component`, `World`
- Entities are usually created with `Entity:new(x, y, name, setup_fn)` and configured through setup functions in `src/game/setup_functions.lua`
- Components inherit from `Component` and typically override `start()`, `update(dt)`, `tick(dt)`, `draw()`, and `destroy()`
- `world` is the main singleton for entity lifecycle, camera, A* navigation grid, time scale, and rendering order

## Project Layout
```text
src/core/         Engine primitives, world state, utilities, shaders, sounds
src/components/   Generic reusable components like sprite, collision, movement, text
src/game/         Game-specific components and entity setup functions
src/game/dudes/   Colonist AI, brain logic, manager, and action modules
src/libs/         Third-party libraries: astar, heap, vector, flux
assets/           Sprites, fonts, sounds, icon, and UI art
```

## Key Constants
| Constant | Value |
|----------|-------|
| `GRID_SIZE_PX` | `16` |
| `GRID_SIZE` | `64` |
| `UPDATE_TIME` | `0.2` |

## Code Conventions
- Entity `x` and `y` are grid coordinates, not pixel coordinates. Convert with `GRID_SIZE_PX` when you need render-space positions.
- The update loop names are backwards from common engine conventions: `update(dt)` is the fixed-step game logic pass, while `tick(dt)` runs every frame for visuals and smoothing.
- `main.lua` intentionally loads many globals (`world`, component classes, setup functions, utility helpers). Follow the existing pattern, but avoid introducing accidental new globals through typos or one-off names.
- Prefer entity setup functions for composition instead of scattering ad hoc component wiring across unrelated files.
- Dude actions in `src/game/dudes/dude_actions/` are plain tables, not classes. Per-action scratch state belongs in `brain.action_state`.
- If you register a death callback on `HealthComponent`, store the callback id and unregister it in `destroy()` when the owner can be removed independently.

## Working Notes
- `main.lua` is the gameplay bootstrap: global imports, world creation, initial spawns, Love callbacks, debug spawn/destruction hotkeys
- `src/core/world.lua` is the main integration point for camera movement, entity queries, navigation refresh, and rendering order
- `src/game/setup_functions.lua` is the source of truth for how world objects are assembled
- `TODO.md` tracks known technical debt and scaling issues; keep it current when you uncover new systemic problems