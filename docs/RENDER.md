# Quarry — Render Pipeline (look-dev)

> How the **3D** game is rendered toward the **2D 1960s-poster / comic** look of the
> [Art Bible](ART_BIBLE.md). This is the first look-dev pass on the greybox — the foundation
> every future material and asset inherits. Implemented in `scripts/postfx.gd` +
> `shaders/poster_*.gdshader` + the environment in `chambers/chamber_base.gd`.

> ⚠️ **Verify in-editor.** Headless has no GPU, so the shaders can't be compile-checked or
> seen here. Press **P** in-game to A/B the pipeline against the raw greybox.

## The stack

Bottom to top, three layers combine into the look:

1. **Environment** (`chamber_base._build_environment`) — the safe, built-in half:
   - deep space-black background (`#0A0A0F`),
   - **glow/bloom** so the "sacred tech" emissives (veins, portals, spirit, loot) bloom,
   - **saturation + contrast** boosted (`adjustment_*`) for punchy, vibrant color,
   - a strong, warm **directional key** for dramatic poster shadows.

2. **Ink outlines** (`poster_outline.gdshader`) — a fullscreen 3D pass that reads the
   **depth + normal** buffers and inks silhouette/crease edges. This is the #1 comic signal.
   *Forward+ only* (needs the normal-roughness buffer; the project uses Forward+).

3. **Comic color** (`poster_color.gdshader`) — a ColorRect over the frame (below the HUD):
   **posterize** (flat bands), extra **saturation**, pulp **halftone dots** (bigger in shadow),
   **paper grain**, and a **vignette**.

## Controls

- **P** — toggle the whole pipeline on/off (A/B against greybox).

## Tuning (shader uniforms, editable in the editor)

| Shader | Uniform | Does |
|---|---|---|
| outline | `thickness` | outline width (px) |
| outline | `depth_edge` / `normal_edge` | edge sensitivity (lower = more lines) |
| outline | `ink` / `ink_amount` | line color & opacity |
| color | `posterize` | color bands (lower = flatter/bolder) |
| color | `saturation` | punch |
| color | `halftone_px` / `halftone_amt` | dot size & strength |
| color | `grain` | paper grain |
| color | `vignette` | edge darkening |

Select the `OutlineQuad`'s material or the ColorRect's material in the running scene tree
(or edit the `.gdshader` defaults) to dial it in.

## Known limits / next steps

- **Materials are still greybox colors.** The env + post push everything graphic, but a real
  re-skin sets each material to the Art Bible palette (Electric Blue / Fiery Orange / Vibrant
  Yellow / Crimson / Silver·Gold). Biggest remaining visual step.
- **Toon/cel *shading*** is currently approximated by posterizing the final image. A proper
  per-material toon light-ramp (banded diffuse) reads cleaner on curved surfaces — a good
  upgrade once the palette re-skin happens.
- If a fullscreen pass misbehaves on your GPU: the outline quad relies on the depth/normal
  buffers (Forward+); the color pass relies on `hint_screen_texture` under the HUD. Each can
  be disabled independently (hide `OutlineQuad`, or the color `CanvasLayer`).
- Halftone is screen-space (fixed dot size); tie it to view distance later if it "swims."
