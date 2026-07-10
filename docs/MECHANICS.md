# Quarry — The Mechanic Triad

The whole game hangs on three verbs that are interesting alone and *combinatorial*
together: **portals**, **localized gravity**, and **Merkavah spirit projection**. This
doc specifies each at an implementable level and — most importantly — how they compose.

The [`prototype/`](../prototype/) now implements every behaviour described below —
walk/look/shoot-through portals, gravity paths + switches + planetoids, and the full
Merkavah verb set (free-fly, tether, spirit blade, spirit locks, spirit-revealed paths) —
plus the supporting weapon and resurrection systems. Per-mechanic notes point at the
relevant script.

---

## 1. Portals

**Fantasy:** the ship is threaded with fixed, glowing rings that fold distance.

**Rules**
- **Fixed placement.** Portals are grown into the ship — level-authored, not player-placed.
  (This differs from *Portal*'s player gun; placement is a design tool, not a resource.)
- **Bidirectional.** Every portal is paired with exactly one partner; travel works both
  ways.
- **Walk through** — instant traversal between distant areas.
- **Look through** — the partner's view renders on the portal surface; you can see what's
  on the other side before committing.
- **Shoot through** — projectiles carry through with remapped direction. At a bad angle you
  can shoot *yourself* — a real risk and a skill expression.
- **Combat use** — flank enemies, attack from impossible angles, retreat instantly.

**Transform math (reference)**
Teleport maps the traveler from the entry portal's frame to the partner's frame, rotated
180° about the portal's up axis (you exit *facing out*):

```
flip = rotate 180° about portal.up
exit_transform = partner.global_transform * flip * entry.global_transform.inverse() * traveler.global_transform
exit_velocity  = (partner.basis * flip * entry.basis.inverse()) * traveler.velocity
```

A short per-portal cooldown after a teleport prevents immediate re-triggering at the exit.

**Prototype:** `scripts/portal.gd` implements all three behaviours. **Walk through** —
teleport with orientation & velocity remapped. **Shoot through** — the trigger catches
projectiles (`scripts/projectile.gd`) and carries them to the partner; a bad angle really
can send one back into you. **Look through** — a `SubViewport` + a virtual camera mirror
the player's eye through the partner portal and render it onto the surface (via a screen-UV
shader); sheets sit on a separate visual layer so the virtual cameras don't recurse.

---

## 2. Localized gravity

**Fantasy:** gravity is a property of a *place*. The ship has no single "down."

**Forms**
- **Gravity paths / walkways.** Lit strips that let you walk "upright" relative to the path
  even as it climbs a wall or crosses a ceiling. Jump or step off and normal gravity
  reasserts — you fall.
- **Gravity switches.** Shootable devices that flip a region's pull. Often asymmetric: they
  affect the player but not the enemies (or vice-versa), which is itself a puzzle.
- **Planetoids.** Small bodies floating inside the ship carry their own **radial** field —
  walk all the way around the outside.

**Implementation model**
Give the player a `current_up` vector instead of assuming world-up:
- Gravity accelerates along `-current_up`.
- Jump impulses along `+current_up`.
- Horizontal movement lives in the plane perpendicular to `current_up`.
- The body's orientation **slerps** toward the target up so transitions read smoothly
  rather than snapping.
- A gravity region sets the target up: a fixed vector (path/switch) or a computed one
  (`(pos - planet_center).normalized()` for radial).

**Prototype:** all three forms. `scripts/player.gd` carries the re-orientable-gravity
model. `scripts/gravity_planet.gd` is a radial planetoid you can circumnavigate (with its
own weaker, moon-like field). `scripts/gravity_path.gd` is a lit walkway you ride straight
up a wall to a ledge. `scripts/gravity_switch.gd` + `scripts/gravity_region.gd` are a
shootable switch that flips a room's pull so you fall to what was the ceiling.

---

## 3. Merkavah — spirit projection

**Fantasy:** the mystic's ascent. Abby leaves her body to walk higher planes.

**Rules**
- **Detach** your spirit for a **limited time**; when it runs out you're pulled back.
- In spirit form you can:
  - **Free-fly** and **walk walls and ceilings**, ignoring normal collision constraints.
  - **Scout ahead** and **reveal** hidden paths/solutions invisible to the physical body.
  - **Interact** with spirit-only elements (panels, **spirit locks**).
  - Use a **spirit blade** to strike certain enemies/objects.
- **Your body is left behind and vulnerable.** This is the core tension: a spirit puzzle is
  also a question of *where is it safe to leave the body?*

**Design value**
The canonical spirit play: leave the body somewhere safe, spirit-walk to solve a puzzle or
set up an ambush, return, and execute. It is the game's best generator of "leave/return"
tension and of asymmetric combat setups.

**Prototype:** `scripts/player.gd` handles the spirit state — free-fly camera, timer,
floor clamp, and a **body tether** (you can't drift beyond a set range: the body really is
a leash). It also carries the **spirit blade** (a short cone-slash that only harms
spirit-vulnerable drones). `scripts/spirit_lock.gd` is a spirit-only lock that opens a
sealed door; `scripts/spirit_reveal.gd` is a bridge invisible to the body until the spirit
gets close, then it turns solid so the body can cross.

---

## 4. Composition — where the game actually lives

The mechanics are designed to be multiplied, not listed. A "two-verb minimum" guides
puzzle design; the best moments use all three.

**Worked examples**

- **Ceiling portal.** A portal sits on a ceiling. You can't reach it — until you cross a
  gravity switch that flips the room; now the ceiling is your floor and the portal is at
  eye level.
- **Spirit-gated shortcut.** A portal is inert until a spirit lock behind a wall is tripped.
  Leave your body on a gravity path, spirit-walk the wall to the lock, trip it, return,
  ride the portal.
- **Trick-shot ambush.** In spirit form you scout a drone patrol and note a portal that
  exits behind them. Return, shoot *through* the portal, hit them from an angle they can't
  read.
- **Planetoid puzzle.** Walk around a planetoid to a portal on its "underside" that only
  lines up when you approach along the surface — impossible to reach in straight-line,
  fixed-gravity space.

**The prototype sandbox** now exercises every verb in the triad across one arena: a
planetoid to circle, a wall to walk up, a room whose gravity you flip by shooting a switch,
a portal pair you can look/step/shoot through (with a drone to tag through it), a
spirit-gated sealed room, and a spirit-revealed bridge guarded by a spirit-only drone. Two
supporting systems back them up — a **weapon/projectile** (for shoot-through and the
switch) and **resurrection** (fall out, or shoot yourself through a portal, and you return
to your last spawn after a brief death-walk). Enough to feel all three verbs interlock.
