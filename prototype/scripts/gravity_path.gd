extends Area3D
## Quarry prototype — a gravity walkway.
##
## A lit strip laid on a wall. While the player is on it, "down" becomes the wall,
## so you can walk straight up it and across to a ledge. Step off the strip and
## world gravity reasserts — you fall.
##
## Set `player` and `path_up` (the wall's outward normal) before adding to the tree;
## world.gd also orients the node so the strip lies flat on the wall.

var player: CharacterBody3D = null
var path_up := Vector3.UP
var strip_size := Vector3(4.0, 9.0, 0.2)

const RECAP := 0.4

var _on := false
var _cooldown := 0.0


func _ready() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = strip_size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.9, 0.68)
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.85, 0.6)
	mat.emission_energy_multiplier = 0.9
	mesh.material_override = mat
	add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	# Thicker off the surface than the strip so you count as "on it" while walking.
	shape.size = Vector3(strip_size.x, strip_size.y, 1.8)
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node) -> void:
	if body == player and _cooldown <= 0.0:
		_on = true


func _on_exit(body: Node) -> void:
	if body == player:
		_on = false
		_cooldown = RECAP
		if player:
			player.set_gravity_up(Vector3.UP)


func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if _on and player and not player.in_spirit:
		player.set_gravity_up(path_up)
