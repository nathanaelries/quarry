extends Area3D
## Quarry prototype — a dropped loot pickup.
##
## A floating, rarity-colored mote that pops in, bobs, and is drawn to the player
## when close (BOTW-style), then collected on contact. Set `item` and `count`
## before adding to the tree (loot.gd does this).

var item := ""
var count := 1

const MAGNET_RADIUS := 3.2
const MAGNET_SPEED := 8.0
const COLLECT_RADIUS := 1.1
const LIFETIME := 45.0

var _info := {}
var _mesh: MeshInstance3D
var _t := 0.0
var _base_y := 0.0


func _ready() -> void:
	add_to_group("pickups")
	_info = Loot.item_info(item)
	var color: Color = _info.get("color", Color.WHITE)

	_mesh = MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = 0.16
	m.height = 0.32
	_mesh.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.6
	_mesh.material_override = mat
	add_child(_mesh)

	var light := OmniLight3D.new()
	light.light_color = color
	light.omni_range = 2.6
	light.light_energy = 1.1
	add_child(light)

	var col := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = COLLECT_RADIUS
	col.shape = sh
	add_child(col)

	body_entered.connect(_on_body_entered)
	_base_y = global_position.y

	scale = Vector3.ONE * 0.1
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	_t += delta
	if _t > LIFETIME:
		queue_free()
		return

	_mesh.rotate_y(delta * 2.2)
	var bob_y := _base_y + sin(_t * 3.0) * 0.12

	var player := get_tree().get_first_node_in_group("player")
	if player:
		var to: Vector3 = (player as Node3D).global_position + Vector3(0, 0.6, 0) - global_position
		var dist := to.length()
		if dist < MAGNET_RADIUS:
			var pull := MAGNET_SPEED * (1.15 - dist / MAGNET_RADIUS)
			global_position += to.normalized() * pull * delta
			return
	global_position.y = bob_y


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("collect"):
		body.collect(item, count, _info.get("color", Color.WHITE), _info.get("name", item), _info.get("rarity", "common"))
		queue_free()
