extends "res://chambers/chamber_base.gd"
## Quarry — Chamber 01: "The Reclamation".
## Teaches spirit projection, then combines the mechanics on a linear escape.
## See docs/LEVEL_1.md. Content only — the base handles player/HUD/nav/win.

const PortalScript := preload("res://scripts/portal.gd")
const PlanetScript := preload("res://scripts/gravity_planet.gd")
const GravityPathScript := preload("res://scripts/gravity_path.gd")
const GravityRegionScript := preload("res://scripts/gravity_region.gd")
const GravitySwitchScript := preload("res://scripts/gravity_switch.gd")
const SpiritLockScript := preload("res://scripts/spirit_lock.gd")


func get_spawn() -> Vector3:
	return Vector3(0, 1.5, 19)


func intro_objective() -> String:
	return "Escape the cell — press F to project your spirit through the door to the lock, then E"


func build_chamber() -> void:
	_build_cell()
	_build_corridor()
	_build_gallery()
	_build_cistern()


# ---- Awakening Cell (spirit-lock gate) -----------------------------------
func _build_cell() -> void:
	_add_box(Vector3(0, -0.5, 17.5), Vector3(12, 1, 11), FLOOR)
	_add_box(Vector3(0, 2, 23), Vector3(12, 4, 0.5), WALL)
	_add_box(Vector3(6, 2, 17.5), Vector3(0.5, 4, 11), WALL)
	_add_box(Vector3(-6, 2, 17.5), Vector3(0.5, 4, 11), WALL)
	_add_box(Vector3(-4, 2, 12), Vector3(4, 4, 0.5), WALL)
	_add_box(Vector3(4, 2, 12), Vector3(4, 4, 0.5), WALL)

	var door := _add_box(Vector3(0, 2, 12), Vector3(4, 4, 0.5), Color(0.32, 0.26, 0.42))
	door.name = "CellDoor"

	var lock: Node3D = SpiritLockScript.new()
	lock.player = player
	lock.door = door
	add_child(lock)
	lock.global_position = Vector3(0, 1.4, 10)

	_vein(Vector3(0, 0.06, 17.5), Vector3(0.5, 0.02, 10))


# ---- Rib Corridor (first combat + loot) ----------------------------------
func _build_corridor() -> void:
	_add_box(Vector3(0, -0.5, 7), Vector3(8, 1, 10), FLOOR)
	_add_box(Vector3(4, 2, 7), Vector3(0.5, 4, 10), WALL)
	_add_box(Vector3(-4, 2, 7), Vector3(0.5, 4, 10), WALL)
	_vein(Vector3(0, 0.06, 7), Vector3(0.5, 0.02, 10))

	_objective_trigger(Vector3(0, 1.5, 11), Vector3(6, 3, 1),
		"Fight through the rib corridor — LMB to fire")

	_spawn_drone(Vector3(0, 1.2, 9), "both", "junior", true, "melee")
	_spawn_drone(Vector3(1.5, 1.2, 4), "both", "junior", true, "melee")
	_spawn_container(Vector3(-2.5, 0.5, 6), "salvage_crate", "junior", false)


# ---- Sunken Gallery (combat + gravity, portal exit) ----------------------
func _build_gallery() -> void:
	_add_box(Vector3(0, -0.5, -8), Vector3(22, 1, 20), FLOOR)
	_add_box(Vector3(-7.5, 2.5, 2), Vector3(7, 5, 0.5), WALL)
	_add_box(Vector3(7.5, 2.5, 2), Vector3(7, 5, 0.5), WALL)
	_add_box(Vector3(11, 2.5, -8), Vector3(0.5, 5, 20), WALL)
	_add_box(Vector3(-11, 2.5, -8), Vector3(0.5, 5, 20), WALL)
	_add_box(Vector3(0, 2.5, -18), Vector3(22, 5, 0.5), WALL)

	_objective_trigger(Vector3(0, 1.5, 1), Vector3(7, 3, 1),
		"Cross the gallery — reach the gate portal to the south")

	_spawn_drone(Vector3(-4, 1.2, -6), "both", "junior", true, "melee")
	_spawn_drone(Vector3(4, 1.2, -10), "both", "middle", true, "melee")
	_add_box(Vector3(9, 3, -12), Vector3(3, 0.5, 3), WALL)
	_spawn_drone(Vector3(9, 3.7, -12), "both", "middle", true, "ranged")

	# Optional: a gravity path up the west wall to a reliquary.
	var path: Node3D = GravityPathScript.new()
	path.player = player
	path.path_up = Vector3(1, 0, 0)
	path.strip_size = Vector3(3.5, 7, 0.2)
	add_child(path)
	path.global_position = Vector3(-10.6, 3.6, -6)
	_add_box(Vector3(-8.5, 6.2, -6), Vector3(4, 0.5, 5), WALL)
	_spawn_container(Vector3(-8.5, 7.0, -6), "reliquary", "senior", true)

	# Exit portal (south) — folds to the Cistern.
	var gate_a: Node3D = PortalScript.new()
	gate_a.player = player
	add_child(gate_a)
	gate_a.global_position = Vector3(0, 1.6, -15)

	var gate_b: Node3D = PortalScript.new()
	gate_b.player = player
	add_child(gate_b)
	gate_b.global_position = Vector3(0, 1.6, -34)
	gate_a.linked = gate_b
	gate_b.linked = gate_a


# ---- Cistern Gate (climax + win) -----------------------------------------
func _build_cistern() -> void:
	_add_box(Vector3(0, -0.5, -42), Vector3(28, 1, 20), FLOOR)
	_add_box(Vector3(0, 3, -32), Vector3(28, 6, 0.5), WALL)
	_add_box(Vector3(14, 3, -42), Vector3(0.5, 6, 20), WALL)
	_add_box(Vector3(-14, 3, -42), Vector3(0.5, 6, 20), WALL)
	_add_box(Vector3(0, 3, -52), Vector3(28, 6, 0.5), WALL)

	_objective_trigger(Vector3(0, 1.5, -35), Vector3(8, 3, 1),
		"End the reclamation — reach the Ascension Gate")

	var planet: Node3D = PlanetScript.new()
	planet.player = player
	add_child(planet)
	planet.global_position = Vector3(-9, 3.0, -44)
	_add_box(Vector3(-9, 5.9, -44), Vector3(2, 0.4, 2), WALL)
	_spawn_container(Vector3(-9, 6.5, -44), "reliquary", "senior", true)

	_build_switch_vault(Vector3(10, 0, -48))

	_spawn_drone(Vector3(0, 1.2, -44), "both", "senior", true, "melee")
	_spawn_drone(Vector3(-5, 1.2, -46), "both", "junior", true, "melee")
	_spawn_drone(Vector3(6, 1.2, -47), "both", "middle", true, "ranged")

	_build_win_gate(Vector3(0, 1.6, -50.5))


func _build_switch_vault(c: Vector3) -> void:
	_add_box(c + Vector3(0, 4.2, 0), Vector3(6, 0.4, 6), WALL)
	_add_box(c + Vector3(0, 2, -3), Vector3(6, 4, 0.4), WALL)
	_add_box(c + Vector3(3, 2, 0), Vector3(0.4, 4, 6), WALL)
	var region: Node3D = GravityRegionScript.new()
	region.player = player
	region.region_size = Vector3(5.4, 4, 5.4)
	add_child(region)
	region.global_position = c + Vector3(0, 2, 0)
	var sw: Node3D = GravitySwitchScript.new()
	sw.region = region
	add_child(sw)
	sw.global_position = c + Vector3(0, 1.3, -2.7)
	_spawn_container(c + Vector3(0, 3.6, 0), "reliquary", "senior", true)
