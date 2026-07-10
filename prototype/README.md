# Quarry — prototype (Godot 4)

A single-room vertical slice that makes the three signature mechanics real and playable.
It is built entirely in code, so there is nothing to wire up: open and press Play.

## Run

1. Install **Godot 4.3+** (standard build — no C#/.NET).
2. Godot project manager → **Import** → pick this folder's `project.godot`.
3. **F5** to play.

> Godot was not installed on the machine this was authored on, so the project has not been
> executed here — open it in the editor to run. If a script needs a tweak for your exact
> Godot version, the error panel will point right at it.

## Controls

| Input | Action |
|---|---|
| **W A S D** | Move |
| **Mouse** | Look |
| **Space** | Jump / (spirit) ascend |
| **Shift** | (spirit) descend |
| **F** | Toggle Merkavah spirit projection |
| **E** | Trip a spirit lock (while in spirit form) |
| **Esc** | Release mouse · click to re-capture |

## What to try

- **Localized gravity** — walk east up the ramp onto the **orange planetoid** and keep
  walking: you'll circle it upside-down as its own gravity holds you.
- **Portals** — step into the **cyan portal ring** near spawn; you'll come out on a high
  ledge you can't otherwise reach.
- **Merkavah** — walk to the sealed room (purple door, south-east). Press **F** to leave
  your body, fly the spirit through to the **purple crystal**, press **E** to trip it — the
  door slides away and your body can walk in to the green goal. Watch the spirit meter:
  when it empties you snap back to your body.

## Files

| File | Role |
|---|---|
| `project.godot` | Minimal config. Main scene = `scenes/main.tscn`. No InputMap (registered in code). |
| `scenes/main.tscn` | One root node running `world.gd`. |
| `scripts/world.gd` | Builds lighting, geometry, the three demos, player, and HUD; registers input. |
| `scripts/player.gd` | First-person controller: re-orientable gravity + spirit projection. |
| `scripts/portal.gd` | Linked portal pair; teleport with remapped velocity. |
| `scripts/gravity_planet.gd` | Planetoid with a radial gravity field. |
| `scripts/spirit_lock.gd` | Spirit-only lock that opens a door. |
| `scripts/hud.gd` | Controls text, mode readout, spirit timer. |

## Known first-pass limits

- **Portals teleport but don't yet render "see-through" or pass projectiles.** The
  look-through / shoot-through pass (a `SubViewport` mirroring the partner's view) is the
  documented next step — see [`../docs/MECHANICS.md`](../docs/MECHANICS.md).
- Entering a strong gravity field re-orients you quickly; the slerp softens it but a hard
  90°+ grab is still abrupt by design.
- No enemies, weapons, or resurrection yet — this slice is about the traversal triad.
