# Quarry — prototype (Godot 4)

A **playable first level — "The Reclamation"** — that puts the mechanics to work in a
designed space. Built entirely in code, so there is nothing to wire up: open and press Play.

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

## The level — "The Reclamation"

A linear escape; the HUD shows your current objective. Full design: [`../docs/LEVEL_1.md`](../docs/LEVEL_1.md).

1. **Awakening Cell** — the door won't open from here. Press **F** to project your spirit
   through it to the lock beyond, get close, and press **E** — the door slides away.
2. **Rib Corridor** — two drones patrol. **LMB** to fire; break the crate for loot. Kill with
   the gun for salvage or the spirit blade (**F** then **LMB**) for essence.
3. **Sunken Gallery** — a firefight with a sniper on a ledge. *Optional:* ride the green
   **gravity path** up the west wall to a reliquary. The **portal** at the south folds you on.
4. **Cistern Gate** — the final reclamation (a big **senior** drone + support). *Optional:*
   circle the **planetoid** or shoot the **gravity switch** in the side vault for caches.
   Step into the glowing **Ascension Gate** to escape.

If you die (drone hits, or shooting yourself through a portal), you death-walk and resurrect
at the cell — health is the 5 pips up top.

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
| `scripts/drone.gd` | Drone: loot target + AI agent (perception, patrol/chase/attack/search, melee/ranged). |
| `scripts/enemy_bolt.gd` | Hostile projectile fired by ranged drones. |
| `scripts/spirit_lock.gd` | Spirit-only lock that opens a door. |
| `scripts/spirit_reveal.gd` | Bridge the spirit reveals for the body to cross. |
| `scripts/juice.gd` | Autoload `Juice`: procedural SFX, screen-shake helpers, impact sparks, spirit audio filter. |
| `scripts/loot.gd` | Autoload `Loot`: item catalog, weighted drop pools, rank/condition rolls, spawner. |
| `scripts/pickup.gd` | A floating, rarity-colored loot mote with a pickup magnet. |
| `scripts/loot_container.gd` | Breakable salvage crate / spirit reliquary. |
| `scripts/hud.gd` | Controls, zone guide, mode readout, spirit timer, death overlay, satchel + pickup toasts. |

## Loot (BOTW-style)

Kill a drone and it drops loot — but **how** you kill it decides *what*: **shoot** it for
**salvage** (chitin, sap, cores), **spirit-blade** it for **essence** (rune fragments,
Sefirah Motes). Drone **rank** (junior/middle/senior) scales the haul. Breakable **crates**
and **reliquaries** have their own pools. Drops float up as rarity-colored motes, magnet to
you, and land in the **satchel** (top-left counter) with a toast. Full design +
tuning-by-data: [`../docs/LOOT.md`](../docs/LOOT.md).

## Drones & combat (AI)

South of spawn, live drones **patrol** until they **spot you** (sight cone + line-of-sight),
then **chase** and **attack** — two melee lungers and one ranged caster that fires bolts.
Shooting one **aggros** it. They ignore gravity flips (so flip a room and *you* fall to the
ceiling while they keep their footing). You now have **5 health** (pips, top-center); a hit
shakes + flashes red, and at zero you death-walk and resurrect. They navigate with a
**baked navmesh** (`NavigationRegion3D` + `NavigationAgent3D`), so a chaser routes around
walls and platforms instead of getting stuck. Full design: [`../docs/DRONES.md`](../docs/DRONES.md).

## Feel & audio (juice)

The greybox now has game-feel, so the loop can be judged with the sound on: **screen shake**
on hits/jumps/gravity-flips/portals, **muzzle flash**, **impact sparks**, and a full set of
**procedurally-synthesized SFX** (shot, hit, footsteps, jump, portal whoosh, gravity
whoomph, spirit enter/exit). Entering spirit mode routes the whole mix through a **lowpass +
reverb** so the world goes ethereal.

> The SFX are **placeholder synth tones generated in code** (no audio files — keeps the repo
> self-contained). They're for validating feel, not shipping; swap in authored audio later —
> the trigger points (`Juice.play_3d/play_2d/spark/set_spirit`) stay the same. Audio couldn't
> be *heard* here (headless), only verified to synthesize and play without error.

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
