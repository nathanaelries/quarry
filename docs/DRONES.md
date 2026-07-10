# Quarry — Drones & AI

> Enemy AI for the ship's drones. Implemented in the prototype (`scripts/drone.gd`,
> `enemy_bolt.gd`). Drones are both **loot targets** and **AI agents** — one script does both.

## What a drone is

Harvested species, reduced to the ship's labor and its teeth. In the prototype a drone is a
`CharacterBody3D` you can configure before it spawns:

- **`vulnerable_to`** — `physical` (gun only) · `spirit` (blade only) · `both`.
- **`rank`** — `junior` / `middle` / `senior`: more HP, faster, richer [loot](LOOT.md).
- **`ai_enabled`** — `false` = a stationary target (the loot range); `true` = active AI.
- **`archetype`** — `melee` (lunges) or `ranged` (fires bolts).

A forward-facing **eye** shows where it's looking and glows red when it's alerted.

## The AI loop

A small state machine, driven by perception each physics frame:

```
PATROL ──spot you──► CHASE ──in range──► ATTACK
  ▲                    │                    │
  └──timeout── SEARCH ◄┘ (lost sight)  ◄────┘ (you slipped away)
```

- **Patrol** — wander around a home anchor, scanning.
- **Chase** — move to your position while it can see you; remember your last-known spot.
- **Attack** — melee lunge (contact damage) or hold range and fire bolts, on a cooldown.
- **Search** — go to the last place it saw you; give up after a few seconds → patrol.
- **Aggro on damage** — shoot one and it turns on you even if it hadn't noticed you.

## Perception

- **Sight cone** — a ~65° half-angle cone out to ~17 m limits an *unaware* drone (once
  alerted it tracks you all around, as long as line-of-sight holds).
- **Line of sight** — a raycast from the drone's eye to you; walls and geometry block it, so
  you can break contact by breaking sight.

## Two systemic hooks (why this fits Quarry)

- **Gravity asymmetry.** Drones use world-down gravity and ignore gravity fields. Flip a
  room with the [gravity switch](MECHANICS.md) and *you* fall to the ceiling while the drones
  keep their footing — the design's "affects the player but not the enemies" made real.
- **Kill-method → loot.** The [loot condition](LOOT.md) still applies: shoot a drone for
  salvage, spirit-blade it for essence. Combat and the economy are the same choice.

## Player stakes

Combat needs consequences, so the player now has **5 health**. A hit shakes the screen,
flashes red, and drops a pip; at zero you enter the **death-walk and resurrect** at spawn
with full health (see [MECHANICS.md](MECHANICS.md) §resurrection). The body is damageable
even while you're projecting — leaving it somewhere safe *matters*.

Ranged drones fire a **hostile bolt** (`enemy_bolt.gd`) that damages you, passes over other
drones, and dies on walls.

## In the prototype

South of spawn, between you and the sealed rooms, a small encounter: two **melee** drones
(junior/middle) patrolling and one **ranged** drone (middle). Walk in and they engage.

## Known limits (future work)

- **Pathfinding is direct-steer + whisker avoidance**, not a navmesh. Drones steer around
  obstacles they can see at shin height, but a cluttered choke can still stump them. A baked
  `NavigationRegion3D` / `NavigationAgent3D` is the proper next step.
- No group/alert propagation (one drone spotting you doesn't call the others), no cover use,
  no flanking. All good candidates once the core loop proves fun.
