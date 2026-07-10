extends Node3D
## Quarry prototype — a fixed portal.
##
## Portals come in linked pairs. Walk into one and you are teleported to its
## partner, facing outward, with your velocity remapped through the pair.
##
## This is the reliable-traversal first pass. "Look through" / "shoot through"
## (rendering the partner's view onto the surface via a SubViewport) is the
## documented next step — see docs/MECHANICS.md.
##
## Set `linked` and `player` after instancing (world.gd does this).

var linked: Node3D = null
var player: CharacterBody3D = null
var color := Color(0.35, 0.85, 1.0)

var _cooldown := 0.0
const COOLDOWN := 0.6


func _ready() -> void:
	_build_ring()
	_build_trigger()


func _build_ring() -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.0
	torus.outer_radius = 1.2
	ring.mesh = torus
	# TorusMesh lies flat (hole along +Y); stand it up so the hole faces local +Z.
	ring.rotation_degrees.x = 90.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	ring.material_override = mat
	add_child(ring)

	# A faint "sheet" filling the ring so the portal reads as a surface.
	var sheet := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	sheet.mesh = quad
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(color.r, color.g, color.b, 0.22)
	smat.emission_enabled = true
	smat.emission = color
	smat.emission_energy_multiplier = 0.4
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sheet.material_override = smat
	add_child(sheet)


func _build_trigger() -> void:
	var area := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.0
	shape.height = 0.8
	col.shape = shape
	col.rotation_degrees.x = 90.0    # thin axis along local Z (the portal normal)
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body != player or linked == null:
		return
	if _cooldown > 0.0:
		return
	_teleport(body)


func _teleport(body: CharacterBody3D) -> void:
	var flip := Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	var rel := linked.global_transform * flip * global_transform.affine_inverse()
	body.global_transform = rel * body.global_transform
	body.velocity = rel.basis * body.velocity

	# Prevent an instant bounce-back at the exit portal.
	_cooldown = COOLDOWN
	if linked.has_method("start_cooldown"):
		linked.start_cooldown()


func start_cooldown() -> void:
	_cooldown = COOLDOWN


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
