# Quarry

> *A **quarry** is both the thing that is hunted and the pit things are torn out of.*
> You are both. So is the world that took you.

**Quarry** is a first-person action-adventure concept and prototype: a reluctant
heroine is abducted onto a colossal *living* starship that seeds worlds with life only
to return and harvest them. To survive and fight back she awakens ancestral powers drawn
from Jewish mystical tradition — projecting her spirit, bending local gravity, and
stepping through fixed portals in the ship's flesh.

It is an original work **inspired by** the design of *Prey* (2006) — specifically the way
that game interlocked three unusual traversal/combat systems. Quarry re-themes and
re-imagines that idea from the ground up; it borrows no characters, assets, or text.

---

## The hook: three mechanics that interlock

Quarry's identity is a **triad** of systems that are individually interesting and
combine into level and combat design that stays surprising:

| Mechanic | What it is | Design role |
|---|---|---|
| **Portals** | Fixed, glowing rings grown into the ship. You can walk through, **look through**, and **shoot through** them. | Traversal shortcuts + flanking and trick-shot combat. |
| **Localized gravity** | Gravity is a *place*, not a constant. Walk up walls, around floating planetoids, along lit gravity paths. | Turns every surface into playable space; reframes rooms. |
| **Merkavah (spirit projection)** | Detach your spirit from your (vulnerable) body: free-fly, scout, walk impossible surfaces, and trip spirit-only locks. | Risk/reward puzzle & ambush setup. |

The point is not any one of them — it's the **cross product**. A portal on a ceiling you
can only reach in a flipped-gravity zone, opened by a lock only your spirit can trip.

See [`docs/MECHANICS.md`](docs/MECHANICS.md) for the full breakdown.

---

## Documentation (the design doc)

- **[docs/DESIGN.md](docs/DESIGN.md)** — the full game design document: pillars, systems,
  progression, and the editorial notes on how this was cleaned up from the source brief.
- **[docs/STORY.md](docs/STORY.md)** — narrative, characters, factions, world (full spoilers).
- **[docs/MECHANICS.md](docs/MECHANICS.md)** — the mechanic triad in implementable detail.
- **[docs/ART_BIBLE.md](docs/ART_BIBLE.md)** — the visual direction (Ōkami × Wind Waker ×
  biomech × Kabbalah): color system, motifs, silhouettes, two-world render. Vector concept
  art in [`docs/art/`](docs/art/); a shareable page renders in [`docs/art/art-bible.html`](docs/art/art-bible.html).
- **[docs/LOOT.md](docs/LOOT.md)** — the BOTW-style drop system: weighted pools, rank
  escalation, and the twist where the *mechanic you kill with* transforms the loot.
- **[docs/DRONES.md](docs/DRONES.md)** — enemy AI: perception (sight cone + line-of-sight),
  patrol/chase/attack/search, melee & ranged archetypes, and the gravity asymmetry.
- **[docs/LEVEL_1.md](docs/LEVEL_1.md)** — "The Reclamation": the first real level — a linear
  escape (cell → corridor → gallery → cistern) with mechanic gates, paced combat, and a win.
- **[docs/SHRINES.md](docs/SHRINES.md)** — the shrine framework: a reusable base + a hub +
  a game shell, so each shrine (BOTW-style teaching level) is one small file to add.

A note on the cultural material: Quarry draws on Kabbalah and Merkavah mysticism as the
*fiction* behind its powers. It is a respectful creative interpretation, **not** a
religious text, and a shipping product should be developed with cultural and religious
consultants. See the "Cultural authenticity" section in `DESIGN.md`.

---

## The prototype

[`prototype/`](prototype/) is a **Godot 4** vertical slice. You start in a **hub** and step
into a shrine gate to play the first shrine, **"The Reclamation"** — a linear escape through
a harvesting district of the Cylinder. Shrines are small, self-contained teaching levels; the
[shrine framework](docs/SHRINES.md) makes each one a single file to add. Built almost entirely
in code, so it opens and runs with nothing to wire up by hand.

The critical path — cell → corridor → gallery → cistern — introduces the mechanics one at a
time and combines them, gated so it's always completable ([docs/LEVEL_1.md](docs/LEVEL_1.md)):

- **Awakening Cell** — project your spirit (**F**) through the sealed door to a lock and trip
  it (**E**): the spirit reaches what the body can't.
- **Rib Corridor** — first combat (**LMB**) and loot; drones patrol, spot you, and chase.
- **Sunken Gallery** — a firefight (a sniper on a ledge), an optional gravity-path climb, and
  a **portal** that folds you to the Cistern.
- **Cistern Gate** — the final reclamation (a senior drone + support), an optional planetoid
  and gravity-switch vault, then the glowing **Ascension Gate** — step in to escape.

Under it: re-orientable gravity, Merkavah spirit projection + blade, portals (walk/look/shoot),
a weapon, BOTW-style loot, drone AI with navmesh + RVO, player health, and resurrection.

### Run it

Godot is **not** installed on this machine, so the project was authored but not executed
here. To try it:

1. Install **Godot 4.3 or newer** (standard build — no C#/.NET needed).
2. Open the Godot project manager → **Import** → select
   `prototype/project.godot`.
3. Press **F5** (Play). The main scene builds the sandbox at runtime.

### Controls

| Input | Action |
|---|---|
| **W A S D** | Move |
| **Mouse** | Look |
| **Space** | Jump / (in spirit) ascend |
| **Shift** | (in spirit) descend |
| **F** | Toggle Merkavah spirit projection |
| **E** | Interact / trip a spirit lock (while in spirit) |
| **Esc** | Release mouse · click to re-capture |

Layout and per-script notes: [`prototype/README.md`](prototype/README.md).

---

## Repo layout

```
quarry/
├─ README.md            ← you are here
├─ LICENSE              ← MIT
├─ .gitignore           ← ignores Godot's generated .godot/ cache & exports
├─ docs/
│  ├─ DESIGN.md         ← full game design document
│  ├─ STORY.md          ← narrative, characters, factions
│  └─ MECHANICS.md      ← the mechanic triad, in detail
└─ prototype/           ← Godot 4 vertical slice
   ├─ project.godot
   ├─ README.md
   ├─ icon.svg
   ├─ scenes/main.tscn
   └─ scripts/          ← player, portal, gravity, spirit, world, hud
```

## Status

Early concept + prototype. This is a design foundation and a proof-of-play for the core
loop, not a game. Contributions and forks welcome.

## License

MIT — see [LICENSE](LICENSE).
