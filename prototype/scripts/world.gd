extends Node3D
## Quarry prototype — Level 1: "The Reclamation".
##
## A linear escape through a harvesting district of the Cylinder: wake in a cell, fight
## and traverse four connected areas, reach the Ascension Gate to escape. The mechanic
## components (portal, gravity, spirit, loot, drone AI) are placed as gates and set-
## dressing along a designed critical path. See docs/LEVEL_1.md.
##
## Built entirely in code; input actions are registered here too.

const PlayerScript := preload("res://scripts/player.gd")
const PortalScript := preload("res://scripts/portal.gd")
const PlanetScript := preload("res://scripts/gravity_planet.gd")
const GravityPathScript := preload("res://scripts/gravity_path.gd")
const GravityRegionScript := preload("res://scripts/gravity_region.gd")
const GravitySwitchScript := preload("res://scripts/gravity_switch.gd")
const SpiritLockScript := preload("res://scripts/spirit_lock.gd")
const DroneScript := preload("res://scripts/drone.gd")
const LootContainerScript := preload("res://scripts/loot_container.gd")
const HudScript := preload("res://scripts/hud.gd")

const FLOOR := Color(0.14, 0.14, 0.18)
const WALL := Color(0.11, 0.11, 0.15)
const AMBER := Color(0.95, 0.66, 0.24)
const CYAN := Color(0.35, 0.85, 1.0)
const GREEN := Color(0.55, 0.85, 0.45)
const GOLD := Color(1.0, 0.86, 0.5)

var _hud: CanvasLayer
var _won := false


func _ready() -> void:
	_setup_input()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_build_environment()

	var player: CharacterBody3D = PlayerScript.new()
	add_child(player)
	player.global_position = Vector3(0, 1.5, 19)
	player.spawn_point = Vector3(0, 1.5, 19)

	_build_cell(player)
	_build_corridor(player)
	_build_gallery(player)
	_build_cistern(player)
	_build_navigation()                  # bake after all static geometry exists

	_hud = HudScript.new()
	_hud.player = player
	add_child(_hud)
	_hud.set_objective("Escape the cell — press F to project your spirit through the door to the lock, then E")


# ---------------------------------------------------------------------------
# Area 1 — Awakening Cell (spirit-lock gate)
# ---------------------------------------------------------------------------
func _build_cell(player: CharacterBody3D) -> void:
	_add_box(Vector3(0, -0.5, 17.5), Vector3(12, 1, 11), FLOOR)          # floor
	_add_box(Vector3(0, 2, 23), Vector3(12, 4, 0.5), WALL)               # north
	_add_box(Vector3(6, 2, 17.5), Vector3(0.5, 4, 11), WALL)             # east
	_add_box(Vector3(-6, 2, 17.5), Vector3(0.5, 4, 11), WALL)            # west
	_add_box(Vector3(-4, 2, 12), Vector3(4, 4, 0.5), WALL)               # south (left of door)
	_add_box(Vector3(4, 2, 12), Vector3(4, 4, 0.5), WALL)                # south (right of door)

	var door := _add_box(Vector3(0, 2, 12), Vector3(4, 4, 0.5), Color(0.32, 0.26, 0.42))
	door.name = "CellDoor"

	var lock: Node3D = SpiritLockScript.new()
	lock.player = player
	lock.door = door
	add_child(lock)
	lock.global_position = Vector3(0, 1.4, 10)                            # beyond the door

	_vein(Vector3(0, 0.06, 17.5), Vector3(0.5, 0.02, 10))


# ---------------------------------------------------------------------------
# Area 2 — Rib Corridor (first combat + loot)
# ---------------------------------------------------------------------------
func _build_corridor(player: CharacterBody3D) -> void:
	_add_box(Vector3(0, -0.5, 7), Vector3(8, 1, 10), FLOOR)
	_add_box(Vector3(4, 2, 7), Vector3(0.5, 4, 10), WALL)
	_add_box(Vector3(-4, 2, 7), Vector3(0.5, 4, 10), WALL)
	_vein(Vector3(0, 0.06, 7), Vector3(0.5, 0.02, 10))

	_objective_trigger(Vector3(0, 1.5, 11), Vector3(6, 3, 1),
		"Fight through the rib corridor — LMB to fire")

	_spawn_drone(Vector3(0, 1.2, 9), "both", "junior", true, "melee")
	_spawn_drone(Vector3(1.5, 1.2, 4), "both", "junior", true, "melee")
	_spawn_container(Vector3(-2.5, 0.5, 6), "salvage_crate", "junior", false)


# ---------------------------------------------------------------------------
# Area 3 — Sunken Gallery (combat + gravity, portal exit)
# ---------------------------------------------------------------------------
func _build_gallery(player: CharacterBody3D) -> void:
	_add_box(Vector3(0, -0.5, -8), Vector3(22, 1, 20), FLOOR)
	_add_box(Vector3(-7.5, 2.5, 2), Vector3(7, 5, 0.5), WALL)             # north (left of gap)
	_add_box(Vector3(7.5, 2.5, 2), Vector3(7, 5, 0.5), WALL)              # north (right of gap)
	_add_box(Vector3(11, 2.5, -8), Vector3(0.5, 5, 20), WALL)             # east
	_add_box(Vector3(-11, 2.5, -8), Vector3(0.5, 5, 20), WALL)            # west
	_add_box(Vector3(0, 2.5, -18), Vector3(22, 5, 0.5), WALL)            # south

	_objective_trigger(Vector3(0, 1.5, 1), Vector3(7, 3, 1),
		"Cross the gallery — reach the gate portal to the south")

	# Combat: melee on the floor, a ranged sniper on a ledge.
	_spawn_drone(Vector3(-4, 1.2, -6), "both", "junior", true, "melee")
	_spawn_drone(Vector3(4, 1.2, -10), "both", "middle", true, "melee")
	_add_box(Vector3(9, 3, -12), Vector3(3, 0.5, 3), WALL)               # sniper ledge
	_spawn_drone(Vector3(9, 3.7, -12), "both", "middle", true, "ranged")

	# Optional: a gravity path up the west wall to a reliquary.
	var path: Node3D = GravityPathScript.new()
	path.player = player
	path.path_up = Vector3(1, 0, 0)                                       # off the west wall
	path.strip_size = Vector3(3.5, 7, 0.2)
	add_child(path)
	path.global_position = Vector3(-10.6, 3.6, -6)
	_add_box(Vector3(-8.5, 6.2, -6), Vector3(4, 0.5, 5), WALL)           # top ledge
	_spawn_container(Vector3(-8.5, 7.0, -6), "reliquary", "senior", true)

	# Exit portal (south) — folds to the Cistern.
	var gate_a: Node3D = PortalScript.new()
	gate_a.player = player
	add_child(gate_a)
	gate_a.global_position = Vector3(0, 1.6, -15)

	# Cistern-side partner (built here, linked; the Cistern room is built separately).
	var gate_b: Node3D = PortalScript.new()
	gate_b.player = player
	add_child(gate_b)
	gate_b.global_position = Vector3(0, 1.6, -34)
	gate_a.linked = gate_b
	gate_b.linked = gate_a


# ---------------------------------------------------------------------------
# Area 4 — Cistern Gate (climax + win)
# ---------------------------------------------------------------------------
func _build_cistern(player: CharacterBody3D) -> void:
	_add_box(Vector3(0, -0.5, -42), Vector3(28, 1, 20), FLOOR)
	_add_box(Vector3(0, 3, -32), Vector3(28, 6, 0.5), WALL)              # north
	_add_box(Vector3(14, 3, -42), Vector3(0.5, 6, 20), WALL)            # east
	_add_box(Vector3(-14, 3, -42), Vector3(0.5, 6, 20), WALL)          # west
	_add_box(Vector3(0, 3, -52), Vector3(28, 6, 0.5), WALL)            # south

	_objective_trigger(Vector3(0, 1.5, -35), Vector3(8, 3, 1),
		"End the reclamation — reach the Ascension Gate")

	# Optional: the planetoid, with a cache on a small perch beside it.
	var planet: Node3D = PlanetScript.new()
	planet.player = player
	add_child(planet)
	planet.global_position = Vector3(-9, 3.0, -44)
	_add_box(Vector3(-9, 5.9, -44), Vector3(2, 0.4, 2), WALL)
	_spawn_container(Vector3(-9, 6.5, -44), "reliquary", "senior", true)

	# Optional: a side vault with a gravity switch → ceiling reliquary.
	_build_switch_vault(player, Vector3(10, 0, -48))

	# Final reclamation.
	_spawn_drone(Vector3(0, 1.2, -44), "both", "senior", true, "melee")
	_spawn_drone(Vector3(-5, 1.2, -46), "both", "junior", true, "melee")
	_spawn_drone(Vector3(6, 1.2, -47), "both", "middle", true, "ranged")

	# The Ascension Gate — step in to escape.
	_build_win_gate(Vector3(0, 1.6, -50.5))


func _build_switch_vault(player: CharacterBody3D, c: Vector3) -> void:
	_add_box(c + Vector3(0, 4.2, 0), Vector3(6, 0.4, 6), WALL)           # ceiling
	_add_box(c + Vector3(0, 2, -3), Vector3(6, 4, 0.4), WALL)            # back
	_add_box(c + Vector3(3, 2, 0), Vector3(0.4, 4, 6), WALL)             # right (open front + left)
	var region: Node3D = GravityRegionScript.new()
	region.player = player
	region.region_size = Vector3(5.4, 4, 5.4)
	add_child(region)
	region.global_position = c + Vector3(0, 2, 0)
	var sw: Node3D = GravitySwitchScript.new()
	sw.region = region
	add_child(sw)
	sw.global_position = c + Vector3(0, 1.3, -2.7)
	_spawn_container(c + Vector3(0, 3.6, 0), "reliquary", "senior", true)   # on the ceiling


# ---------------------------------------------------------------------------
# Objective / win triggers
# ---------------------------------------------------------------------------
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
		_won = true
		if _hud:
			_hud.level_complete()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------
func _setup_input() -> void:
	var binds := {
		"move_forward": KEY_W,
		"move_back": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"jump": KEY_SPACE,
		"descend": KEY_SHIFT,
		"spirit_toggle": KEY_F,
		"interact": KEY_E,
	}
	for action in binds:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = binds[action]
		InputMap.action_add_event(action, ev)


# ---------------------------------------------------------------------------
# Environment / lighting
# ---------------------------------------------------------------------------
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


# ---------------------------------------------------------------------------
# Navigation
# ---------------------------------------------------------------------------
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


# ---------------------------------------------------------------------------
# Spawners / helpers
# ---------------------------------------------------------------------------
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
