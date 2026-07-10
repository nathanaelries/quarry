# Quarry — Combat & Movement Verbs

> The moment-to-moment combat kit. The triad ([MECHANICS.md](MECHANICS.md)) is traversal;
> this is the fighting. Implemented across `scripts/player.gd`, `drone.gd`, `enemy_bolt.gd`,
> `juice.gd`. Enemy AI itself lives in [DRONES.md](DRONES.md).

## The verbs

| Verb | Input | What it does |
|---|---|---|
| **Fire** | LMB | Shoot a projectile — carries through portals. |
| **Spirit blade** | LMB (in spirit) | Cone-slash; only harms spirit-vulnerable drones. |
| **Dash** | Shift | Quick burst with **i-frames** — dodge through anything. |
| **Parry** | RMB | Timed deflect — negate a hit, reflect a bolt, stagger a melee. |

(Shift is dash in the body and *descend* in spirit — mutually exclusive modes, one key.)

## Dash (the "Moves" verb)

A short, fast burst in your movement direction (or forward if you're not moving), on a
cooldown. **The whole dash is invulnerable** — `take_damage` is a no-op while `_dash_t > 0`,
so a well-timed dash rolls through a bolt or a lunge. It overrides normal planar movement for
its duration; gravity along your "up" is preserved, so it works on walls and around
planetoids too.

Tune in `player.gd`: `DASH_SPEED` (20), `DASH_TIME` (0.16 s), `DASH_CD` (0.7 s).

## Parry (the "Parry" verb)

RMB opens a brief **parry window** (`PARRY_WINDOW`, 0.24 s). If an attack lands inside it:

- **Melee** → no damage, and the attacker is **staggered** (`stagger()`): it drops its wind-up
  and sits stunned and open for ~1.3 s. A free punish.
- **Ranged bolt** → **reflected** — the bolt reverses, turns friendly, and bites the drones
  (`enemy_bolt.reflect()`).

A successful parry pays off with feel: a metallic *clang*, a gold screen flash, a shake, and
a brief **hit-stop** (`Juice.hitstop` — real-time-restored time dilation).

### Fair by design: telegraphed attacks
So parry is a *reaction*, not a coin-flip, drone attacks **telegraph**: on the attack
cooldown a drone enters a **wind-up** (`WINDUP`, 0.4 s) with its eye flaring bright and a
tell sound, *then* strikes. That wind-up is your window — read it, parry it. Ranged attacks
are read off the bolt itself in flight.

## Health & resurrection

The player has **5 HP** (pips, top-center). A hit shakes + flashes red and drops a pip; at
zero you death-walk and **resurrect** at your spawn with full health (see
[MECHANICS.md](MECHANICS.md) §resurrection). Your body is damageable while you project, so
where you leave it matters.

## What this unblocks

The sealed hub pedestals **"Moves"** and **"Parry"** now have their verbs — the two chambers
that teach them can be built (see [CHAMBERS.md](CHAMBERS.md)).

## Not yet (future)

- A **combo/attack chamber** verb set may want a melee swing for the body (not just the gun),
  or charge/heavy attacks.
- Parry could **build a resource** (a spirit charge) rather than only staggering.
- Perfect-dodge (a dodge at the last instant) could trigger the same hit-stop reward as parry.
