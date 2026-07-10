extends "res://shrines/shrine_base.gd"
## Quarry — the Hub. A pedestal chamber where you choose a shrine to enter.
## Reuses the shrine base (player/HUD/nav) but has no win gate; you leave by stepping
## into a shrine gate. The Reclamation is open; the other three are sealed placeholders
## for the four starter shrines (spirit / moves / parry / attacks+puzzles).


func get_spawn() -> Vector3:
	return Vector3(0, 1.6, 0)


func intro_objective() -> String:
	return "The Cylinder's shrines — step into a glowing gate to enter one"


func build_shrine() -> void:
	_add_box(Vector3(0, -0.5, 0), Vector3(26, 1, 26), FLOOR)
	_add_box(Vector3(0, 1.5, 13), Vector3(26, 3, 0.5), WALL)
	_add_box(Vector3(0, 1.5, -13), Vector3(26, 3, 0.5), WALL)
	_add_box(Vector3(13, 1.5, 0), Vector3(0.5, 3, 26), WALL)
	_add_box(Vector3(-13, 1.5, 0), Vector3(0.5, 3, 26), WALL)
	_vein(Vector3(0, 0.06, 0), Vector3(3, 0.02, 3))

	var done := _completed()
	_pedestal(Vector3(0, 0, -9), "reclamation", "01 · The Reclamation — spirit projection", true, done.has("reclamation"))
	_pedestal(Vector3(9, 0, 0), "moves", "02 · Moves — sealed (coming soon)", false, false)
	_pedestal(Vector3(0, 0, 9), "parry", "03 · Parry — sealed (coming soon)", false, false)
	_pedestal(Vector3(-9, 0, 0), "attacks", "04 · Attacks & Puzzles — sealed (coming soon)", false, false)


func _completed() -> Dictionary:
	var g := get_parent()
	if g and "completed" in g:
		return g.completed
	return {}


func _pedestal(pos: Vector3, id: String, title: String, open: bool, done: bool) -> void:
	_add_box(pos + Vector3(0, 0.4, 0), Vector3(2, 0.8, 2), WALL)

	var color := GOLD if done else (CYAN if open else Color(0.3, 0.3, 0.34))
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.7
	torus.outer_radius = 0.85
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0 if (open or done) else 0.25
	ring.material_override = mat
	add_child(ring)
	ring.global_position = pos + Vector3(0, 1.7, 0)

	_trigger(pos + Vector3(0, 1.0, 0), 3.5, _read.bind(title))
	if open or done:
		_trigger(pos + Vector3(0, 1.5, 0), 1.1, _enter.bind(id))
	else:
		_trigger(pos + Vector3(0, 1.5, 0), 1.1, _sealed)


func _trigger(pos: Vector3, radius: float, cb: Callable) -> void:
	var area := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = radius
	col.shape = shape
	area.add_child(col)
	add_child(area)
	area.global_position = pos
	area.body_entered.connect(cb)


func _read(body: Node, title: String) -> void:
	if body.is_in_group("player") and _hud:
		_hud.set_objective(title)


func _enter(body: Node, id: String) -> void:
	if not body.is_in_group("player"):
		return
	var g := get_parent()
	if g and g.has_method("enter_shrine"):
		g.enter_shrine(id)


func _sealed(body: Node) -> void:
	if body.is_in_group("player") and _hud:
		_hud.set_objective("This shrine is sealed — coming soon")
