extends CharacterBody3D
## Quarry prototype — a drone: loot target AND AI agent.
##
## Configure before adding to the tree:
##   • vulnerable_to : "physical" | "spirit" | "both"
##   • rank          : "junior" | "middle" | "senior"   (HP, speed, loot)
##   • ai_enabled    : false → a stationary dummy (loot range); true → active AI
##   • archetype     : "melee" (lunges) | "ranged" (fires bolts)
##
## AI loop: PATROL → (spot the player: vision cone + line-of-sight) → CHASE → ATTACK,
## SEARCH the last-known spot if it loses you, then back to PATROL. Taking damage aggros it.
##
## Drones use world-down gravity and ignore gravity fields — the design's player/enemy
## asymmetry: flip a room and the drones keep their footing while you fall to the ceiling.
## The kill METHOD still decides the loot (shoot → salvage, spirit-blade → essence).

const ENEMY_BOLT := preload("res://scripts/enemy_bolt.gd")

# ---- Config --------------------------------------------------------------
var vulnerable_to := "both"
var rank := "junior"
var ai_enabled := false
var archetype := "melee"

# ---- Tuning --------------------------------------------------------------
const RANK_HP := {"junior": 2, "middle": 3, "senior": 4}
const RANK_SPEED := {"junior": 3.2, "middle": 3.9, "senior": 4.6}
const RANK_SCALE := {"junior": 0.85, "middle": 1.0, "senior": 1.2}
const GRAVITY := 20.0
const VISION_RANGE := 17.0
const FOV_COS := 0.42                # cos(~65°) half-angle of the sight cone
const MELEE_RANGE := 2.0
const RANGED_RANGE := 11.0
const ATTACK_CD := 1.3
const MELEE_DAMAGE := 1
const SEARCH_TIME := 4.0
const WINDUP := 0.4                   # telegraph before an attack — the window to parry it
const STUN_TIME := 1.3                # a parried drone is staggered this long
const PATROL_RADIUS := 5.0
const TURN_RATE := 7.0

enum State { IDLE, PATROL, CHASE, ATTACK, SEARCH }

# ---- State ---------------------------------------------------------------
var _state := State.IDLE
var _health := 2
var _speed := 3.2
var _last_kind := "physical"
var _alive := true
var _home := Vector3.ZERO
var _home_set := false
var _player: Node3D
var _atk_cd := 0.0
var _windup_t := 0.0
var _stun_t := 0.0
var _search_t := 0.0
var _last_seen := Vector3.ZERO
var _patrol_target := Vector3.ZERO
var _repath_t := 0.0
var _agent: NavigationAgent3D
var _desired := Vector3.ZERO         # horizontal velocity we WANT; RVO returns a safe one

var _mat: StandardMaterial3D
var _eye_mat: StandardMaterial3D
var _base_color := Color(0.85, 0.2, 0.25)


func _ready() -> void:
	add_to_group("drones")
	if vulnerable_to == "spirit":
		_base_color = Color(0.6, 0.35, 0.95)
	if vulnerable_to != "physical":
		add_to_group("spirit_targets")
	_health = RANK_HP.get(rank, 2)
	_speed = RANK_SPEED.get(rank, 3.2)
	var s: float = RANK_SCALE.get(rank, 1.0)
	_player = get_tree().get_first_node_in_group("player")

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

	# A forward "eye" so you can read facing and alert state.
	var eye := MeshInstance3D.new()
	var em := SphereMesh.new()
	em.radius = 0.13
	em.height = 0.26
	eye.mesh = em
	_eye_mat = StandardMaterial3D.new()
	_eye_mat.albedo_color = Color(1, 1, 0.7)
	_eye_mat.emission_enabled = true
	_eye_mat.emission = Color(1, 0.95, 0.5)
	_eye_mat.emission_energy_multiplier = 1.5
	eye.material_override = _eye_mat
	eye.position = Vector3(0, 0.2, -0.46) * s
	add_child(eye)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.9, 1.4, 0.9) * s
	col.shape = shape
	add_child(col)

	if ai_enabled:
		_state = State.PATROL
		_agent = NavigationAgent3D.new()
		_agent.radius = 0.6
		_agent.height = 1.4
		_agent.path_desired_distance = 0.6
		_agent.target_desired_distance = 0.8
		_agent.path_max_distance = 4.0
		# RVO avoidance so chasers don't stack up when they converge on the player.
		_agent.avoidance_enabled = true
		_agent.max_speed = _speed
		_agent.neighbor_distance = 4.0
		_agent.max_neighbors = 8
		_agent.time_horizon_agents = 1.2
		_agent.time_horizon_obstacles = 0.5
		add_child(_agent)
		_agent.velocity_computed.connect(_on_velocity_computed)


# ---------------------------------------------------------------------------
# AI loop
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if not _alive or not ai_enabled:
		return                                  # dummies just float where placed
	if not _home_set:
		_home = global_position
		_patrol_target = _pick_patrol()
		_home_set = true
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")

	_atk_cd = maxf(0.0, _atk_cd - delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta

	_desired = Vector3.ZERO
	if _stun_t > 0.0:
		_stun_t -= delta                    # staggered — hold still, don't act
	else:
		match _state:
			State.PATROL: _do_patrol(delta)
			State.CHASE: _do_chase(delta)
			State.ATTACK: _do_attack(delta)
			State.SEARCH: _do_search(delta)

	# Hand the wanted velocity to the avoidance sim; it answers on velocity_computed.
	_agent.set_velocity(_desired)


## RVO answer: the avoidance-adjusted velocity. Apply it (keeping gravity) and move.
func _on_velocity_computed(safe: Vector3) -> void:
	if not _alive:
		return
	velocity.x = safe.x
	velocity.z = safe.z
	move_and_slide()


func _do_patrol(delta: float) -> void:
	_repath_t -= delta
	if global_position.distance_to(_patrol_target) < 1.2 or _repath_t <= 0.0:
		_patrol_target = _pick_patrol()
		_repath_t = 3.5
	_move_toward(_patrol_target, _speed * 0.5, delta)
	if _can_see_player():
		_alert()


func _do_chase(delta: float) -> void:
	if _can_see_player():
		_last_seen = _player.global_position
		var reach := MELEE_RANGE if archetype == "melee" else RANGED_RANGE
		if global_position.distance_to(_player.global_position) <= reach:
			_state = State.ATTACK
			return
		_move_toward(_player.global_position, _speed, delta)
	else:
		_state = State.SEARCH
		_search_t = SEARCH_TIME


func _do_attack(delta: float) -> void:
	if not _can_see_player():
		_windup_t = 0.0
		_state = State.SEARCH
		_search_t = SEARCH_TIME
		return
	var dist := global_position.distance_to(_player.global_position)
	var reach := MELEE_RANGE if archetype == "melee" else RANGED_RANGE
	if dist > reach * 1.15:
		_windup_t = 0.0
		_state = State.CHASE
		return
	# ranged backpedals if you close in; otherwise hold ground (RVO still spaces them)
	if archetype == "ranged" and dist < RANGED_RANGE * 0.55:
		_move_toward(global_position * 2.0 - _player.global_position, _speed * 0.8, delta)
	else:
		_desired = Vector3.ZERO
	_face(_player.global_position, delta)      # always face the player while attacking
	# Telegraph, then strike — the wind-up is your window to parry.
	if _windup_t > 0.0:
		_windup_t -= delta
		if _windup_t <= 0.0:
			_attack(dist)
			_atk_cd = ATTACK_CD
			_eye_mat.emission = Color(1.0, 0.25, 0.2)
	elif _atk_cd <= 0.0:
		_windup_t = WINDUP
		_eye_mat.emission = Color(1.6, 0.7, 0.2)   # bright wind-up tell
		Juice.play_3d("drone_alert", global_position, -11.0)


func _do_search(delta: float) -> void:
	_search_t -= delta
	if _can_see_player():
		_alert()
		return
	if _search_t <= 0.0 or global_position.distance_to(_last_seen) < 1.4:
		_state = State.PATROL
		_patrol_target = _pick_patrol()
		_eye_mat.emission = Color(1, 0.95, 0.5)
		return
	_move_toward(_last_seen, _speed * 0.8, delta)


# ---------------------------------------------------------------------------
# Perception / movement
# ---------------------------------------------------------------------------
func _can_see_player() -> bool:
	if _player == null:
		return false
	var to: Vector3 = _player.global_position - global_position
	var dist := to.length()
	if dist > VISION_RANGE or dist < 0.05:
		return dist <= VISION_RANGE            # point-blank always counts
	if (-global_transform.basis.z).dot(to / dist) < FOV_COS and _state == State.PATROL:
		return false                            # only the sight cone limits an unaware drone
	var from := global_position + Vector3(0, 1.0, 0)
	var params := PhysicsRayQueryParameters3D.create(from, _player.global_position + Vector3(0, 0.4, 0))
	params.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(params)
	return hit.is_empty() or hit.get("collider") == _player


## Move toward `target` along the navmesh path (routes around baked geometry).
func _move_toward(target: Vector3, speed: float, delta: float) -> void:
	if _agent == null:
		return
	if _agent.target_position.distance_to(target) > 0.75:
		_agent.target_position = target        # repath only when the goal actually moves
	var next := _agent.get_next_path_position()  # current position until the map is ready
	var dir := next - global_position
	dir.y = 0.0
	if dir.length() > 0.2:
		dir = dir.normalized()
		_desired = dir * speed
		_face(global_position + dir, delta)
	else:
		_desired = Vector3.ZERO


func _face(target: Vector3, delta: float) -> void:
	var flat := Vector3(target.x - global_position.x, 0, target.z - global_position.z)
	if flat.length() < 0.05:
		return
	var want := atan2(flat.x, flat.z)
	rotation.y = lerp_angle(rotation.y, want, clampf(TURN_RATE * delta, 0.0, 1.0))


func _pick_patrol() -> Vector3:
	var a := randf() * TAU
	var r := randf_range(1.5, PATROL_RADIUS)
	return _home + Vector3(cos(a) * r, 0, sin(a) * r)


# ---------------------------------------------------------------------------
# Combat
# ---------------------------------------------------------------------------
func _alert() -> void:
	_state = State.CHASE
	_last_seen = _player.global_position
	_eye_mat.emission = Color(1.0, 0.25, 0.2)
	Juice.play_3d("drone_alert", global_position, -4.0)


func _attack(dist: float) -> void:
	if archetype == "ranged":
		_fire_bolt()
	elif dist <= MELEE_RANGE + 0.4:
		_melee()


func _melee() -> void:
	if _player and _player.has_method("is_parrying") and _player.is_parrying():
		if _player.has_method("on_parry_success"):
			_player.on_parry_success()
		stagger()                                # parried → staggered, wide open
		return
	if _player and _player.has_method("take_damage"):
		_player.take_damage(MELEE_DAMAGE)
	Juice.play_3d("drone_shot", global_position, -3.0)
	# lunge punch (visual — velocity is owned by the avoidance callback now)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1.25, 0.8, 1.25), 0.08)
	tw.tween_property(self, "scale", Vector3.ONE, 0.12)


func _fire_bolt() -> void:
	var eye := global_position + Vector3(0, 1.0, 0) + (-global_transform.basis.z) * 0.6
	var target: Vector3 = _player.global_position + Vector3(0, 0.5, 0)
	var bolt: Node3D = ENEMY_BOLT.new()
	get_parent().add_child(bolt)
	bolt.launch(eye, target - eye)
	Juice.play_3d("drone_shot", global_position, -2.0)


# ---------------------------------------------------------------------------
# Damage / death / loot
# ---------------------------------------------------------------------------
## Parried — reel back, drop the attack, and sit open for a beat.
func stagger() -> void:
	_stun_t = STUN_TIME
	_windup_t = 0.0
	_atk_cd = maxf(_atk_cd, 0.8)
	_flash(Color(0.5, 0.75, 1.0))
	_eye_mat.emission = Color(0.4, 0.6, 1.0)


func take_hit(amount: int, kind: String) -> void:
	if vulnerable_to != "both" and kind != vulnerable_to:
		_flash(Color(0.5, 0.5, 0.55))
		return
	_last_kind = kind
	_health -= amount
	if _health <= 0:
		_die()
		return
	_flash(Color(1, 1, 1))
	if ai_enabled and _state != State.CHASE and _state != State.ATTACK:
		_alert()                                # shooting it aggros it


func _flash(c: Color) -> void:
	_mat.emission = c
	var tw := create_tween()
	tw.tween_property(_mat, "emission", _base_color * 0.4, 0.3)


func _die() -> void:
	_alive = false
	var pool := "drone_essence" if _last_kind == "spirit" else "drone_salvage"
	Loot.spawn_drops(pool, global_position, rank)

	set_deferred("collision_layer", 0)
	remove_from_group("spirit_targets")
	remove_from_group("drones")
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.2)
	tw.tween_property(_mat, "emission", Color(2, 2, 2), 0.1)
	tw.chain().tween_callback(queue_free)
