# Quarry — Camera, Character & Animation

> Quarry plays in **first person** and toggles to a **Gears-of-War-style over-the-shoulder**
> view. Because OTS shows Abigail full-body most of the time, her model + animation set are
> **core**, not deferrable. This doc covers the camera rig, the proxy stand-in, and the
> animation scaffold that a real rigged model plugs into. Implemented in `scripts/player.gd`.

## Camera: first-person ⇄ over-the-shoulder

Press **V** to toggle. The rig is built under the player's `head` (which carries mouse
*pitch*; *yaw* is on the body so it re-orients with gravity — you keep the camera on walls
and planetoids):

```
head (pitch)
 ├─ camera            ← first-person eye
 └─ ots_pivot         ← shoulder offset (right + up, OTS_OFFSET)
     └─ ots_spring    ← SpringArm3D, pulls the camera in past walls (excludes the player)
         └─ ots_camera ← over-the-shoulder eye (trails OTS_DISTANCE behind)
```

- **First person:** the eye camera; the body is hidden.
- **OTS:** the spring-arm camera over the right shoulder (Abigail sits screen-left, Gears
  style); the body is shown. The **`SpringArm3D`** shape-casts so the camera slides in when a
  wall is behind you.
- Both share the same yaw/pitch, so movement stays camera-relative and gravity re-orientation
  just works. Spirit mode keeps its own free-fly camera; leaving spirit returns you to
  whichever physical view you had.
- Camera shake is applied per-view (the OTS camera's position is owned by the spring arm, so
  its shake rides on the pivot).

Tunables in `player.gd`: `OTS_OFFSET` (shoulder), `OTS_DISTANCE` (trail). Not yet: aim-zoom,
cover-snap, roadie-run — later Gears-kit combat features.

## The Abigail proxy

`_build_proxy_body()` builds a simple humanoid **blockout** from primitives (torso, hips,
limbs, head, a cyan visor marking the front, a chest emblem) sized to the collision capsule.
It's a **stand-in** so OTS reads orientation and framing immediately — **replace it with
Abigail's rigged model.**

## Animation scaffold

There are no animation clips yet (that's authored art — Blender/Mixamo/mocap). What exists is
the **harness** a real `AnimationTree` / `AnimationPlayer` will consume, so dropping in clips
is wiring, not surgery. The player emits:

| Signal | Payload | Use |
|---|---|---|
| `anim_state_changed(state)` | `idle` · `run` · `air` · `dash` · `spirit` · `dead` | drive a **locomotion blend** / state machine |
| `anim_event(name)` | `fire` · `blade` · `parry` · `dash` · `jump` · `hurt` | fire **one-shot** action clips |

Until clips exist, the proxy just leans into movement so OTS isn't lifeless.

## Dropping in Abigail's real model (later)

1. Model + rig + animation clips in a DCC tool; export **glTF** (`.glb`).
2. Import into `res://`; the imported scene has a `Skeleton3D` + `AnimationPlayer`.
3. Replace the proxy: instance her scene under the player in place of `body_rig`; align the
   skeleton so feet ≈ y-0.9, head ≈ y+0.9 (collision-capsule space).
4. Add an `AnimationTree` (a locomotion **BlendSpace** for idle→run + one-shots) and connect
   it to `anim_state_changed` / `anim_event`.
5. In first person you may swap her body for a **first-person arms/weapon** rig; in OTS/spirit
   the full body shows.

## Priorities (revised)

Abigail is **not** low-priority — she's on screen constantly in OTS. Sensible order:
**camera (done)** → proxy + scaffold (done) → look-dev render pipeline → produce her model +
clips → plug in via the scaffold → polish. Enemy (drone) models can follow the same pipeline.
