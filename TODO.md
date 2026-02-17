# TODO — Known Technical Debt

## High Priority

### Global namespace pollution
Every component class, setup function, and utility is a global defined in `main.lua`. A typo like `SpriteComponet` silently evaluates to `nil` instead of erroring. Two files defining the same name silently overwrite each other. Consider using a module registry or at minimum `strict.lua` to catch undefined global access.

### `is_valid()` usage is inconsistent
Some places use `if is_valid(x)`, others use `if is_valid(x) == false`, others use bare `if x then`. The `== false` pattern is subtly wrong — `is_valid(nil)` returns `nil`, and `nil == false` is `false` in Lua, so the branch is skipped. It works by accident because both are falsy, but it's a landmine. Pick one idiom and use it everywhere.

## Medium Priority

### `update()` / `tick()` naming is backwards
In most engines, "tick" = fixed timestep, "update" = per-frame. Here it's the opposite — `update(dt)` is the fixed 0.2s step and `tick(dt)` runs every frame. Confusing for anyone new to the codebase.

### Death callbacks have no unregister mechanism
`HealthComponent:register_death_callback(fn, ctx)` stores a raw function + context. If the owning component is destroyed before the entity dies, the callback fires on a dead component. There's no way to unregister a callback either.

### No zombie entity protection
`entity:destroy()` sets `is_valid = false` but other entities may still hold references. The `is_valid()` guard works but is purely opt-in — miss one check and you're indexing a destroyed entity with stale data.

## Low Priority (Scaling Concerns)

### `setup_functions.lua` is monolithic
Every entity type lives in one file. As entity variety grows this becomes a merge-conflict magnet. Could split into per-category files (e.g. `setup_resources.lua`, `setup_buildings.lua`, `setup_dudes.lua`).

### `world:refresh_nav_collision()` rebuilds every tick
Iterates all entities with CollisionComponent and rebuilds the entire walkability grid from scratch every 0.2s. O(n) per fixed update. Fine now, will bottleneck with hundreds of entities. Could dirty-flag tiles and only update on change.

### A* recomputed every move step
`ai_mover_component` runs a full A* pathfind every time the move timer fires instead of caching the path and following it. With multiple dudes this stacks up. Could cache paths and only recompute when the goal changes or the path is blocked.
