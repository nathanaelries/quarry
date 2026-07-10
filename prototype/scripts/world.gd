extends Node3D
## Quarry prototype — world builder.
##
## Assembles the whole sandbox in code (lighting, geometry, the three mechanic
## demos, the player, and the HUD) so the project runs straight from F5 with no
## hand-authored scene graph to break. Input actions are registered here too, so
## project.godot carries no InputMap that could drift out of sync.

const PlayerScript := preload("res://scripts/player.gd")
const PortalScript := preload("res://scripts/portal.gd")
const PlanetScript := preload("res://scripts/gravity_planet.gd")
const GravityPathScript := preload("res://scripts/gravity_path.gd")
const GravityRegionScript := preload("res://scripts/gravity_region.gd")
const GravitySwitchScript := preload("res://scripts/gravity_switch.gd")
const SpiritLockScript := preload("res://scripts/spirit_lock.gd")
const SpiritRevealScript := preload("res://scripts/spirit_reveal.gd")
const DroneScript := preload("res://scripts/drone.gd")
const LootContainerScript := preload("res://scripts/loot_container.gd")
const HudScript := preload("res://scripts/hud.gd")

const CYAN := Color(0.35, 0.85, 1.0)
const ORANGE := Color(0.82, 0.42, 0.16)
const GREEN := Color(0.4, 1.0, 0.5)


func _ready() -> void:
	_setup_input()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	_build_environment()
	_build_arena()

	var player: CharacterBody3D = PlayerScript.new()
	add_child(player)
	player.global_position = Vector3(0, 2, 8)
	player.spawn_point = Vector3(0, 2, 8)

	_build_gravity_demo(player)
	_build_gravity_path_demo(player)
	_build_gravity_switch_demo(player)
	_build_portal_demo(player)
	_build_spirit_demo(player)
	_build_spirit_reveal_demo(player)
	_build_loot_demo(player)
	_build_combat_demo(player)

	var hud: CanvasLayer = HudScript.new()
	hud.player = player
	add_child(hud)


# ---------------------------------------------------------------------------
# Input — registered at runtime so there is no InputMap in project.godot.
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
# Scene dressing
# ---------------------------------------------------------------------------
func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.03, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.47, 0.6)
	env.ambient_light_energy = 0.5
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.05, 0.1)
	env.fog_density = 0.01

	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -46, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)


func _build_arena() -> void:
	# Floor.
	_add_box(Vector3(0, -0.5, 0), Vector3(44, 1, 44), Color(0.14, 0.14, 0.18))
	# Perimeter walls so you can't wander off the edge.
	_add_box(Vector3(0, 1.5, -22), Vector3(44, 4, 1), Color(0.1, 0.1, 0.14))
	_add_box(Vector3(0, 1.5, 22), Vector3(44, 4, 1), Color(0.1, 0.1, 0.14))
	_add_box(Vector3(-22, 1.5, 0), Vector3(1, 4, 44), Color(0.1, 0.1, 0.14))
	_add_box(Vector3(22, 1.5, 0), Vector3(1, 4, 44), Color(0.1, 0.1, 0.14))


# ---------------------------------------------------------------------------
# Mechanic 1 — localized gravity (walk-around planetoid)
# ---------------------------------------------------------------------------
func _build_gravity_demo(player: CharacterBody3D) -> void:
	# A ramp up to the planetoid so you can step onto it.
	_add_box(Vector3(8, 0.6, 2), Vector3(4, 0.4, 3), Color(0.2, 0.2, 0.26))

	var planet: Node3D = PlanetScript.new()
	planet.player = player
	add_child(planet)
	planet.global_position = Vector3(12, 3.2, 2)


# Gravity path — walk straight up a wall to a high ledge (north, +Z).
func _build_gravity_path_demo(player: CharacterBody3D) -> void:
	_add_box(Vector3(0, 5, 20), Vector3(6, 10, 1), Color(0.16, 0.17, 0.22))          # the wall
	_add_box(Vector3(0, 10.1, 17.8), Vector3(6, 0.5, 5), Color(0.18, 0.22, 0.2))     # top ledge
	var beacon := _add_box(Vector3(0, 10.9, 17.0), Vector3(0.5, 0.5, 0.5), GREEN, true, 1.6)
	beacon.name = "PathBeacon"

	var path: Node3D = GravityPathScript.new()
	path.player = player
	path.path_up = Vector3(0, 0, -1)                                                 # wall's outward normal
	add_child(path)
	path.global_position = Vector3(0, 5, 19.4)


# Gravity switch — shoot the switch to flip a room's gravity and reach the ceiling.
func _build_gravity_switch_demo(player: CharacterBody3D) -> void:
	var c := Vector3(16, 0, -6)
	_add_box(c + Vector3(0, 6.2, 0), Vector3(8, 0.4, 8), Color(0.15, 0.15, 0.2))     # ceiling
	_add_box(c + Vector3(0, 3, -3.8), Vector3(8, 6, 0.4), Color(0.16, 0.16, 0.21))   # back wall
	_add_box(c + Vector3(-3.8, 3, 0), Vector3(0.4, 6, 7), Color(0.16, 0.16, 0.21))   # left wall
	_add_box(c + Vector3(3.8, 3, 0), Vector3(0.4, 6, 7), Color(0.16, 0.16, 0.21))    # right wall
	# front is open — walk in from the arena

	var region: Node3D = GravityRegionScript.new()
	region.player = player
	region.region_size = Vector3(7.4, 6.0, 7.4)
	add_child(region)
	region.global_position = c + Vector3(0, 3, 0)

	var sw: Node3D = GravitySwitchScript.new()
	sw.region = region
	add_child(sw)
	sw.global_position = c + Vector3(0, 2.0, -3.5)                                   # on the back wall

	# The prize sits on the ceiling — only reachable once you've flipped gravity.
	var goal := _add_box(c + Vector3(0, 5.6, 0), Vector3(0.6, 0.6, 0.6), Color(1.0, 0.85, 0.2), true, 1.8)
	goal.name = "CeilingGoal"


# ---------------------------------------------------------------------------
# Mechanic 2 — portals (reach an otherwise-unreachable ledge)
# ---------------------------------------------------------------------------
func _build_portal_demo(player: CharacterBody3D) -> void:
	var portal_a: Node3D = PortalScript.new()
	portal_a.player = player
	add_child(portal_a)
	portal_a.global_position = Vector3(-6, 1.6, 6)

	# A high ledge you can't jump to — the portal is the only way up.
	_add_box(Vector3(-13, 6.5, -10), Vector3(7, 1, 7), Color(0.18, 0.2, 0.26))
	# A little prize on the ledge so arriving feels like arriving.
	var beacon := _add_box(Vector3(-13, 8.2, -10), Vector3(0.5, 0.5, 0.5), CYAN, true, 2.0)
	beacon.name = "LedgeBeacon"

	var portal_b: Node3D = PortalScript.new()
	portal_b.player = player
	add_child(portal_b)
	portal_b.global_position = Vector3(-13, 8.6, -10)

	portal_a.linked = portal_b
	portal_b.linked = portal_a

	# A drone floating just off portal B's exit — look through portal A to see it,
	# then shoot straight through to tag it (or teleport up and shoot it directly).
	_spawn_drone(Vector3(-13, 8.6, -7), "physical")


## Spawn a drone. `vuln` = "physical" | "spirit" | "both"; rank scales its loot.
## ai=true makes it patrol/chase/attack; archetype = "melee" | "ranged".
func _spawn_drone(pos: Vector3, vuln: String, rank := "junior", ai := false, archetype := "melee") -> Node3D:
	var drone: Node3D = DroneScript.new()
	drone.vulnerable_to = vuln
	drone.rank = rank
	drone.ai_enabled = ai
	drone.archetype = archetype
	add_child(drone)
	drone.global_position = pos
	return drone


# Combat — live AI drones between spawn and the southern rooms. They patrol until they
# spot you (sight cone + line-of-sight), then chase and attack; shooting one aggros it.
# Kill with the gun for salvage, the spirit blade for essence.
func _build_combat_demo(player: CharacterBody3D) -> void:
	_spawn_drone(Vector3(-3, 1.2, -4), "both", "junior", true, "melee")
	_spawn_drone(Vector3(2, 1.2, -6), "both", "middle", true, "melee")
	_spawn_drone(Vector3(-1, 1.2, -10), "both", "middle", true, "ranged")


func _spawn_container(pos: Vector3, pool: String, rank: String, spirit: bool) -> Node3D:
	var c: Node3D = LootContainerScript.new()
	c.pool = pool
	c.rank = rank
	c.spirit_breakable = spirit
	add_child(c)
	c.global_position = pos
	return c


# Loot demo — a firing range + breakable containers.
# Shoot a drone for salvage, spirit-blade it for essence; higher rank = richer haul.
func _build_loot_demo(player: CharacterBody3D) -> void:
	_add_box(Vector3(0, 0.4, 3), Vector3(9, 0.8, 2), Color(0.15, 0.15, 0.2))     # firing-range plinth
	_spawn_drone(Vector3(-3, 1.6, 3), "both", "junior")
	_spawn_drone(Vector3(0, 1.6, 3), "both", "middle")
	_spawn_drone(Vector3(3, 1.6, 3), "both", "senior")

	_spawn_container(Vector3(6, 0.5, 6), "salvage_crate", "junior", false)       # shoot me
	_spawn_container(Vector3(-5, 0.5, 9), "salvage_crate", "middle", false)      # shoot me
	_spawn_container(Vector3(11, 0.6, -7.5), "reliquary", "senior", true)        # spirit-blade me


# ---------------------------------------------------------------------------
# Mechanic 3 — Merkavah spirit projection (trip a spirit-only lock)
# ---------------------------------------------------------------------------
func _build_spirit_demo(player: CharacterBody3D) -> void:
	var c := Vector3(11, 0, -12)     # room centre on the floor plane

	# A sealed room: three solid walls + a door the physical body can't pass.
	_add_box(c + Vector3(0, 2, -3.7), Vector3(7.4, 4, 0.4), Color(0.16, 0.16, 0.2))   # back
	_add_box(c + Vector3(-3.7, 2, 0), Vector3(0.4, 4, 7.4), Color(0.16, 0.16, 0.2))   # left
	_add_box(c + Vector3(3.7, 2, 0), Vector3(0.4, 4, 7.4), Color(0.16, 0.16, 0.2))    # right

	# The door is its own body so the spirit lock can slide it down.
	var door := _add_box(c + Vector3(0, 2, 3.7), Vector3(7.4, 4, 0.4), Color(0.3, 0.24, 0.4))
	door.name = "SpiritDoor"

	# The goal inside the sealed room.
	var goal := _add_box(c + Vector3(0, 1, -2.5), Vector3(0.8, 2, 0.8), GREEN, true, 1.6)
	goal.name = "SpiritGoal"

	# The lock — only reachable by the projected spirit.
	var lock: Node3D = SpiritLockScript.new()
	lock.player = player
	lock.door = door
	add_child(lock)
	lock.global_position = c + Vector3(0, 1.4, 0)


# Spirit-revealed path — scout in spirit to reveal a bridge, cross in the flesh,
# slash the spirit-only drone guarding the goal.
func _build_spirit_reveal_demo(player: CharacterBody3D) -> void:
	# A ramp up to the near platform. NOTE: if it tilts the wrong way in-editor,
	# flip the sign of the rotation below.
	var ramp := _add_box(Vector3(-8, 1.0, 6), Vector3(4.6, 0.4, 3), Color(0.2, 0.2, 0.26))
	ramp.rotation_degrees = Vector3(0, 0, -24)

	_add_box(Vector3(-12, 1.75, 6), Vector3(4, 0.5, 4), Color(0.18, 0.18, 0.24))   # near platform
	_add_box(Vector3(-19, 1.75, 6), Vector3(4, 0.5, 4), Color(0.18, 0.18, 0.24))   # far platform (over a 3-unit gap)

	var bridge: Node3D = SpiritRevealScript.new()
	bridge.player = player
	add_child(bridge)
	bridge.global_position = Vector3(-15.5, 1.8, 6)

	var goal := _add_box(Vector3(-19, 2.6, 5.0), Vector3(0.5, 0.5, 0.5), Color(0.6, 0.4, 0.95), true, 1.8)
	goal.name = "RevealGoal"

	# A spirit-only drone guarding the goal — the physical gun can't touch it.
	_spawn_drone(Vector3(-19, 2.7, 6.8), "spirit")


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------
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

	add_child(body)
	body.global_position = center
	return body
