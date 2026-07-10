# Quarry — Loot & Drops

> A BOTW-style probabilistic drop system, themed to Quarry. Implemented in the prototype
> (`scripts/loot.gd`, `pickup.gd`, `loot_container.gd`). This doc is the design + tuning
> reference.

## What we took from Breath of the Wild

BOTW's loot tables gave us four ideas worth stealing, each mapped onto Quarry:

| BOTW | Quarry |
|---|---|
| Weighted pools: guaranteed drops + probability rolls | Same — pools have a `guaranteed` list and a weighted `table`. |
| **Rank escalation** (Junior / Middle / Senior drop more & rarer) | Drones carry a `rank`; higher rank = more probability rolls (and thus more rare shots) + more HP. |
| **Condition transforms the drop** (burnt→cooked, frozen→chilled) | **The mechanic you kill with** transforms the drop — this is the Quarry twist (see below). |
| Breakable containers with their own pools | Salvage crates and sacred reliquaries. |

## The twist: the kill *method* is the condition

BOTW changes a drop based on the *state* of the corpse (set it on fire, get cooked meat).
Quarry has a richer hook already built in — **how** you killed it:

- **Shoot a drone** → it breaks into **salvage** (`drone_salvage`): chitin, sap, cores, cells.
- **Spirit-blade a drone** → you strike its *soul*, so it yields **spirit essence**
  (`drone_essence`): rune fragments, Sefirah Motes, Portal Filaments.

So a `both`-vulnerable drone is a genuine choice: bullets for materials, or the blade for
mystical loot. That choice is the loot system's soul, and it's native to the mechanic triad.

## Rarity tiers

Five tiers, colored straight from the [Art Bible](ART_BIBLE.md) palette (so pickups read
their value at a glance and match the world):

| Tier | Color | Palette |
|---|---|---|
| Common | Bone Ivory | `#D8C9A6` |
| Uncommon | Harvest Green | `#7FBF6B` |
| Rare | Portal Cyan | `#4FD4E0` |
| Epic | Merkavah Violet | `#B79BFF` |
| Legendary | Emanation Gold | `#FFE39A` |

## Item catalog (prototype)

| Item | Tier | Fiction |
|---|---|---|
| Chitin Shard | Common | scrap of drone plating |
| Sap Vial | Common | a dram of the ship's harvested life |
| Drone Core | Uncommon | a drone's spent power cell |
| Rune Fragment | Uncommon | a broken letter-glyph from a vein |
| Gravity Cell | Rare | a shard that still remembers its "down" |
| Portal Filament | Rare | a thread of folded space |
| Sefirah Mote | Epic | a spark shed from a great organ-node |
| Ancient Keeper Core | Legendary | a relic of the ship's makers |

## Drops → pickups

Rolled drops spawn as **floating, rarity-colored motes** that pop in, bob, and are drawn to
the player when close (BOTW's pop-and-grab), then collected on contact. Collected items go
to a satchel (a simple `item → count` inventory on the player) and raise a toast; rare+
pickups get a brighter chime.

## Containers

- **Salvage crate** — shoot to break; drops `salvage_crate` (materials).
- **Reliquary** — a sacred vessel; `spirit_breakable`, so the spirit blade pops it (a
  projectile works too); drops `reliquary` (spirit loot).

## Tuning & extending

Everything lives in data in `scripts/loot.gd`:
- **`ITEMS`** — id → name + rarity.
- **`RARITY_COLOR`** — tier → color.
- **`POOLS`** — each pool's `guaranteed` list and weighted `table` (`weight`, `min`, `max`).
- **`ROLLS`** — probability picks per rank.

Add an item by adding an `ITEMS` entry and referencing it in a pool. Add a pool and point a
drone/container at it by name. No code changes needed beyond the data.

## Not yet (future)

- A real **economy** — what loot is *for* (the Sefirot upgrade tree, crafting, cooking).
- **First-encounter bonuses** and per-region container pools (both are in BOTW's table).
- Persistence / save. Right now the satchel is per-run.
