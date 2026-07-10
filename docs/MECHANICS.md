# Quarry — The Mechanic Triad

The whole game hangs on three verbs that are interesting alone and *combinatorial*
together: **portals**, **localized gravity**, and **Merkavah spirit projection**. This
doc specifies each at an implementable level and — most importantly — how they compose.

The [`prototype/`](../prototype/) implements a first pass of all three; per-mechanic
implementation notes point at the relevant script.

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

**Prototype:** `scripts/portal.gd` — working teleport with remapped velocity, an emissive
ring, a trigger volume, and a cooldown. (See-through rendering via `SubViewport` is noted
as the next step; the prototype ships the reliable teleport first.)

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

**Prototype:** `scripts/player.gd` implements re-orientable gravity;
`scripts/gravity_planet.gd` is a radial planetoid you can circumnavigate.

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

**Prototype:** `scripts/player.gd` handles the spirit state (free-fly camera, timer,
return); `scripts/spirit_lock.gd` is a spirit-only lock that opens a sealed door.

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

**The prototype sandbox** stitches a minimal version of these together: a planetoid to
circle, a portal to a ledge, and a spirit-gated door — enough to feel the verbs interlock.
