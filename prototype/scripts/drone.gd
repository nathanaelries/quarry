extends StaticBody3D
## Quarry prototype — a dummy drone target that drops loot.
##
## Configure before adding to the tree:
##   • vulnerable_to : "physical" | "spirit" | "both"
##   • rank          : "junior" | "middle" | "senior"  (more/richer loot, more HP)
##
## The KILL METHOD decides the loot (BOTW's condition mechanic): a physical kill
## yields salvage; a spirit-blade kill strikes the soul and yields spirit essence.
## A spirit-only drone reads purple; a normal one reads red.

var vulnerable_to := "both"
var rank := "junior"

var _health := 2
var _last_kind := "physical"
var _mat: StandardMaterial3D
var _base_color := Color(0.85, 0.2, 0.25)

const RANK_HP := {"junior": 2, "middle": 3, "senior": 4}
const RANK_SCALE := {"junior": 0.85, "middle": 1.0, "senior": 1.2}


func _ready() -> void:
	add_to_group("drones")
	if vulnerable_to == "spirit":
		_base_color = Color(0.6, 0.35, 0.95)
	if vulnerable_to != "physical":
		add_to_group("spirit_targets")     # both/spirit can be slashed
	_health = RANK_HP.get(rank, 2)
	var s: float = RANK_SCALE.get(rank, 1.0)

	var mesh := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = Vector3(0.9, 1.4, 0.9) * s
	mesh.mesh = m
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = _base_color
	_mat.emission_enabled = true
	_mat.emission = _base_color * 0.4
	mesh.material_override = _mat
	add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.9, 1.4, 0.9) * s
	col.shape = shape
	add_child(col)


func take_hit(amount: int, kind: String) -> void:
	if vulnerable_to != "both" and kind != vulnerable_to:
		_flash(Color(0.5, 0.5, 0.55))     # resistant — sparks but no damage
		return
	_last_kind = kind
	_health -= amount
	if _health <= 0:
		_die()
	else:
		_flash(Color(1, 1, 1))


func _flash(c: Color) -> void:
	_mat.emission = c
	var tw := create_tween()
	tw.tween_property(_mat, "emission", _base_color * 0.4, 0.3)


func _die() -> void:
	var pool := "drone_essence" if _last_kind == "spirit" else "drone_salvage"
	Loot.spawn_drops(pool, global_position, rank)

	set_deferred("collision_layer", 0)    # stop registering further hits
	remove_from_group("spirit_targets")
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.2)
	tw.tween_property(_mat, "emission", Color(2, 2, 2), 0.1)
	tw.chain().tween_callback(queue_free)
