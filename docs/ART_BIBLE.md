# Quarry — Art Bible

> **Status: art *direction*, not art production.** This is the visual source of truth.
> Level design, UI, VFX, materials, and any future 3D all inherit from it. Explore on
> paper; commit to polygons only once a slice is proven fun. Cultural guardrails: [DESIGN.md §9](DESIGN.md).

Companion visuals live in [`art/`](art/) (editable SVG) and in the shareable Art Bible
page (published as an Artifact — link kept with the project).

---

## 1. The thesis — one sentence

**Quarry looks like a living sacred painting of a ship:** the ink-and-gold spirit worlds of
**Ōkami** fused with the bright, expressive, cel-shaded adventure of **The Wind Waker**,
wrapped around a **biomechanical vessel whose anatomy *is* the Kabbalistic Tree of Life.**

Nothing in this game is grey and grim. Even horror is beautiful here — rendered in ink,
bone, and gold, not gore.

---

## 2. What we pull from each reference

We are not copying either game; we are borrowing specific, nameable qualities.

### Ōkami — *the sacred, the ink, the bloom*
- **Sumi-e linework:** confident calligraphic brush outlines; lines that taper and swell.
- **Washi-paper ground:** a faint paper grain over everything, so the world reads as
  *painted*, not photographed.
- **Divine energy as ink & bloom:** powers manifest as blossoming ink, petals, and gold
  light — not sci-fi lens flare.
- **Limited-but-vivid palette + gold leaf:** few colors, high intent, sacred gold accents.
- **The world reacts to the sacred:** dead things bloom where power touches them.

> Pull specifically from: Celestial Brush ink strokes, Konohana blooms, Shinshū Field's
> palette, the gold-outlined celestial beings, the washi texture over cutscenes.

### The Wind Waker — *the charm, the read, the pop*
- **Cel shading:** flat color fills in clean bands + expressive, weighty **ink outlines**.
- **Silhouette-first design:** every ship, creature, and prop reads as a bold shape from
  across the room.
- **Warm, inviting color** even in danger — earnest adventure, a little whimsy.
- **Toon lighting & particle pop:** wind-lines, sparkles, big readable "poofs" of effect.
- **Expressive economy:** huge emotion from simple, exaggerated shapes.

> Pull specifically from: the toon outline + flat-material look, the King of Red Lions'
> shape economy, expressive eyes, wind/particle feedback, the warm sea palette.

### Biomechanical — *the body of the ship*
- Organic-mech hybrid: **sinew + chitin plating + veins of light.** Grown, not built.
- De-gore'd: take H.R. Giger's *architecture* (ribbed corridors, organ-chambers,
  fused forms) but render it in ink and bone so it's **awe, not disgust.**

### Kabbalah — *the meaning and the anatomy*
- The **Tree of Life (Etz Chaim):** 10 *sefirot* nodes + 22 connecting paths.
- **Merkavah / the Chariot:** the star-tetrahedron "engine," the ascent motif.
- **Sacred geometry:** Flower of Life, nested circles, precise symmetry.
- **Hebrew letter-runes:** the 22 letters glow along the ship's veins like living circuitry.
- Treated as **sacred and accurate**, never as decoration or gibberish (see §9 of DESIGN.md
  — engage cultural/religious consultants before production).

---

## 3. The fusion — how they become one thing

The idea that makes Quarry *Quarry*:

> **The Cylinder's power system is literally the Tree of Life.** Ten great glowing organs
> (the *sefirot*) sit in the hull, joined by 22 luminous vein-paths that pulse with the
> life the ship harvests. Hebrew letter-runes flow along the veins like circuitry.
> **Sacred geometry is the ship's anatomy, not its wallpaper.**

So a corridor is a rib-vault of chitin and bone, ink-outlined, with a gold vein of stolen
life running its spine and a faint rune-glyph flaring as you pass. A boss chamber is a
sefirah — a cathedral-organ of light. Abby's powers answer in Ōkami ink-bloom and gold.

---

## 4. Two worlds, two renders (this is a mechanic, not just a mood)

The physical/spirit split ([MECHANICS.md](MECHANICS.md) §3) gets a **visual identity** that
doubles as gameplay legibility:

| | **Physical** (Assiah — World of Action) | **Spirit / Merkavah** (ascending toward Atzilut — Emanation) |
|---|---|---|
| Feel | grounded, warm, "Wind Waker" | ethereal, luminous, "Ōkami spirit realm" |
| Outlines | thick, confident ink | dissolving into brushstroke & bloom |
| Color | fuller cel color | desaturated toward gold + pale blue |
| Light | toon key + warm bounce | bloom-heavy, gold ascent light, paper grain rises |
| Hidden things | unseen | reveal as glowing ink (spirit-only paths, runes) |

The moment you press **F**, the whole frame should shift toward the sacred. That transition
is a signature shot.

---

## 5. Color system

A tight palette with **intent per color**. These hexes are the canonical values — they also
**reconcile the prototype's greybox accents** (cyan portals, orange gravity, purple spirit,
green goals, red drones) into a meaning, so the placeholder colors already point here.

**Neutrals / ground**
| Role | Hex | Notes |
|---|---|---|
| Ink Black | `#12161B` | sumi-e outlines, deepest shadow |
| Hull Slate | `#33414D` | chitin & plate base |
| Bone Ivory | `#D8C9A6` | plating midtone |
| Washi Paper | `#EDE3CC` | paper ground / light plating |

**Life & warmth — the harvested "sap" (and gravity fields)**
| Role | Hex | Reconciles |
|---|---|---|
| Amber Sap | `#F2A93C` | greybox **orange** (gravity) → life flowing in veins |
| Ember Gold | `#D98A2B` | vein shadow |

**Sacred / spirit / Merkavah — the ascent, World of Emanation**
| Role | Hex | Reconciles |
|---|---|---|
| Emanation Gold | `#FFE39A` | divine light, gold leaf |
| Merkavah Violet | `#B79BFF` | greybox **purple** (spirit) |
| Ascent Blue | `#8FB6FF` | ethereal cool |

**Fold-space — portals (cool sacred tech)**
| Role | Hex | Reconciles |
|---|---|---|
| Portal Cyan | `#4FD4E0` | greybox **cyan** (portals) |
| Deep Teal | `#1E6E78` | portal rim/shadow |

**Harvest & hostility**
| Role | Hex | Reconciles |
|---|---|---|
| Harvest Green | `#7FBF6B` | greybox **green** (goals) → seeded/harvested life |
| Drone Crimson | `#E0564B` | greybox **red** (hostile drones) |

**Metal**
| Role | Hex | Notes |
|---|---|---|
| Gold Leaf | `#D9A441` | sacred-geometry frames, sefirot haloes |

**Rules of use**
- **Warm = life & the sacred; cool = fold-space & the ascent.** Don't cross the wires.
- Gold is *earned* — reserve it for sacred geometry, sefirot, and Abby's power. Never trim.
- Keep any single frame to ~2 accents over the neutral ground. Vividness comes from
  restraint, not saturation everywhere.

---

## 6. Shape language & silhouette

- **Sinew vs. star:** every hero form contrasts a soft organic mass against crisp sacred
  geometry. Bulbous organ-chambers *bound* by hard geometric frames and radiating lattices.
- **The Merkavah star-tetrahedron** is the recurring "engine/heart" silhouette — spin it,
  frame with it, build spirit-blade and portal VFX from it.
- **Sefirot spheres** in a Tree lattice = the ship's read-at-a-glance signature.
- **Drones:** harvested-humanoid silhouettes with a caged Merkavah core where the heart was.
- **Abby:** Wind-Waker-readable proportions — a practical mechanic's build (boots, tool
  belt, rolled sleeves) with one thread of the sacred (a gold cord, a rune-mark).
- Test every design as a **flat black silhouette first.** If it doesn't read, redesign.

See [`art/silhouettes.svg`](art/silhouettes.svg) and
[`art/cylinder-tree.svg`](art/cylinder-tree.svg).

---

## 7. Rendering approach (how we'd hit this in Godot, later)

Direction, not a task list — but it keeps the bible technically honest:
- **Toon/cel shading:** banded diffuse via a light ramp; 2–3 bands.
- **Ink outlines:** inverted-hull or a screen-space edge-detect (depth+normal) post pass.
- **Washi grain:** a subtle paper texture multiplied in a full-screen post shader.
- **Everything sacred emits:** veins, runes, sefirot, portals, spirit — all on emission,
  read through **WorldEnvironment glow/bloom.**
- **Spirit mode = a post-process state:** desaturate, push gold tint, raise bloom + paper
  grain, thin the outlines. One toggled screen shader sells the whole "ascent."
- Author cel **ramps** and a small set of **matcap-ish** sacred materials rather than
  photoreal PBR.

---

## 8. VFX & motion language

- **Powers = ink bloom** (Ōkami): spirit projection blossoms out in ink and gold; the
  spirit blade is a single calligraphic stroke.
- **Feedback = toon pop** (Wind Waker): wind-lines on dashes, sparkle bursts on pickups,
  fat readable "poofs" on impact.
- **Sacred tech = geometry:** portals open as a rotating Merkavah + Flower-of-Life ring;
  gravity fields shimmer as faint sacred-geometry lattices; runes flare then fade.
- Motion is **weighty but graceful** — big anticipation, clean follow-through, never floaty.

---

## 9. UI direction

- **Parchment + ink + gold leaf.** Panels are washi cards with brush borders; frames use
  gold sacred-geometry corners.
- **Diegetic where possible:** the spirit meter is a **sefirah node filling with light**;
  health/return is ink draining and re-inking.
- **Type:** a warm humanist face for body; sacred accents may use *respectful, correct*
  Hebrew letterforms (consulted — never decorative gibberish).
- Minimal, calm, sacred — the opposite of busy sci-fi HUDs.

---

## 10. Do / Don't guardrails

**Do**
- Treat Kabbalah motifs as sacred, accurate, and intentional; consult from pre-production.
- Silhouette-test everything; keep the palette disciplined; keep gold earned.
- Keep the ink-and-bloom beauty even in the ship's most hostile, harvested places.

**Don't**
- Photoreal gore/horror — we're ink and bone, awe not disgust.
- Hebrew (or any sacred symbol) as random decoration or wallpaper.
- Muddy, desaturated "gritty sci-fi" — that is the exact opposite of Quarry.
- Lose readability to detail. Detail serves the silhouette, never buries it.

---

## 11. What inherits from this (downstream)

- **Level design:** spaces are organs and rib-vaults threaded by the Tree's veins; the
  sefirot are landmarks and boss arenas.
- **UI/VFX:** §8–9 above.
- **Greybox → art:** the placeholder accent colors already map to §5, so re-skinning is a
  translation, not a redesign.
- **The signature shot** to chase in any first art test: a rib-vault corridor, gold vein
  down its spine, a rune flaring — then press **F** and watch it bloom into the spirit world.
