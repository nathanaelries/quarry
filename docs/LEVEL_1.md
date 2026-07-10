# Quarry — Level 1: "The Reclamation"

> The first real level: a linear escape through a harvesting district of the Cylinder.
> Built in `prototype/scripts/world.gd`, reusing the mechanic components as gates and
> set-dressing along a designed critical path.

## Premise

Abby wakes in a reclamation cell, her powers freshly granted. She must escape the district
and reach the **Ascension Gate** before the ship reclaims her.

## The critical path

```
[Awakening Cell] → [Rib Corridor] → [Sunken Gallery] → ⟿portal⟿ → [Cistern Gate]
   spirit-lock        first combat      combat +            final combat +
   gate               + loot            gravity (optional)  Ascension Gate (win)
```

Each area introduces or combines mechanics, and every hard gate uses a **robust** mechanic
so the level is always completable; the finicky-to-tune mechanics are **optional loot**
side-content, never blocking.

### 1. Awakening Cell — *teach Merkavah*
A sealed cell. The exit door won't open from this side. **Project your spirit (F)** through
the door to the lock beyond it and trip it (**E**) — the door slides away. First lesson:
the spirit reaches what the body can't. *Gate: spirit lock (robust).*

### 2. Rib Corridor — *teach the weapon & loot*
An organic corridor with a gold vein down its spine. Two drones patrol — **LMB** to fire.
A salvage crate to break. *Gate: clear the path.*

### 3. Sunken Gallery — *combat + gravity*
A cavern. Melee drones on the floor, a ranged drone perched on a ledge (flip the fight with
positioning). **Optional:** ride a **gravity path** up the west wall to a reliquary. The
exit is a **portal** at the south end — step through to fold to the Cistern.
*Gate: reach the portal (combat).*

### 4. Cistern Gate — *the climax*
A vast chamber. The final reclamation: a **senior** drone plus support. **Optional:** walk
around the **planetoid** for a cache, or shoot the **gravity switch** in the side vault to
reach a ceiling reliquary. Cross to the glowing **Ascension Gate** and step in — **escape.**
*Gate: reach the gate (combat).*

## Objectives

The HUD shows a running objective, updated by trigger volumes as you cross between areas:
1. *Escape the cell — project your spirit to the lock, then E.*
2. *Fight through the rib corridor.*
3. *Cross the gallery — reach the gate portal.*
4. *End the reclamation — reach the Ascension Gate.*
5. → **THE RECLAMATION — ESCAPED.**

## What's featured where

| Mechanic | Where | Role |
|---|---|---|
| Spirit projection / lock | Cell | critical gate |
| Weapon + loot + drone AI | Corridor, Gallery, Cistern | combat |
| Spirit blade | anywhere (kill a drone with it) | combat + essence loot |
| Portals | Gallery → Cistern | critical transition |
| Gravity path | Gallery | optional loot |
| Planetoid gravity | Cistern | optional loot |
| Gravity switch | Cistern side vault | optional loot |
| Resurrection | anywhere you die | safety net |

## Notes / future

- Layout is greybox; spacing, encounter counts, and pacing want an in-editor tuning pass.
- No checkpoints yet — dying resurrects you at the cell spawn. A per-area checkpoint is the
  obvious next step for a longer level.
- Spirit-revealed bridges aren't on this level's path (demoed separately); a good candidate
  for an optional shortcut later.
