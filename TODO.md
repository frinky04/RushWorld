# Gameplay

## Dude AI
- Finish Phase 1 of the colonist Utility AI before adding mood/traits/social systems.
- Fix `src/game/dudes/dude_actions/action_work.lua` so work can actually be claimed and progressed when `dude.work` starts as `nil`. Right now the action exits before assigning a job.
- Add minimum commitment / interrupt rules to `src/game/dudes/dude_brain_component.lua` so actions do not switch immediately on every slightly higher score. Keep hysteresis, but add per-action commitment windows and explicit interruptibility.
- Refactor multi-step actions to use explicit internal stages instead of `started` booleans. Start with `work` and `eat`, since both already behave like staged sequences.
- Keep action module responsibilities high-level: the brain picks the action, and the action owns its internal sequence (`find target -> move -> interact -> recover`).
- Build a proper needs layer on `DudeComponent` for normalized hunger, tiredness, social, and comfort values. Actions should score from those needs rather than ad hoc per-action fields.
- Add mood only after the needs layer exists. Replace the current stub mood multiplier with a real derived mood score and simple work-speed scaling first.
- Add traits after mood is working. Traits should modify need rates, action weights, and mood impacts through shared systems instead of one-off checks inside actions.
- Defer memory, mental breaks, and social relationships until the utility core, needs, mood, and traits are stable.

# Tech Debt
-  `is_valid()` usage is inconsistent
The core ECS loops and lookups now skip invalid entities/components by default, and AI goal resolution drops invalid entity goals. There are still call sites that mix `is_valid(...)`, `is_valid_component(...)`, and bare truthiness checks. Pick one idiom per reference type and use it consistently so stale references stay obvious in review.

- `update()` / `tick()` naming is backwards
In most engines, "tick" = fixed timestep, "update" = per-frame. Here it's the opposite - `update(dt)` is the fixed `0.2s` step and `tick(dt)` runs every frasme. Confusing for anyone new to the codebase.

- Residual zombie reference risk
Destroyed entities/components now keep their metatables, `destroy()` is idempotent, and core world/entity iteration skips invalid objects. Raw field access is still not guarded, though, so stale references can still leak old coordinates or names if a caller bypasses the helper methods.
