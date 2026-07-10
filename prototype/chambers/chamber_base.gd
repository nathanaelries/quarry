extends Node3D
## Quarry — base class for a chamber (and the hub).
##
## A chamber is a small, self-contained teaching level. Subclass this and override:
##   • get_spawn()        → where the player starts
##   • intro_objective()  → the first HUD objective line
##   • build_chamber()     → lay out the content (use the helpers below)
## The base handles the player, HUD, input, lighting, navmesh bake, objectives, and the
## win → completion flow. Add a win gate with _build_win_gate(); stepping into it completes
## the chamber and returns to the hub.

const PlayerScript := preload("res://scripts/player.gd")
const HudScript := preload("res://scripts/hud.gd")
const DroneScript := preload("res://scripts/drone.gd")
const LootContainerScript := preload("res://scripts/loot_container.gd")

const FLOOR := Color(0.14, 0.14, 0.18)
const WALL := Color(0.11, 0.11, 0.15)
const AMBER := Color(0.95, 0.66, 0.24)
const CYAN := Color(0.35, 0.85, 1.0)
const GREEN := Color(0.55, 0.85, 0.45)
const GOLD := Color(1.0, 0.86, 0.5)

var player: CharacterBody3D
var chamber_id := ""

var _hud: CanvasLayer
var _won := false


func _ready() -> void:
	_setup_input()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_build_environment()

	player = PlayerScript.new()
	add_child(player)
	var spawn := get_spawn()
	player.global_position = spawn
	player.spawn_point = spawn

	build_chamber()
	_build_navigation()

	_hud = HudScript.new()
	_hud.player = player
	add_child(_hud)
	_hud.set_objective(intro_objective())


# ---- Override points ------------------------------------------------------
func get_spawn() -> Vector3:
	return Vector3(0, 1.5, 0)


func intro_objective() -> String:
	return ""


func build_chamber() -> void:
	pass


# ---- Completion -----------------------------------------------------------
func _build_win_gate(pos: Vector3) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.4
	torus.outer_radius = 1.7
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GOLD
	mat.emission_enabled = true
	mat.emission = GOLD
	mat.emission_energy_multiplier = 2.5
	ring.material_override = mat
	add_child(ring)
	ring.global_position = pos + Vector3(0, 0.4, 0)

	var light := OmniLight3D.new()
	light.light_color = GOLD
	light.omni_range = 8.0
	light.light_energy = 3.0
	add_child(light)
	light.global_position = pos + Vector3(0, 0.4, 0)

	var area := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.4
	col.shape = shape
	area.add_child(col)
	add_child(area)
	area.global_position = pos + Vector3(0, 0.4, 0)
	area.body_entered.connect(_on_win)


func _on_win(body: Node) -> void:
	if body.is_in_group("player") and not _won:
		_complete()


func _complete() -> void:
	_won = true
	if _hud and _hud.has_method("level_complete"):
		_hud.level_complete()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(3.5).timeout
	var game := get_parent()
	if game and game.has_method("complete_chamber"):
		game.complete_chamber(chamber_id)


# ---- Objectives -----------------------------------------------------------
func _objective_trigger(pos: Vector3, size: Vector3, text: String) -> void:
	var area := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	area.add_child(col)
	add_child(area)
	area.global_position = pos
	area.body_entered.connect(_on_objective.bind(text))


func _on_objective(body: Node, text: String) -> void:
	if body.is_in_group("player") and _hud:
		_hud.set_objective(text)


# ---- Build helpers --------------------------------------------------------
func _spawn_drone(pos: Vector3, vuln: String, rank := "junior", ai := false, archetype := "melee") -> Node3D:
	var drone: Node3D = DroneScript.new()
	drone.vulnerable_to = vuln
	drone.rank = rank
	drone.ai_enabled = ai
	drone.archetype = archetype
	add_child(drone)
	drone.global_position = pos
	return drone


func _spawn_container(pos: Vector3, pool: String, rank: String, spirit: bool) -> Node3D:
	var c: Node3D = LootContainerScript.new()
	c.pool = pool
	c.rank = rank
	c.spirit_breakable = spirit
	add_child(c)
	c.global_position = pos
	return c


func _vein(center: Vector3, size: Vector3) -> void:
	var m := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	m.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = AMBER
	mat.emission_enabled = true
	mat.emission = AMBER
	mat.emission_energy_multiplier = 0.7
	m.material_override = mat
	add_child(m)
	m.global_position = center


func _add_box(center: Vector3, size: Vector3, color: Color, emissive := false, energy := 1.0) -> StaticBody3D:
	var body := StaticBody3D.new()

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = energy
	mesh.material_override = mat
	body.add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

	body.add_to_group("navgeo")
	add_child(body)
	body.global_position = center
	return body


# ---- Systems --------------------------------------------------------------
func _build_navigation() -> void:
	var region := NavigationRegion3D.new()
	var navmesh := NavigationMesh.new()
	navmesh.cell_size = 0.25
	navmesh.cell_height = 0.25
	navmesh.agent_height = 1.5
	navmesh.agent_radius = 0.5
	navmesh.agent_max_climb = 0.5
	navmesh.agent_max_slope = 45.0
	navmesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	navmesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	navmesh.geometry_source_group_name = "navgeo"
	region.navigation_mesh = navmesh
	add_child(region)
	region.bake_navigation_mesh(false)


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.03, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.42, 0.5)
	env.ambient_light_energy = 0.45
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.04, 0.08)
	env.fog_density = 0.012

	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -50, 0)
	sun.light_energy = 1.0
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.shadow_enabled = true
	add_child(sun)


func _setup_input() -> void:
	var binds := {
		"move_forward": KEY_W,
		"move_back": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"jump": KEY_SPACE,
		"descend": KEY_SHIFT,
		"dash": KEY_SHIFT,          # physical mode; descend is spirit-only, so no conflict
		"spirit_toggle": KEY_F,
		"interact": KEY_E,
	}
	for action in binds:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			var ev := InputEventKey.new()
			ev.physical_keycode = binds[action]
			InputMap.action_add_event(action, ev)
