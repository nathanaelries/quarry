// Quarry — ink outlines. A fullscreen 3D post pass: detects silhouette/crease edges
// from the depth + normal buffers and inks them, for the 1960s comic look.
// Forward+ only (needs the normal-roughness buffer). Tunables are exposed as uniforms.
shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest;

uniform float thickness : hint_range(0.5, 3.0) = 1.3;   // outline width, in pixels
uniform float depth_edge : hint_range(0.0, 0.02) = 0.004;
uniform float normal_edge : hint_range(0.0, 2.0) = 0.55;
uniform vec3 ink : source_color = vec3(0.05, 0.04, 0.08);
uniform float ink_amount : hint_range(0.0, 1.0) = 0.9;

void vertex() {
	// Fill the screen regardless of the camera (a fullscreen triangle/quad trick).
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float raw_depth(vec2 uv) {
	return texture(depth_tex, uv).r;
}

vec3 view_normal(vec2 uv) {
	return texture(normal_tex, uv).xyz * 2.0 - 1.0;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = thickness / VIEWPORT_SIZE;
	vec3 col = texture(screen_tex, uv).rgb;

	// Depth discontinuities (silhouettes).
	float dc = raw_depth(uv);
	float dd = abs(dc - raw_depth(uv + vec2(px.x, 0.0)))
		+ abs(dc - raw_depth(uv - vec2(px.x, 0.0)))
		+ abs(dc - raw_depth(uv + vec2(0.0, px.y)))
		+ abs(dc - raw_depth(uv - vec2(0.0, px.y)));
	float e_depth = step(depth_edge, dd);

	// Normal discontinuities (creases).
	vec3 nc = view_normal(uv);
	float nd = (1.0 - dot(nc, view_normal(uv + vec2(px.x, 0.0))))
		+ (1.0 - dot(nc, view_normal(uv - vec2(px.x, 0.0))))
		+ (1.0 - dot(nc, view_normal(uv + vec2(0.0, px.y))))
		+ (1.0 - dot(nc, view_normal(uv - vec2(0.0, px.y))));
	float e_normal = step(normal_edge, nd);

	float edge = clamp(e_depth + e_normal, 0.0, 1.0) * ink_amount;
	ALBEDO = mix(col, ink, edge);
}
