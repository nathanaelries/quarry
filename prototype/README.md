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
| **LMB** | Fire the gun / swing the spirit blade |
| **Space** | Jump / (spirit) ascend |
| **Shift** | (spirit) descend |
| **F** | Toggle Merkavah spirit projection |
| **E** | Trip a spirit lock (while in spirit form) |
| **Esc** | Release mouse · click to re-capture |

## What to try

Everything in the mechanic triad is now live in one arena:

- **Planetoid gravity** — walk east onto the **orange planetoid** and keep going: you circle
  it upside-down under its own (moon-light) field. One good jump launches you off.
- **Gravity path** — north, a **green lit strip** on a wall: step onto it and walk straight
  *up* the wall to the ledge. Step off and you fall.
- **Gravity switch** — the room to the south-east: **shoot the yellow switch** and the room's
  gravity flips — you fall up to the ceiling, where the prize waits. Shoot it again to drop.
- **Portals (look / step / shoot)** — the **cyan rings** to the west. *Look* into one to see
  the far side rendered live; *step* through to reach the high ledge; *shoot* straight
  through to tag the drone floating past the exit. Bad angle = you might hit yourself.
- **Merkavah — spirit lock** — the sealed room (purple door, south). **F** to leave your
  body, fly the spirit through the wall to the **purple crystal**, **E** to trip it; the door
  opens for your body. Watch the meter — empty and you snap home. You also can't drift past
  the tether.
- **Merkavah — reveal + blade** — the platforms to the west, split by a gap. **F**, fly the
  spirit across to reveal the hidden **bridge**, and **LMB** to slash the purple spirit-only
  drone. Return, cross the now-solid bridge in the flesh.
- **Resurrection** — fall off the world, or shoot yourself through a portal: a brief
  death-walk, then you return to spawn.

## Files

| File | Role |
|---|---|
| `project.godot` | Minimal config. Main scene = `scenes/main.tscn`. No InputMap (registered in code). |
| `scenes/main.tscn` | One root node running `world.gd`. |
| `scripts/world.gd` | Builds lighting, geometry, every demo, player, and HUD; registers input. |
| `scripts/player.gd` | First-person controller: re-orientable gravity, spirit projection, weapon, blade, tether, resurrection. |
| `scripts/portal.gd` | Linked portal pair: walk / look (SubViewport) / shoot through. |
| `scripts/projectile.gd` | Weapon projectile — damages targets, carries through portals. |
| `scripts/gravity_planet.gd` | Planetoid with a radial (moon-light) gravity field. |
| `scripts/gravity_path.gd` | Lit walkway you ride up a wall. |
| `scripts/gravity_region.gd` | A volume whose pull a switch can flip. |
| `scripts/gravity_switch.gd` | Shootable switch that flips its linked region. |
| `scripts/drone.gd` | Dummy target — vulnerable to gun, blade, or both. |
| `scripts/spirit_lock.gd` | Spirit-only lock that opens a door. |
| `scripts/spirit_reveal.gd` | Bridge the spirit reveals for the body to cross. |
| `scripts/hud.gd` | Controls, zone guide, mode readout, spirit timer, death overlay. |

## Known first-pass limits (needs eyes-on-screen)

The whole triad loads and runs error-free headless, but a few things can only be judged —
or need light tuning — in the editor:

- **See-through portals** render via a `SubViewport` + screen-UV shader. Headless has no
  GPU, so the visual couldn't be verified here. If a portal surface reads black, the usual
  fix is a one-liner (share the main `World3D` on the SubViewport).
- **The reveal-demo ramp** is tilted by a guessed rotation sign. If it slopes the wrong way,
  flip the sign of `rotation_degrees.z` in `world.gd::_build_spirit_reveal_demo`.
- **Gravity transitions** (planetoid capture, path onto a wall, switch flip) can feel abrupt
  on a hard 90°+ grab; the slerp softens it but the exact feel is tuning.
- Drones are inert dummies (no AI); the vehicle/shuttle from the design isn't in yet.
