# TODO - Known Technical Debt

## High Priority

### Global namespace pollution
Every component class, setup function, and utility is a global defined in `main.lua`. A typo like `SpriteComponet` silently evaluates to `nil` instead of erroring. Two files defining the same name silently overwrite each other. Consider using a module registry or at minimum `strict.lua` to catch undefined global access.

### `is_valid()` usage is inconsistent
The worst `is_valid(x) == false` cases have been cleaned up, but entity/component validity checks are still mixed between `is_valid(...)`, `is_valid_component(...)`, and bare truthiness checks. Pick one idiom per reference type and use it consistently so stale entity references stay obvious in review.

## Medium Priority

### `update()` / `tick()` naming is backwards
In most engines, "tick" = fixed timestep, "update" = per-frame. Here it's the opposite - `update(dt)` is the fixed `0.2s` step and `tick(dt)` runs every frame. Confusing for anyone new to the codebase.

### No zombie entity protection
`entity:destroy()` sets `is_valid = false` but other entities may still hold references. The `is_valid()` guard works but is purely opt-in - miss one check and you're indexing a destroyed entity with stale data.

## Low Priority (Scaling Concerns)

### Dirty nav refresh still rebuilds the full grid
`world:refresh_nav_collision()` now runs only when blockers change, which removes the constant per-step rebuild. It still repaints the whole walkability grid when it does run. If blocker churn gets high, move to tile-level dirty tracking instead of full-grid refreshes.

### Cached A* paths still invalidate broadly
`ai_mover_component` now caches paths and reuses them until the goal or nav version changes, but any nav rebuild invalidates the whole cached path. If moving blockers become common, path patching or more local invalidation would reduce unnecessary replans.
