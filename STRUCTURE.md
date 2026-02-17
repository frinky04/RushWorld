# RushWorld — Codebase Structure

Colony survival game built with **Love2D** and **Lua**. Dudes (colonists) survive on a 64x64 tile grid with Utility AI brains, A* pathfinding, and a custom ECS architecture.

---

## File Tree

```
main.lua                              Entry point. Loads globals, spawns world entities, drives Love2D callbacks.
conf.lua                              Love2D config: vsync, MSAA, resizable window, icon.

src/core/
  entity.lua                          Entity class. Holds x,y,name,components. Manages component lifecycle,
                                      collision-aware move(), y-sort via draw_priority.
  component.lua                       Base Component class. All components inherit via metatables.
                                      Stubs: update(dt), tick(dt), draw(), key_input(), destroy().
  world.lua                           World singleton. Owns entity list, A* grid, camera (lerped pos+zoom),
                                      time_scale, world_time. Entity queries, y-sorted rendering, nav refresh.
  util.lua                            Global utilities: hexToRGBA, is_valid, damage_entity, v2 math,
                                      resource/building finders, interp_to, round, map_to_range.
  shaders.lua                         GLSL shader: shader_solid_white (flash sprites white).
  sounds.lua                          Loads audio globals: am_forest_ambience, sfx_place_object, sfx_error_placing.
  spatial_sound.lua                   Empty stub — planned positional audio.

src/components/                       Generic reusable components
  sprite_component.lua                Renders Image at grid pos. Pivot, flip, tint, sprite-lerp tweening,
                                      blink effect (sine alpha), white flash shader toggle.
  collision_component.lua             Grid collision. Blocks movement, marks tiles unwalkable for A*.
  navigation_blocker_component.lua    Lightweight pathfinding-only blocker (no movement blocking).
  ai_mover_component.lua              Moves entity along A* path toward self.goal on a timer.
                                      Exposes is_at_goal(), is_at_end_of_path(), should_move flag.
  player_input_component.lua          WASD/arrow movement with cooldown. Exists but unused.
  text_component.lua                  Renders text label at entity position. Used for dude status HUD.

src/game/                             Game-specific code
  setup_functions.lua                 Entity factories: setup_tree, setup_log, setup_dude, setup_rock,
                                      setup_stone, setup_wall, setup_grass, setup_ruin, setup_berry_bush,
                                      setup_dude_corpse, setup_ruble, setup_dude_manager, etc.
  health_component.lua                HP tracking. take_damage(), die() → death callbacks → entity:destroy().
  resource_component.lua              Harvestable resource tag. Spawns dropped item entities on death.
  building_component.lua              Building under construction. Tracks required_resources, blink+flash
                                      while waiting, self-destructs when all materials delivered.
  food_component.lua                  Edible tag. Stores hunger_restored. on_eaten() destroys entity.
  sway_component.lua                  Sin-wave rotation for trees/grass. Random offset per instance.
  spawn_on_death_component.lua        On death, spawns a new entity (tree→log, ruin→ruble→stone).

src/game/dudes/                       Dude AI system
  dude_component.lua                  Core dude data: hunger, tiredness, goal, work, held item, status.
                                      Drives held-item positioning, hunger drain, death→corpse spawn.
  dude_brain_component.lua            Utility AI brain. Scores actions with trait/mood/hysteresis modifiers.
                                      Selects best action each frame. Per-dude state in brain.action_state.
  dude_manager_component.lua          Singleton on dude_manager entity. Tracks live dudes, finds free work.

  dude_actions/                       Action modules (plain tables, not classes)
    action_idle.lua                   Score 0.05. Fallback — does nothing, never completes.
    action_wander.lua                 Score 0.1. Random walk within radius 5, pause 5s on arrival.
    action_eat.lua                    Score scales with hunger urgency. Find berry bush → navigate → eat.
    action_work.lua                   Score 0.4 when work available. Multi-step: find building → find
                                      material or harvest resource → pick up → deliver.

src/libs/                             Third-party libraries
  astar.lua                           A* pathfinding on 2D grid. path() (full), rough_path() (greedy).
                                      find_closest_valid_position() for delivery spots.
  heap.lua                            Binary min-heap for A* priority queue.
  vector.lua                          2D vector with operator overloads.
  flux.lua                            Tweening library (included, not actively used).

assets/
  sprites/                            Entity sprites (16x16 pixel art). Includes clothing/ stubs.
  fonts/                              Oxanium font family (7 weights). Only Bold loaded as OXANIUM_REGULAR.
  sounds/                             Ambience WAV, SFX (place, error, chop, harvest), music MP3.
  ui/                                 logo.png, current.png (not referenced in code).
```

---

## Key Patterns

### Entity Creation
```lua
local e = Entity:new(x, y, "name", setup_function)
-- Entity:new() adds to world.entities, then calls setup_function(e)
-- setup_function adds components: SpriteComponent:new(e, ...), HealthComponent:new(e, 100), etc.
```

### Component Inheritance
```lua
local MyComp = {}
MyComp.__index = MyComp
setmetatable(MyComp, { __index = Component })

function MyComp:new(entity)
    local self = Component:new(entity)  -- auto-adds to entity.components
    setmetatable(self, MyComp)
    return self
end
```

### Two Update Loops
- **`update(dt)`** — fixed timestep (0.2s). Game logic: AI decisions, stat drain, nav refresh.
- **`tick(dt)`** — every frame. Visuals: sprite lerp, camera, sway, blink, held-item positioning.

### Grid System
- Entity `x, y` are grid coords (0–63), not pixels.
- Multiply by `GRID_SIZE_PX` (16) for pixel position.
- `entity:get_render_position()` returns lerped pixel position for smooth movement.

### Rendering
1. `world:y_sort()` — sorts by `render_ontop`, then `y`, then `draw_priority`, then creation time.
2. Push camera transform (translate + zoom).
3. Draw checkerboard background, then all entities in sorted order.
4. Pop transform, draw HUD in screen space.

### Pathfinding
- `world.astar` is a 64x64 A* grid, re-synced from collision components every `update()`.
- `AI_MovementComponent` calls `world.astar:path()` each move step.

### Dude Utility AI
```
brain:update(dt)
  → score all actions (base * trait * mood + hysteresis)
  → switch to highest scorer if different
  → action:perform(dude, brain, dt) → true means complete
```
- Per-dude scratch state lives in `brain.action_state[action.name]`, cleared on switch.
- `brain.pause_time` temporarily halts movement and evaluation.

### Death Chain
```
health <= 0 → HealthComponent:handle_death()
  → death callbacks (SpawnOnDeathComponent, ResourceComponent, DudeComponent)
  → entity:destroy() → removed from world, is_valid = false
```

### World Query Methods
| Method | Returns |
|--------|---------|
| `find_entity_by_name(name)` | First match |
| `find_nearest_entity_by_name(name, x, y)` | Closest by Manhattan distance |
| `find_entity_at(x, y)` | First entity at tile |
| `find_entities_at(x, y)` | All entities at tile |
| `find_all_entities_with_component(type)` | All with that component |

### Important Globals
- `world` — World singleton
- `dude_manager` — entity with DudeManagerComponent
- All component classes (e.g. `SpriteComponent`, `HealthComponent`, `DudeComponent`)
- All setup functions (e.g. `setup_tree`, `setup_dude`)
- Constants: `GRID_SIZE_PX`, `GRID_SIZE`, `UPDATE_TIME`, `BACKGROUND_A/B/C`
- `OXANIUM_REGULAR` (font), `shader_solid_white`, audio sources
