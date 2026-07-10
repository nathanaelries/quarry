# Quarry — Game Design Document

> Status: concept + vertical-slice prototype. Living document.

Quarry is a first-person action-adventure about a woman abducted onto a living,
world-devouring starship, who fights back by awakening ancestral powers rooted in Jewish
mystical tradition. It is an **original work inspired by** the systems design of *Prey*
(2006) — the interlock of portals, localized gravity, and spirit projection — re-themed
and re-imagined with new characters, world, and fiction.

---

## 1. Vision & pillars

**One line:** *Abducted onto a living planet-harvester, a reluctant heir turns her
heritage into power — bending gravity, stepping through portals, and walking the world as
a spirit — to tear the ship apart from the inside.*

Four design pillars everything is measured against:

1. **The triad is the game.** Portals + localized gravity + spirit projection interlock.
   No mechanic ships as a gimmick; every space and encounter should want at least two of
   them.
2. **The ship is a character.** The Cylinder is alive — it shifts, consumes, and adapts.
   The player should always feel *inside something*, never on a set.
3. **Heritage as power, handled with respect.** Powers are drawn from real tradition. They
   are treated as sacred and earned, never as loot.
4. **Death is a verb, not a wall.** Resurrection is a mechanic. Bold, experimental play is
   the intended play.

---

## 2. The mechanic triad (summary)

Full detail in [MECHANICS.md](MECHANICS.md). In brief:

- **Portals** — fixed, grown-in rings. Bidirectional. You can walk through, look through,
  and shoot through them (including the risk of shooting *yourself* at a bad angle). Used
  for traversal and for creative combat angles.
- **Localized gravity** — gravity is a property of a region, not the world. Lit **gravity
  paths** let you walk "upright" up walls and across ceilings; step off and normal gravity
  reasserts. Shootable **gravity switches** flip a room's pull (often affecting the player
  but not enemies, or vice-versa). Small **planetoids** inside the ship carry their own
  radial fields — walk all the way around them.
- **Merkavah (spirit projection)** — detach your spirit for a limited time. In spirit form
  you can walk walls and ceilings, pass certain barriers, wield a **spirit blade**, reveal
  hidden solutions, and scout. Your body is left behind and **vulnerable**. This is the
  central risk/reward and puzzle verb.

**Supporting systems:** resurrection (see §5), a small weapon set mixing grounded and
alien arms, a flying shuttle vehicle for large chambers, and puzzles that are almost
always a *combination* of the three core verbs.

---

## 3. Setting: The Cylinder

A vast organic-technological starship — fleshy, biomechanical architecture laced with
metal and alien tech. It seeds life across the galaxy, then returns to harvest it,
grinding conquered species into mindless **drones**. Its interior holds:

- Cavernous chambers on a scale that dwarfs the player.
- Floating **planetoids** with their own gravity.
- Districts of harvested species, repurposed as drone labor.
- Regions that are visibly *alive* — breathing, wet, hostile.

The ship is run by **The Mother**, a telepathic entity who was once human. Full world and
faction detail in [STORY.md](STORY.md).

---

## 4. Story (summary)

Full spoilers and character detail live in [STORY.md](STORY.md). The spine:

- **Abigail "Abby" Koval** — an Israeli-American mechanic and former U.S. Army soldier in
  Miami — is abducted, along with her boyfriend **Ben** and her grandfather **Elias**,
  when their building is lifted into the sky.
- Freed by a cybernetic **Stranger**, she watches Elias die in an alien machine. In a
  near-death crossing into the **World of Emanation**, his spirit grants her ancestral
  powers and charges her to protect Earth. Her own driving goal stays personal: reach Ben.
- She finds Ben fused to an alien host and must mercy-kill him. She learns the ship's
  purpose, joins **The Remnant** resistance (led by **Eliana**), and confronts The Mother.
- **Climax choice:** become the new Mother and rule the ship, or destroy it. In the
  canonical ending she pilots the Cylinder into the sun, dies, and resurrects on Earth
  months later — with a deliberate sequel hook.

**Tone:** tense sci-fi horror + action + spiritual empowerment; bittersweet, with real
stakes and real loss.

---

## 5. Systems detail

### 5.1 Resurrection ("the return")
Death is not a hard fail. When Abby falls, her spirit is cast into a brief liminal space;
she returns to her body after a short beat. During the return she can sometimes *improve*
the state she comes back in (a mini-interaction that rewards attention). Effects:

- Removes the fear tax on experimentation — the triad *wants* reckless combinations.
- Reframes checkpoints as story, not UI.
- Difficulty is tuned around resurrection existing, not around it being a crutch.

### 5.2 Combat
- A compact arsenal: a few grounded firearms and a few alien weapons with genuinely
  different properties (not reskins).
- **Environmental combat is first-class:** shoot *through* portals, use gravity switches to
  drop enemies, lure drones into hazards, set spirit-form ambushes.
- Enemies read the space differently than you do — some ignore gravity flips, some can't
  follow through portals — which is itself a puzzle.

### 5.3 Progression — the Tree
Powers deepen along a structure themed on the **Sefirot** (the ten emanations of the
Kabbalistic Tree of Life). Each unlock is diegetic — granted by spirits, earned in the
World of Emanation — never bought. Example axes:

- Spirit duration & the spirit blade.
- Gravity mastery (manual flips, path-walking control).
- Portal interaction (stabilizing, redirecting, shooting through more reliably).

### 5.4 Vehicle
A versatile flying **shuttle** for the ship's largest chambers — used for both traversal
and vehicle combat, and to reach planetoids.

---

## 6. Puzzle & level design philosophy

- **Two-verb minimum.** A good Quarry puzzle needs at least two of {portal, gravity,
  spirit}. Example: leave your body on a gravity path, spirit-walk the ceiling to trip a
  lock that opens a portal, return to the body, ride the portal through.
- **Legibility first.** Portals glow; gravity paths are lit lines; spirit-only elements
  have a distinct treatment visible only (or best) in spirit form. The player should read
  the *possibility* of a space before they solve it.
- **The ship teaches by mutating.** New verbs are introduced by the environment changing
  around the player, not by tutorial pop-ups.

---

## 7. Art & atmosphere

- Organic, grotesque, awe-inspiring interiors; biomechanical + metal + alien.
- Lighting carries the language: glowing portal rings, lit gravity paths, an ethereal
  treatment for spirit form.
- Signature set-pieces: the opening abduction; large-scale battles across planetoids; the
  descent into the sun.

---

## 8. Themes

- **Heritage & identity** — Abby begins cynical about her culture and ends drawing power
  from it.
- **Resistance to eradication and exploitation.**
- **What it means to stay human when offered god-like power.**
- **Family, loss, legacy.**
- **The horror of being harvested vs. the empowerment of fighting back with inherited
  knowledge.**

---

## 9. Cultural authenticity (non-negotiable)

Quarry uses Kabbalah, Merkavah mysticism, the Four Worlds, and the Sefirot as the *fiction*
behind its powers. Guidelines for any real development:

- Treat the material as **sacred and earned**, never as generic "magic" or as loot.
- Engage **cultural and religious consultants** and, ideally, creators from the community,
  from pre-production onward — not as a review pass at the end.
- Names, blessings, and iconography are used with intent and accuracy, or not at all.
- The Four Worlds and Sefirot are interpreted respectfully as mythic structure; the game
  does not claim to represent doctrine.

This document and the prototype are a **creative interpretation**, not a religious source.

---

## 10. Editorial notes — reconciliations from the source brief

The originating brief contained transcription corruption and internal contradictions. The
following decisions were made to produce a consistent canon; they are recorded here so the
reasoning is visible and reversible.

- **Protagonist name.** The brief used both "Abigail Koval" and "Abigail Tawodi."
  → Canon: **Abigail "Abby" Koval**. ("Tawodi" is a Cherokee word for hawk — a holdover
  from the *Prey* lineage that inspired this concept — and does not fit the re-theme.)
- **Spirit-guide animal.** The brief named the spirit hawk "Talon" (another *Prey*
  holdover). → Renamed **Aya** (איה, *ayah* — a bird of prey named in the Torah) to fit the
  world. Kept as an optional companion/guide.
- **Grandfather.** Named **Elias Koval**; consistently the spiritual guide who appears as a
  spirit after death.
- **Text corruption.** The source had find/replace artifacts ("Human Shead Studios",
  "publisShed", "Sheavily", "grandfater", "Him" substituted for "her", "AtmoCylinder",
  "etHimeal", etc.). All corrected. The developer/publisher line in the brief described
  *Prey* (2006) itself and is out of scope for Quarry's own canon — retained only as an
  inspiration credit in the README.
- **"The Cylinder"** is retained as the living ship's name (it is the world, and the
  spatial motif of the game).

Open questions worth resolving next: Aya's exact role (guide vs. mechanic), how the
Sefirot map concretely to unlocks, and how much of the Miami framing survives past the
prologue.
