extends Node3D
## Quarry prototype — a planetoid with its own radial gravity field.
##
## While the player is inside the influence radius, "down" points at the
## planet's centre, so you can walk all the way around the outside. Leave the
## field and gravity returns to world-up.
##
## Set `player` after instancing (world.gd does this).

var player: CharacterBody3D = null
var surface_radius := 2.5
var influence_radius := 5.0        # capture field, kept close to the surface so a jump can clear it
var field_gravity := 8.0           # weaker than world gravity (22) — moon-like, jumps launch you off

const RECAPTURE_COOLDOWN := 0.6    # grace period after leaving, so you aren't re-grabbed mid-arc

var _active := false
var _cooldown := 0.0


func _ready() -> void:
	_build_planet()
	_build_field()


func _build_planet() -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = surface_radius
	sphere.height = surface_radius * 2.0
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.82, 0.42, 0.16)
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.12, 0.0)
	mat.emission_energy_multiplier = 0.6
	mesh.material_override = mat
	add_child(mesh)

	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = surface_radius
	col.shape = shape
	body.add_child(col)
	add_child(body)


func _build_field() -> void:
	var area := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = influence_radius
	col.shape = shape
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_enter)
	area.body_exited.connect(_on_exit)


func _on_enter(body: Node) -> void:
	if body == player and _cooldown <= 0.0:
		_active = true


func _on_exit(body: Node) -> void:
	if body == player:
		_active = false
		_cooldown = RECAPTURE_COOLDOWN
		if player:
			player.set_gravity_up(Vector3.UP)


func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if _active and player and not player.in_spirit:
		var up := player.global_position - global_position
		if up.length() > 0.001:
			player.set_gravity_up(up.normalized(), field_gravity)
