# Quarry — The Shrine Framework

> Shrines are small, self-contained teaching levels (à la BOTW). This is the system that
> makes them cheap to add: a reusable base, a hub to enter them, and a game shell that swaps
> between them and tracks completion. Adding a shrine is one file, not a `world.gd` rewrite.

## Pieces

| File | Role |
|---|---|
| `scripts/game.gd` | **Game shell** (the main scene root). Swaps between the hub and shrines; remembers which shrines are completed. Holds the shrine `SHRINES` registry. |
| `shrines/shrine_base.gd` | **Base class.** Provides the player, HUD, input, lighting, navmesh bake, objective triggers, build helpers (`_add_box`, `_vein`, `_spawn_drone`, `_spawn_container`, `_objective_trigger`), and the win → completion flow (`_build_win_gate`). |
| `shrines/hub.gd` | **The Hub.** A pedestal chamber (extends the base). Step into a glowing gate to enter that shrine; sealed pedestals are placeholders. |
| `shrines/shrine_reclamation.gd` | **Shrine 01** — "The Reclamation" (Level 1) as content on the base. |

## Flow

```
Game (root)
  └─ Hub  ──(step into a gate)──►  Shrine  ──(reach the win gate)──►  back to Hub (marked ✓)
```

- `Game._ready()` → `enter_hub()`.
- A hub gate calls `Game.enter_shrine(id)` → frees the hub, instances the shrine.
- The shrine's win gate calls `_complete()` → banner → `Game.complete_shrine(id)` → records it
  and returns to the hub, where that pedestal now reads as done (gold).

## Adding a shrine

1. Write `shrines/shrine_<name>.gd`:
   ```gdscript
   extends "res://shrines/shrine_base.gd"

   func get_spawn() -> Vector3: return Vector3(0, 1.5, 0)
   func intro_objective() -> String: return "…"
   func build_shrine() -> void:
       _add_box(...)                 # geometry (auto-tagged for the navmesh)
       _spawn_drone(...)             # enemies
       _objective_trigger(pos, size, "…")
       _build_win_gate(exit_pos)     # step in to finish
   ```
2. Register it in `game.gd` `SHRINES = { "<name>": preload(...) }`.
3. Add a hub pedestal for it in `hub.gd`.

That's it — the base handles everything else. (`extends` uses the file path, not a
`class_name`, so it resolves even before the editor re-imports.)

## The four starter shrines (planned)

| # | Shrine | Teaches | Status |
|---|---|---|---|
| 01 | The Reclamation | Spirit projection (+ combined mechanics) | **built** |
| 02 | Moves | A dash / dodge | needs the **dash** mechanic |
| 03 | Parry | Timed parry / deflect | needs the **parry** mechanic |
| 04 | Attacks & Puzzles | Weapon + spirit blade + puzzle-solving | mechanics exist |

## Not yet (future)

- **Persistence.** Completion is in-memory only (resets on quit); the player's satchel doesn't
  carry between shrines yet. A save file + persistent player state is the next system.
- **Rewards.** Completing a shrine just marks it done. Tie it to the Sefirot progression later.
- **Open world.** The long-term goal (a traversable Cylinder) is a separate, much larger
  effort — world streaming, LOD, save, content at scale. Shrines prove the loop first.
