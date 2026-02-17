# Agent Instructions

## Runtime
- **Love2D** game engine with **Lua**
- Run: `love .` or `run.bat`
- Config: `conf.lua`

## Commit Attribution
AI commits MUST include:
```
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

## Architecture
- Custom ECS: `Entity`, `Component`, `World` in `src/core/`
- Components extend `Component` base class — override `start()`, `update(dt)`, `tick(dt)`, `draw()`, `destroy()`
- Entities created via `Entity:new(x, y, name, setup_fn)` — setup functions in `src/game/setup_functions.lua`
- World manages entity lifecycle, grid, camera, and rendering

## Project Structure
```
src/core/         — Engine: entity, component, world, util, shaders, sounds
src/components/   — Generic reusable components (sprite, collision, AI movement, text)
src/game/         — Game-specific components and setup functions
src/game/dudes/   — Dude AI, brain, and manager components
src/libs/         — Third-party: astar, flux (tweening), heap, vector
assets/           — Sprites, fonts, sounds
```

## Key Constants (main.lua)
| Constant | Value |
|----------|-------|
| `GRID_SIZE_PX` | 16 |
| `GRID_SIZE` | 64 |
| `UPDATE_TIME` | 0.2 |

## Conventions
- Components are classes returned via `require` and assigned to globals (e.g., `SpriteComponent = require(...)`)
- Setup functions (e.g., `setup_rock`, `setup_tree`) configure entities with components
- Grid-based positioning: entity `x, y` are grid coords, not pixels
- Two update loops: `update(dt)` (every frame), `tick(dt)` (fixed timestep at `UPDATE_TIME`)
- Use `hexToRGBA()` from `src/core/util.lua` for colors
