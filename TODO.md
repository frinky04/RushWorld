# Gameplay



# Tech Debt
-  `is_valid()` usage is inconsistent
The core ECS loops and lookups now skip invalid entities/components by default, and AI goal resolution drops invalid entity goals. There are still call sites that mix `is_valid(...)`, `is_valid_component(...)`, and bare truthiness checks. Pick one idiom per reference type and use it consistently so stale references stay obvious in review.

- `update()` / `tick()` naming is backwards
In most engines, "tick" = fixed timestep, "update" = per-frame. Here it's the opposite - `update(dt)` is the fixed `0.2s` step and `tick(dt)` runs every frasme. Confusing for anyone new to the codebase.

- Residual zombie reference risk
Destroyed entities/components now keep their metatables, `destroy()` is idempotent, and core world/entity iteration skips invalid objects. Raw field access is still not guarded, though, so stale references can still leak old coordinates or names if a caller bypasses the helper methods.
