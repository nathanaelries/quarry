// Quarry — comic color post. A fullscreen ColorRect pass over the (inked) 3D frame:
// bold saturation, flat posterized bands, pulp halftone dots, paper grain, vignette.
// Runs below the HUD so the UI stays crisp.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;

uniform float posterize : hint_range(2.0, 16.0) = 6.0;    // color bands (lower = flatter)
uniform float saturation : hint_range(0.6, 2.5) = 1.4;
uniform float halftone_px : hint_range(3.0, 16.0) = 6.0;  // dot cell size in pixels
uniform float halftone_amt : hint_range(0.0, 1.0) = 0.3;  // dot strength in shadows
uniform float grain : hint_range(0.0, 0.25) = 0.05;
uniform float vignette : hint_range(0.0, 1.5) = 0.55;

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(41.31, 289.17))) * 43758.5453); }

void fragment() {
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;

	// Bold saturation.
	float l = luma(col);
	col = clamp(mix(vec3(l), col, saturation), 0.0, 1.0);

	// Flat posterized bands (cel look).
	col = floor(col * posterize + 0.5) / posterize;

	// Pulp halftone: bigger black dots where the image is darker.
	vec2 cell = FRAGCOORD.xy / halftone_px;
	float d = length(fract(cell) - 0.5);
	float radius = 0.55 * (1.0 - luma(col));
	float dot_mask = smoothstep(radius, radius - 0.12, d);   // 1 inside the dot
	col *= mix(1.0, 1.0 - dot_mask, halftone_amt);

	// Static paper grain.
	col += (hash(FRAGCOORD.xy) - 0.5) * grain;

	// Vignette for the dramatic poster framing.
	vec2 v = SCREEN_UV - 0.5;
	col *= 1.0 - vignette * dot(v, v);

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
