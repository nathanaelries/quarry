extends Node3D
## Quarry prototype — a fixed portal (linked pair).
##
## Three of the design's four portal behaviours:
##   • Walk through  — teleport the player, orientation & velocity remapped.
##   • Shoot through — projectiles carry to the partner (see projectile.gd).
##   • Look through  — the partner's view is rendered live onto the surface via a
##                     SubViewport + a virtual camera that mirrors the player's eye.
##
## Set `linked` and `player` after instancing (world.gd does this).

var linked: Node3D = null
var player: Node = null
var color := Color(0.35, 0.85, 1.0)
var see_through := true

const COOLDOWN := 0.6
const VIEW_LAYER := 2                 # sheets live here so virtual cams skip them (no recursion)

var _cooldown := 0.0
var _sub: SubViewport
var _vcam: Camera3D
var _sheet_mat: ShaderMaterial

const VIEW_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D view_tex : source_color;
void fragment() {
	ALBEDO = texture(view_tex, SCREEN_UV).rgb;
}
"""


func _ready() -> void:
	_build_ring()
	_build_view()
	_build_sheet()
	_build_trigger()


func _build_ring() -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.0
	torus.outer_radius = 1.2
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0       # stand it up: hole faces local +Z
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	ring.material_override = mat
	add_child(ring)


func _build_view() -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(640, 360)
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sub.transparent_bg = false
	add_child(_sub)

	_vcam = Camera3D.new()
	_vcam.cull_mask = 1                   # render only layer 1 → never the portal sheets (layer 2)
	_sub.add_child(_vcam)
	_vcam.current = true                  # current *within the SubViewport*, not the main screen


func _build_sheet() -> void:
	var sheet := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	sheet.mesh = quad
	sheet.layers = VIEW_LAYER

	if see_through:
		var sh := Shader.new()
		sh.code = VIEW_SHADER
		_sheet_mat = ShaderMaterial.new()
		_sheet_mat.shader = sh
		_sheet_mat.set_shader_parameter("view_tex", _sub.get_texture())
		sheet.material_override = _sheet_mat
	else:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(color.r, color.g, color.b, 0.25)
		m.emission_enabled = true
		m.emission = color
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		sheet.material_override = m

	add_child(sheet)


func _build_trigger() -> void:
	var area := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.0
	shape.height = 0.8
	col.shape = shape
	col.rotation_degrees.x = 90.0        # thin axis along local Z (the portal normal)
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	area.area_entered.connect(_on_area_entered)


# ---------------------------------------------------------------------------
# Transport
# ---------------------------------------------------------------------------
## Maps a transform from this portal's frame to the partner's, facing out (180° flip).
func get_rel() -> Transform3D:
	var flip := Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	return linked.global_transform * flip * global_transform.affine_inverse()


func _on_body_entered(body: Node) -> void:
	if body != player or linked == null or _cooldown > 0.0:
		return
	var rel := get_rel()
	body.global_transform = rel * body.global_transform
	if "velocity" in body:
		body.velocity = rel.basis * body.velocity
	_cooldown = COOLDOWN
	if linked.has_method("start_cooldown"):
		linked.start_cooldown()


func _on_area_entered(area: Area3D) -> void:
	if linked == null:
		return
	if area.is_in_group("projectiles") and area.has_method("portal_transport"):
		area.portal_transport(get_rel())


func start_cooldown() -> void:
	_cooldown = COOLDOWN


# ---------------------------------------------------------------------------
# Per-frame: cooldown + live look-through camera
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta

	if not see_through or linked == null or player == null:
		return
	var eye: Camera3D = player.get_active_camera() if player.has_method("get_active_camera") else null
	if eye == null:
		return

	# Match the screen so SCREEN_UV sampling lines up, and mirror the player's eye
	# through the *partner* portal so this surface shows what's on the other side.
	var vp_size := Vector2i(get_viewport().get_visible_rect().size)
	if vp_size.x > 0 and vp_size.y > 0 and _sub.size != vp_size:
		_sub.size = vp_size
	_vcam.fov = eye.fov
	_vcam.global_transform = get_rel() * eye.global_transform
