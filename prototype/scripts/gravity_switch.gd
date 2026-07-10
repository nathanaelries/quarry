extends StaticBody3D
## Quarry prototype — a shootable gravity switch.
##
## Shoot it (the projectile calls take_hit) to flip its linked gravity region.
## Set `region` before adding to the tree.

var region: Node = null

var _mat: StandardMaterial3D
var _base := Color(0.95, 0.72, 0.15)


func _ready() -> void:
	add_to_group("switches")

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.2, 1.2, 0.3)
	mesh.mesh = box
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = _base
	_mat.emission_enabled = true
	_mat.emission = _base * 0.7
	_mat.emission_energy_multiplier = 1.2
	mesh.material_override = _mat
	add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.2, 1.2, 0.3)
	col.shape = shape
	add_child(col)


func take_hit(_amount: int, kind: String) -> void:
	if kind != "physical":
		return
	if region and region.has_method("toggle"):
		region.toggle()
	_flash()


func _flash() -> void:
	_mat.emission = Color(1, 1, 1)
	var tw := create_tween()
	tw.tween_property(_mat, "emission", _base * 0.7, 0.35)
