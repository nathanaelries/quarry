extends StaticBody3D
## Quarry prototype — a breakable loot container.
##
## Shoot it (or, if `spirit_breakable`, slash it in spirit form) to break it and
## spill its pool. Set `pool`, `rank`, and `spirit_breakable` before adding to the
## tree. A salvage crate reads amber; a sacred reliquary reads violet.

var pool := "salvage_crate"
var rank := "junior"
var spirit_breakable := false
var size := Vector3(1.0, 1.0, 1.0)

var _health := 2
var _mat: StandardMaterial3D
var _tint := Color("6a5a3a")


func _ready() -> void:
	add_to_group("containers")
	if spirit_breakable:
		add_to_group("spirit_targets")
		_tint = Color("6a5a8f")

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = _tint
	_mat.emission_enabled = true
	_mat.emission = _tint * 0.4
	mesh.material_override = _mat
	add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	add_child(col)


func take_hit(amount: int, _kind: String) -> void:
	_health -= amount
	if _health <= 0:
		_break()
	else:
		_mat.emission = Color(1, 1, 1)
		var tw := create_tween()
		tw.tween_property(_mat, "emission", _tint * 0.4, 0.25)


func _break() -> void:
	Loot.spawn_drops(pool, global_position + Vector3(0, 0.4, 0), rank)
	Juice.play_3d("break", global_position, -2.0)
	Juice.spark(global_position, _tint.lightened(0.3))
	queue_free()
