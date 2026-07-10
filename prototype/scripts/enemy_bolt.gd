extends Area3D
## Quarry prototype — a hostile bolt fired by a ranged drone.
##
## Damages the player, passes over other drones, dies on world geometry.

var velocity := Vector3.ZERO
var speed := 18.0
var damage := 1

var _life := 4.0
var _reflected := false
var _mat: StandardMaterial3D


func _ready() -> void:
	add_to_group("enemy_bolts")

	var mesh := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.14
	s.height = 0.28
	mesh.mesh = s
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.95, 0.35, 0.4)
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.25, 0.3)
	_mat.emission_energy_multiplier = 3.0
	mesh.material_override = _mat
	add_child(mesh)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.3, 0.35)
	light.omni_range = 3.0
	light.light_energy = 1.4
	add_child(light)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.16
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)


func launch(from: Vector3, dir: Vector3) -> void:
	global_position = from
	velocity = dir.normalized() * speed


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	global_position += velocity * delta


func reflect() -> void:
	velocity = -velocity * 1.4                    # send it back, faster
	_reflected = true
	_mat.albedo_color = Color(0.5, 0.9, 1.0)      # now friendly
	_mat.emission = Color(0.45, 0.85, 1.0)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("drones"):
		if _reflected and body.has_method("take_hit"):
			body.take_hit(2, "physical")          # a parried bolt bites the drones
			_impact(Color(0.5, 0.9, 1.0))
		return                                    # otherwise pass over allies
	if body.is_in_group("player"):
		if _reflected:
			return                                # your own reflected bolt won't hit you
		if body.has_method("is_parrying") and body.is_parrying():
			if body.has_method("on_parry_success"):
				body.on_parry_success()
			reflect()
			return
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_impact(Color(1.0, 0.35, 0.4))
		return
	_impact(Color(1.0, 0.35, 0.4))                # wall / floor


func _impact(color: Color) -> void:
	Juice.play_3d("hit", global_position, -6.0)
	Juice.spark(global_position, color)
	queue_free()
