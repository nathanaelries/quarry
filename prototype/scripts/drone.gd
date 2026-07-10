extends StaticBody3D
## Quarry prototype — a dummy drone target.
##
## Something to shoot at / slash. Configure `vulnerable_to` before adding it to the
## tree: "physical" (only the weapon hurts it), "spirit" (only the spirit blade), or
## "both". A spirit-only drone reads purple; a normal one reads red.

var health := 2
var vulnerable_to := "both"       # "physical" | "spirit" | "both"

var _mat: StandardMaterial3D
var _base_color := Color(0.85, 0.2, 0.25)


func _ready() -> void:
	add_to_group("drones")
	if vulnerable_to == "spirit":
		_base_color = Color(0.6, 0.35, 0.95)
		add_to_group("spirit_targets")

	var mesh := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = Vector3(0.9, 1.4, 0.9)
	mesh.mesh = m
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = _base_color
	_mat.emission_enabled = true
	_mat.emission = _base_color * 0.4
	mesh.material_override = _mat
	add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.9, 1.4, 0.9)
	col.shape = shape
	add_child(col)


func take_hit(amount: int, kind: String) -> void:
	if vulnerable_to != "both" and kind != vulnerable_to:
		_flash(Color(0.5, 0.5, 0.55))     # resistant — sparks but no damage
		return
	health -= amount
	if health <= 0:
		_die()
	else:
		_flash(Color(1, 1, 1))


func _flash(c: Color) -> void:
	_mat.emission = c
	var tw := create_tween()
	tw.tween_property(_mat, "emission", _base_color * 0.4, 0.3)


func _die() -> void:
	set_deferred("collision_layer", 0)    # stop registering further hits
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.2)
	tw.tween_property(_mat, "emission", Color(2, 2, 2), 0.1)
	tw.chain().tween_callback(queue_free)
