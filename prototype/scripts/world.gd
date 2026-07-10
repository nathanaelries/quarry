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
const SpiritLockScript := preload("res://scripts/spirit_lock.gd")
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

	_build_gravity_demo(player)
	_build_portal_demo(player)
	_build_spirit_demo(player)

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
