# Colonist Brain Design

Design document for the RushWorld dude AI, mood, and personality systems.

## Overview

Dudes are driven by a **Utility AI** that scores possible actions each tick and picks the highest. Personality **traits** bias these scores, making each dude behave differently. A **mood system** with ~15-20 drivers affects both performance (continuous scaling) and triggers **mental breaks** at extremes. Dudes have **short-term memory** of recent events that feed into mood.

The goal: emergent stories from the intersection of social dynamics and survival pressure.

---

## 1. Utility AI

### How It Works

Every tick, each available **action** is scored from 0.0 to 1.0 based on the dude's current state. The highest-scoring action is selected.

```
score = base_curve(relevant_need) * weight * trait_modifier * mood_modifier
```

- **base_curve** — maps a need value (e.g. hunger 0-1) to an urgency score. Usually a curve, not linear (e.g. hunger only gets urgent past 0.6).
- **weight** — base importance of this action category.
- **trait_modifier** — personality shifts the weight (e.g. Lazy dude: work weight * 0.6).
- **mood_modifier** — low mood can suppress optional actions, high mood can boost social ones.

### Action Categories

| Action | Primary Driver | Example Scoring |
|--------|---------------|-----------------|
| Eat | Hunger need | Urgent past 0.6 hunger, critical past 0.85 |
| Sleep / Rest | Tiredness need | Gradual curve, hard override past 0.9 |
| Wander | Boredom / no better option | Low flat score, fallback action |
| Build | Available work + work drive | Moderate, boosted by Hardworker trait |
| Gather resources | Resource need nearby | Moderate, context-dependent |
| Socialize | Social need + nearby dude | Rises over time without interaction |
| Flee | Threat nearby | Spikes to max, overrides almost everything |
| Idle | Nothing to do | Lowest priority, absolute fallback |

### Anti-Flicker

To prevent dudes flip-flopping between close scores:
- **Hysteresis** — current action gets a small bonus (+0.05) so switching requires a meaningful score difference.
- **Minimum commitment** — some actions have a minimum duration before they can be interrupted (except by Flee).

### Multi-Step Actions

Some actions require multiple steps (e.g. eat = find food source → walk to it → harvest → eat). These are handled as **action sequences** — the Utility AI picks the high-level action, and the action itself manages its internal steps. This replaces the current brain state machine with something more extensible.

---

## 2. Mood System

### Mood Score

Each dude has an overall **mood** value from 0 (worst) to 100 (best), calculated as:

```
mood = base_mood + sum(active_mood_modifiers)
```

`base_mood` is 50 (neutral). Modifiers push it up or down.

### Mood Thresholds

| Range | State | Effect |
|-------|-------|--------|
| 0-15 | Breaking | Mental break triggers |
| 16-30 | Very unhappy | -30% work speed, may refuse tasks |
| 31-45 | Unhappy | -15% work speed |
| 46-55 | Neutral | No modifier |
| 56-70 | Content | +10% work speed |
| 71-85 | Happy | +20% work speed, social actions more frequent |
| 86-100 | Elated | +30% work speed, inspiration chance |

### Mood Drivers (~15-20 sources)

**Needs-based (always active):**
1. Hunger — negative when hungry, positive after eating
2. Tiredness — negative when exhausted
3. Comfort — environmental quality (indoors, near fire, etc.)
4. Social — time since last positive social interaction

**Event-based (from memories):**
5. Ate good meal — small positive, short duration
6. Ate raw food — small negative
7. Friend died — large negative, long duration
8. Witnessed death — moderate negative
9. Had a good conversation — moderate positive
10. Was insulted — moderate negative
11. Completed a build — small positive
12. Idle too long — growing negative

**Environmental:**
13. Sleeping outside — negative
14. Nice surroundings — positive (near decorations/nature)
15. Ugly surroundings — negative (near corpses/rubble)
16. Crowded — negative (too many dudes nearby)
17. Alone too long — negative

**Trait-driven:**
18. Trait-specific triggers (e.g. Outdoorsy dude gets positive mood outside, negative indoors)

### Mental Breaks

When mood stays below 15 for a sustained period, a mental break triggers. The type is influenced by personality:

| Break | Behavior | Trait Affinity |
|-------|----------|---------------|
| Tantrum | Destroys nearby objects/buildings | Volatile |
| Sad Wander | Ignores all tasks, walks aimlessly | Pessimist |
| Binge Eating | Consumes all available food | Glutton |
| Hide | Refuses to leave a spot, won't work | Coward |
| Berserk | Attacks nearest dude | Volatile |

Mental breaks last a fixed duration and cannot be interrupted by normal actions. Other dudes can attempt to "talk down" a breaking dude (social action) with a chance of ending it early.

---

## 3. Personality Traits

Each dude spawns with **2-3 traits** randomly selected from a pool. Traits are categorized to prevent contradictions (max 1 from each category).

### Trait Pool

**Work Ethic:**
- Hardworker — work actions score +40%, "completed build" mood bonus doubled
- Lazy — work actions score -40%, idling doesn't cause negative mood

**Temperament:**
- Optimist — base mood +10, negative mood modifiers reduced by 25%
- Pessimist — base mood -10, positive mood modifiers reduced by 25%
- Volatile — mood swings are amplified (modifiers * 1.5), more likely to mental break

**Social:**
- Social Butterfly — social need grows 2x faster, conversation mood bonus doubled
- Loner — social need grows 0.5x, proximity to others causes small negative mood

**Appetite:**
- Glutton — hunger grows 1.5x faster, eating mood bonus doubled, binge break affinity
- Iron Stomach — no negative mood from raw/bad food

**Courage:**
- Brave — flee threshold lower, can fight threats, small positive mood in danger
- Coward — flee threshold higher, flee action scored much higher, hide break affinity

**Environment:**
- Outdoorsy — positive mood outside, negative mood indoors
- Homebody — positive mood indoors/near buildings, negative mood in wilderness

### Trait Effects on Utility AI

Traits modify the Utility AI through three mechanisms:
1. **Score weights** — directly multiply action scores (e.g. Lazy * 0.6 on work)
2. **Need rates** — change how fast needs grow (e.g. Glutton hunger * 1.5)
3. **Mood modifiers** — alter mood impact of events (e.g. Optimist reduces negatives)

---

## 4. Short-Term Memory

Each dude maintains a list of **recent memories** (max ~10). Memories are the bridge between events and mood.

### Memory Structure

```lua
{
    type = "friend_died",         -- memory type (maps to mood modifier)
    description = "Bob died",     -- for UI/debug
    mood_impact = -20,            -- mood modifier while active
    age = 0,                      -- ticks since creation
    duration = 50,                -- ticks until expiry
    decay = true                  -- if true, mood_impact fades linearly
}
```

### Memory Behavior

- Memories are created by game events (eating, social interactions, witnessing death, completing work, etc.)
- Each memory has a **duration** and optionally **decays** — a decaying memory's mood impact shrinks linearly to 0 over its duration.
- Severe memories (friend died, mental break witnessed) have longer durations and decay slower.
- When the memory list exceeds the cap, the weakest (lowest current mood_impact) memory is dropped.
- Duplicate memories of the same type **stack** but with diminishing returns (second instance at 60% impact, third at 30%).

---

## 5. Social System

Dudes form **relationships** that emerge from interactions, not predefined.

### Relationship Score

Each dude-to-dude pair has a relationship value from -100 (enemy) to +100 (best friend), starting at 0 (stranger).

| Range | Label |
|-------|-------|
| -100 to -50 | Rival |
| -49 to -10 | Disliked |
| -9 to 9 | Neutral |
| 10 to 49 | Friendly |
| 50 to 100 | Close friend |

### Social Interactions

When two dudes are near each other and one (or both) have social need, they can interact. Interaction type and outcome are influenced by mood and traits:

| Interaction | Relationship Effect | Mood Effect | Likelihood |
|-------------|-------------------|-------------|------------|
| Chat | +3 to +8 | Small positive | High (default) |
| Joke | +5 to +12 | Moderate positive | Medium, boosted by high mood |
| Insult | -5 to -15 | Negative to both | Low, boosted by low mood or Volatile |
| Argue | -8 to -20 | Negative to both | Low, boosted by existing rivalry |
| Deep talk | +10 to +20 | Large positive | Rare, requires existing friendship |

### Emergent Scenarios

The combination of social, mood, and survival systems should produce scenarios like:
- A dude's friend dies → grief mood → low mood → poor work output → other dudes pick up slack → if they can't, colony spirals
- Two dudes with Volatile trait keep insulting each other → rivalry → one snaps into berserk break → attacks the other
- A Lazy + Optimist dude barely works but keeps morale up through socializing
- Resource shortage → everyone hungry → moods drop → mental breaks cascade → colony collapse (the classic RimWorld death spiral)
- A Brave dude stands and fights a threat while a Coward flees, creating natural role differentiation

---

## 6. Implementation Phases

### Phase 1: Utility AI Core
Replace the current brain state machine with a scored action system. Port existing behaviors (eat, wander, work, idle) to the new system. Add hysteresis and minimum commitment.

### Phase 2: Needs & Mood
Add hunger, tiredness, social, and comfort as tracked needs with curves. Implement mood score calculation and performance scaling (work speed modifiers).

### Phase 3: Traits
Build the trait pool and apply trait modifiers to Utility AI scoring and need rates. Randomize trait assignment on dude spawn.

### Phase 4: Memory
Add the memory system. Hook up game events (eating, building, etc.) to create memories. Wire memories into mood calculation.

### Phase 5: Mental Breaks
Implement mood threshold detection and break behaviors. Add break-specific AI overrides.

### Phase 6: Social
Add relationship tracking, social interactions, and social-driven memories. This is the layer that ties everything together for emergent storytelling.
