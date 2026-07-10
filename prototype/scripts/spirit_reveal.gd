extends Node3D
## Quarry prototype — a spirit-revealed bridge.
##
## Invisible and intangible to the physical body (only a faint shimmer hints at it).
## Project your spirit and fly close, and it resolves into something solid and lit —
## a path the body can then walk. "Scout in spirit, reveal the way, cross in the flesh."
##
## Set `player` before adding to the tree.

var player: Node = null
var span_size := Vector3(3.5, 0.4, 2.5)
var reveal_radius := 3.5

var revealed := false
var _mat: StandardMaterial3D
var _col: CollisionShape3D


func _ready() -> void:
	var body := StaticBody3D.new()
	_col = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = span_size
	_col.shape = shape
	_col.disabled = true                       # intangible until revealed
	body.add_child(_col)
	add_child(body)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = span_size
	mesh.mesh = box
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.5, 0.4, 0.9, 0.07)   # barely-there shimmer
	_mat.emission_enabled = true
	_mat.emission = Color(0.4, 0.3, 0.8)
	_mat.emission_energy_multiplier = 0.12
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = _mat
	body.add_child(mesh)


func _process(_delta: float) -> void:
	if revealed or player == null:
		return
	if player.in_spirit and player.spirit_pivot.global_position.distance_to(global_position) < reveal_radius:
		_reveal()


func _reveal() -> void:
	revealed = true
	_col.disabled = false                      # now solid — the body can cross
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_mat, "albedo_color", Color(0.6, 0.5, 0.95, 1.0), 0.4)
	tw.tween_property(_mat, "emission_energy_multiplier", 0.7, 0.4)
