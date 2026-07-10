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

A note on the cultural material: Quarry draws on Kabbalah and Merkavah mysticism as the
*fiction* behind its powers. It is a respectful creative interpretation, **not** a
religious text, and a shipping product should be developed with cultural and religious
consultants. See the "Cultural authenticity" section in `DESIGN.md`.

---

## The prototype

[`prototype/`](prototype/) is a small **Godot 4** vertical slice that makes the three
mechanics real and playable in one sandbox room. It is built almost entirely in code so
it opens and runs with nothing to wire up by hand.

What it demonstrates:

- **First-person controller with re-orientable gravity** — your "down" follows the field
  you're standing in.
- **A planetoid with radial gravity** — walk all the way around it.
- **Merkavah spirit projection** — press **F** to leave your body, free-fly to scout, and
  trip a spirit-only lock that opens a sealed door.
- **A portal pair** — walk into one, come out the other, reaching a ledge you otherwise
  couldn't.

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
