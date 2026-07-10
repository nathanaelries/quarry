extends Node3D
## Quarry prototype — a spirit-only lock.
##
## The physical body can't reach or trip this. Only the projected spirit can:
## fly close in spirit form and press Interact to open the linked door. This is
## the "leave the body somewhere safe, spirit-walk to the lock" loop in miniature.
##
## Set `player` and `door` after instancing (world.gd does this).

var player: Node = null
var door: Node3D = null
var radius := 2.0

var _activated := false
var _crystal_mat: StandardMaterial3D


func _ready() -> void:
	var mesh := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.6, 1.0, 0.6)
	mesh.mesh = prism
	_crystal_mat = StandardMaterial3D.new()
	_crystal_mat.albedo_color = Color(0.6, 0.45, 1.0)
	_crystal_mat.emission_enabled = true
	_crystal_mat.emission = Color(0.5, 0.3, 1.0)
	_crystal_mat.emission_energy_multiplier = 1.2
	mesh.material_override = _crystal_mat
	add_child(mesh)


func _process(_delta: float) -> void:
	if _activated or player == null:
		return
	if not player.in_spirit:
		return
	var spirit_pos: Vector3 = player.spirit_pivot.global_position
	if spirit_pos.distance_to(global_position) <= radius and Input.is_action_just_pressed("interact"):
		_activate()


func _activate() -> void:
	_activated = true
	_crystal_mat.albedo_color = Color(0.5, 1.0, 0.6)
	_crystal_mat.emission = Color(0.3, 1.0, 0.4)

	if door:
		# Slide the door down out of the way.
		var tween := create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(door, "position:y", door.position.y - 4.0, 1.0)
