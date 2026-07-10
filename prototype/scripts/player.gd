extends CharacterBody3D
## Quarry prototype — first-person player.
##
## Two of the three signature mechanics live here:
##   • Re-orientable gravity: the player carries a `current_up` vector instead of
##     assuming world-up, so gravity zones can make any surface the floor.
##   • Merkavah spirit projection: press the toggle to leave the (now vulnerable)
##     body as a free-flying spirit for a limited time.
##
## Everything the player needs (camera, capsule, spirit rig) is built in _ready(),
## so no scene wiring is required.

# ---- Tunables -------------------------------------------------------------
const SPEED := 6.0
const JUMP_SPEED := 7.0
const GRAVITY := 22.0
const MOUSE_SENS := 0.0022
const ORIENT_SPEED := 8.0          # how fast the body re-aligns to a new "up"
const PITCH_LIMIT := 1.4           # radians (~80°)
const SPIRIT_SPEED := 9.0
const SPIRIT_DURATION := 8.0       # seconds before the spirit is pulled home
const SPIRIT_FLOOR_Y := 0.4        # spirit slips through walls, but not through the floor
const SPIRIT_TETHER := 24.0        # the body is a leash: the spirit can't drift further than this
const BLADE_RANGE := 3.2           # spirit blade reach
const DEATH_PLANE_Y := -12.0       # fall below this and you "die" (then resurrect)
const RESURRECT_DELAY := 1.2       # seconds in the death-walk before returning

const PROJECTILE := preload("res://scripts/projectile.gd")

const SHAKE_MAX := 0.16            # camera-shake max offset (metres)
const SHAKE_DECAY := 3.2
const STEP_INTERVAL := 0.42        # seconds between footstep sfx while moving
const MAX_HEALTH := 5              # hits before the death-walk
const DASH_SPEED := 20.0           # dash burst; i-frames last the dash
const DASH_TIME := 0.16
const DASH_CD := 0.7
const PARRY_WINDOW := 0.24         # timing window a parry stays open
const PARRY_CD := 0.5
const OTS_OFFSET := Vector3(0.55, 0.35, 0)   # over-the-shoulder camera offset (right + up)
const OTS_DISTANCE := 3.2                     # how far the OTS camera trails

# ---- State ----------------------------------------------------------------
var current_up := Vector3.UP
var target_up := Vector3.UP
var gravity_strength := GRAVITY     # gravity regions can override this (e.g. a moon-light planetoid)
var body_pitch := 0.0
var spirit_pitch := 0.0
var in_spirit := false
var spirit_time_left := 0.0
var spawn_point := Vector3.ZERO     # set by world.gd after positioning; resurrection returns here
var is_dead := false
var health := MAX_HEALTH
var _trauma := 0.0                   # camera shake, decays each frame
var _step_t := 0.0
var _dash_t := 0.0                   # >0 = mid-dash (i-frames)
var _dash_cd := 0.0
var _dash_dir := Vector3.ZERO
var _parry_t := 0.0                  # >0 = parry window open
var _parry_cd := 0.0

# ---- Nodes (built at runtime) --------------------------------------------
var head: Node3D                    # yaw on the body, pitch on the head
var camera: Camera3D                # first-person eye
var ots_pivot: Node3D               # over-the-shoulder rig root (shoulder offset)
var ots_spring: SpringArm3D         # pulls the OTS camera in past walls
var ots_camera: Camera3D            # over-the-shoulder eye
var body_rig: Node3D                # Abigail proxy blockout (shown in OTS / spirit)
var spirit_pivot: Node3D            # top-level: free-flies in world space
var spirit_camera: Camera3D
var spirit_blade: MeshInstance3D

var _ots := false                   # false = first-person, true = over-the-shoulder (Gears-style)

signal mode_changed(is_spirit: bool)
signal spirit_time_changed(fraction: float)
signal died()
signal resurrected()
signal damaged(fraction: float)
signal parried()
signal picked_up(text: String, color: Color, rarity: String)
## Animation scaffold — a real AnimationTree/Player (once Abigail's clips exist) consumes these.
signal anim_state_changed(state: String)   # persistent locomotion: idle/run/air/dash/spirit/dead
signal anim_event(name: String)            # one-shots: fire/blade/parry/dash/jump/hurt

var inventory := {}                 # item id -> count
var _anim_state := "idle"


func _ready() -> void:
	_build_body()
	_build_spirit_rig()
	up_direction = current_up
	add_to_group("player")
	_update_view()


func _build_body() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	col.shape = cap
	add_child(col)

	_build_proxy_body()                 # Abigail stand-in, shown in OTS / spirit

	head = Node3D.new()
	head.position = Vector3(0, 0.7, 0)  # eye height; pitch lives here
	add_child(head)

	# First-person eye.
	camera = Camera3D.new()
	head.add_child(camera)

	# Over-the-shoulder rig: shoulder offset → spring arm (wall-avoiding) → trailing camera.
	ots_pivot = Node3D.new()
	ots_pivot.position = OTS_OFFSET
	head.add_child(ots_pivot)
	ots_spring = SpringArm3D.new()
	ots_spring.spring_length = OTS_DISTANCE
	var probe := SphereShape3D.new()
	probe.radius = 0.25
	ots_spring.shape = probe
	ots_spring.add_excluded_object(get_rid())   # never collide with our own body
	ots_pivot.add_child(ots_spring)
	ots_camera = Camera3D.new()
	ots_spring.add_child(ots_camera)


## A humanoid blockout standing in for Abigail (swap for her rigged model later).
## Body origin is the capsule centre; feet ≈ y-0.9, head ≈ y+0.9.
func _build_proxy_body() -> void:
	body_rig = Node3D.new()
	add_child(body_rig)
	var suit := Color(0.16, 0.16, 0.3)
	var accent := Color(0.35, 0.85, 1.0)
	_part(Vector3(0.48, 0.66, 0.28), Vector3(0, 0.18, 0), suit)               # torso
	_part(Vector3(0.4, 0.22, 0.26), Vector3(0, -0.28, 0), suit)               # hips
	_part(Vector3(0.16, 0.6, 0.18), Vector3(-0.12, -0.68, 0), suit)           # left leg
	_part(Vector3(0.16, 0.6, 0.18), Vector3(0.12, -0.68, 0), suit)            # right leg
	_part(Vector3(0.13, 0.52, 0.15), Vector3(-0.33, 0.16, 0), suit)           # left arm
	_part(Vector3(0.13, 0.52, 0.15), Vector3(0.33, 0.16, 0), suit)            # right arm
	_part(Vector3(0.34, 0.34, 0.32), Vector3(0, 0.7, 0), suit)               # head
	_part(Vector3(0.26, 0.12, 0.06), Vector3(0, 0.72, -0.17), accent, true)   # visor (front = -Z)
	_part(Vector3(0.14, 0.14, 0.05), Vector3(0, 0.2, -0.15), accent, true)    # chest emblem


func _part(size: Vector3, pos: Vector3, color: Color, emissive := false) -> void:
	var m := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	m.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.4
	m.material_override = mat
	m.position = pos
	body_rig.add_child(m)


func _build_spirit_rig() -> void:
	spirit_pivot = Node3D.new()
	spirit_pivot.top_level = true          # move in world space, ignore body transform
	add_child(spirit_pivot)

	spirit_camera = Camera3D.new()
	spirit_pivot.add_child(spirit_camera)

	# A small glowing wisp marks where the spirit is.
	var wisp := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	wisp.mesh = sphere
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.55, 0.8, 1.0, 0.55)
	smat.emission_enabled = true
	smat.emission = Color(0.4, 0.7, 1.0)
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wisp.mesh.material = smat
	spirit_pivot.add_child(wisp)

	# Spirit blade: a thin glowing edge in front of the eye, shown for a beat on a slash.
	spirit_blade = MeshInstance3D.new()
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.06, 1.2, 0.5)
	spirit_blade.mesh = blade_mesh
	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.7, 0.9, 1.0, 0.7)
	blade_mat.emission_enabled = true
	blade_mat.emission = Color(0.6, 0.85, 1.0)
	blade_mat.emission_energy_multiplier = 2.0
	blade_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spirit_blade.mesh.material = blade_mat
	spirit_blade.position = Vector3(0.4, -0.2, -0.9)
	spirit_blade.rotation_degrees = Vector3(0, 0, 25)
	spirit_blade.visible = false
	spirit_camera.add_child(spirit_blade)

	spirit_pivot.visible = false


## The camera currently driving the screen — spirit, over-the-shoulder, or first-person.
func get_active_camera() -> Camera3D:
	if in_spirit:
		return spirit_camera
	return ots_camera if _ots else camera


## Make the right camera current and show the body only when it'd be on screen.
func _update_view() -> void:
	if in_spirit:
		spirit_camera.current = true
	elif _ots:
		ots_camera.current = true
	else:
		camera.current = true
	# Body is visible in over-the-shoulder and while projecting; hidden in first-person.
	body_rig.visible = _ots or in_spirit


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	# Left click: recapture the mouse if free, otherwise fire.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif not is_dead:
			_fire()

	# Right click: parry (physical only).
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if not is_dead and not in_spirit and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_parry()

	if event.is_action_pressed("dash") and not in_spirit and not is_dead:
		_dash()

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("spirit_toggle") and not is_dead:
		_toggle_spirit()

	if event.is_action_pressed("camera_toggle"):
		_ots = not _ots
		_update_view()

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if in_spirit:
			spirit_pivot.rotate_y(-event.relative.x * MOUSE_SENS)
			spirit_pitch = clampf(spirit_pitch - event.relative.y * MOUSE_SENS, -PITCH_LIMIT, PITCH_LIMIT)
			spirit_camera.rotation.x = spirit_pitch
		else:
			# Yaw around the *current* gravity up so mouse-look stays sane on walls.
			rotate(current_up, -event.relative.x * MOUSE_SENS)
			body_pitch = clampf(body_pitch - event.relative.y * MOUSE_SENS, -PITCH_LIMIT, PITCH_LIMIT)
			head.rotation.x = body_pitch


# ---------------------------------------------------------------------------
# Physics
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if global_position.y < DEATH_PLANE_Y:
		die()
		return
	if in_spirit:
		_process_spirit(delta)
		return

	_reorient(delta)
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_parry_cd = maxf(0.0, _parry_cd - delta)
	_parry_t = maxf(0.0, _parry_t - delta)

	# Gravity + jump along the current up axis.
	if not is_on_floor():
		velocity += -current_up * gravity_strength * delta
	elif Input.is_action_pressed("jump"):
		velocity += current_up * JUMP_SPEED
		if Input.is_action_just_pressed("jump"):
			Juice.play_2d("jump", -3.0)
			add_shake(0.06)
			anim_event.emit("jump")

	# Movement in the plane perpendicular to "up" — a dash overrides it.
	var along_up := velocity.project(current_up)
	if _dash_t > 0.0:
		_dash_t -= delta
		velocity = _dash_dir * DASH_SPEED + along_up
	else:
		var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var dir := (transform.basis.x * input.x + transform.basis.z * input.y)
		if dir.length() > 0.001:
			dir = dir.normalized()
		velocity = dir * SPEED + along_up

	up_direction = current_up
	move_and_slide()
	_footsteps(delta)
	_update_anim(delta)


## Derive the locomotion state and give the proxy some life. A real AnimationTree
## (once Abigail has clips) subscribes to anim_state_changed / anim_event instead.
func _update_anim(delta: float) -> void:
	var planar := (velocity - velocity.project(current_up)).length()
	var s := "idle"
	if _dash_t > 0.0:
		s = "dash"
	elif not is_on_floor():
		s = "air"
	elif planar > 0.7:
		s = "run"
	_set_anim_state(s)
	var lean := -0.14 if (s == "run" or s == "dash") else 0.0
	body_rig.rotation.x = lerp(body_rig.rotation.x, lean, clampf(delta * 8.0, 0.0, 1.0))


func _set_anim_state(s: String) -> void:
	if s != _anim_state:
		_anim_state = s
		anim_state_changed.emit(s)


func _footsteps(delta: float) -> void:
	var planar_speed := (velocity - velocity.project(current_up)).length()
	if is_on_floor() and planar_speed > 1.5:
		_step_t += delta
		if _step_t >= STEP_INTERVAL:
			_step_t = 0.0
			Juice.play_3d("step", global_position, -7.0)
	else:
		_step_t = STEP_INTERVAL      # first step lands promptly when you start moving


## Smoothly rotate the body so its local up tracks `target_up`.
func _reorient(delta: float) -> void:
	if current_up.is_equal_approx(target_up):
		return
	var next_up := current_up.slerp(target_up, clampf(delta * ORIENT_SPEED, 0.0, 1.0))
	if next_up.length() < 0.001:
		return
	next_up = next_up.normalized()
	var q := Quaternion(current_up, next_up)
	transform.basis = Basis(q) * transform.basis
	current_up = next_up
	up_direction = current_up


## Called by gravity regions to request a new down/up, with an optional field strength.
func set_gravity_up(new_up: Vector3, strength := GRAVITY) -> void:
	if new_up.length() < 0.001:
		return
	var n := new_up.normalized()
	# A real re-orientation (not the tiny per-frame drift of a planetoid) gets a whoomph.
	if target_up.angle_to(n) > 0.44:
		add_shake(0.35)
		Juice.play_3d("whoomph", global_position, -1.0)
	target_up = n
	gravity_strength = strength


# ---------------------------------------------------------------------------
# Camera shake (juice)
# ---------------------------------------------------------------------------
func add_shake(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	var offset := Vector3.ZERO
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - delta * SHAKE_DECAY)
		var amt := _trauma * _trauma
		offset = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * SHAKE_MAX * amt
	# Reset every rig, then shake only the active one. (The OTS camera's own position is
	# owned by the spring arm, so its shake rides on the pivot instead.)
	camera.position = Vector3.ZERO
	spirit_camera.position = Vector3.ZERO
	ots_pivot.position = OTS_OFFSET
	if in_spirit:
		spirit_camera.position = offset
	elif _ots:
		ots_pivot.position = OTS_OFFSET + offset
	else:
		camera.position = offset


# ---------------------------------------------------------------------------
# Merkavah — spirit projection
# ---------------------------------------------------------------------------
func _toggle_spirit() -> void:
	if in_spirit:
		_exit_spirit()
	else:
		_enter_spirit()


func _enter_spirit() -> void:
	in_spirit = true
	spirit_time_left = SPIRIT_DURATION
	velocity = Vector3.ZERO                 # the body slumps where it stands

	spirit_pivot.global_position = head.global_position
	spirit_pivot.rotation = Vector3.ZERO    # world-aligned free-fly
	spirit_pitch = 0.0
	spirit_camera.rotation = Vector3.ZERO
	spirit_pivot.visible = true
	_update_view()                          # switch to the spirit camera, show the body

	Juice.set_spirit(true)
	Juice.play_2d("spirit_in", -2.0)
	add_shake(0.15)
	_set_anim_state("spirit")
	mode_changed.emit(true)
	spirit_time_changed.emit(1.0)


func _exit_spirit() -> void:
	in_spirit = false
	spirit_pivot.visible = false
	_update_view()                          # back to the last physical view (FP or OTS)
	Juice.set_spirit(false)
	Juice.play_2d("spirit_out", -3.0)
	mode_changed.emit(false)
	spirit_time_changed.emit(0.0)


func _process_spirit(delta: float) -> void:
	spirit_time_left -= delta
	if spirit_time_left <= 0.0:
		_exit_spirit()
		return
	spirit_time_changed.emit(spirit_time_left / SPIRIT_DURATION)

	# Free-fly relative to where the spirit is looking.
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis := spirit_camera.global_transform.basis
	var move := cam_basis.x * input.x + cam_basis.z * input.y
	if move.length() > 0.001:
		move = move.normalized()
	var lift := 0.0
	if Input.is_action_pressed("jump"):
		lift += 1.0
	if Input.is_action_pressed("descend"):
		lift -= 1.0
	move += Vector3.UP * lift
	spirit_pivot.global_position += move * SPIRIT_SPEED * delta

	# The spirit is incorporeal (it passes through walls), but stop it from
	# sinking below the floor into the void under the map.
	if spirit_pivot.global_position.y < SPIRIT_FLOOR_Y:
		var p := spirit_pivot.global_position
		p.y = SPIRIT_FLOOR_Y
		spirit_pivot.global_position = p

	# The body is a leash — the spirit can't drift beyond the tether.
	var leash := spirit_pivot.global_position - global_position
	if leash.length() > SPIRIT_TETHER:
		spirit_pivot.global_position = global_position + leash.normalized() * SPIRIT_TETHER


# ---------------------------------------------------------------------------
# Weapons — the physical gun, and the spirit blade
# ---------------------------------------------------------------------------
func _fire() -> void:
	if in_spirit:
		_slash()
	else:
		_shoot()


func _shoot() -> void:
	var cam := camera
	var forward := -cam.global_transform.basis.z
	var muzzle := cam.global_position + forward * 1.2
	var proj := PROJECTILE.new()
	proj.shooter = self
	get_parent().add_child(proj)         # lives in the world, not parented to the player
	proj.launch(muzzle, forward)
	anim_event.emit("fire")

	# Juice: muzzle flash + report + kick.
	var flash := OmniLight3D.new()
	flash.light_color = Color(1.0, 0.8, 0.4)
	flash.omni_range = 4.0
	flash.light_energy = 3.0
	get_parent().add_child(flash)
	flash.global_position = muzzle
	var tw := flash.create_tween()
	tw.tween_property(flash, "light_energy", 0.0, 0.08)
	tw.tween_callback(flash.queue_free)
	Juice.play_3d("shot", muzzle, -3.0)
	add_shake(0.12)


func _slash() -> void:
	spirit_blade.visible = true
	var origin := spirit_pivot.global_position
	var forward := -spirit_camera.global_transform.basis.z
	Juice.play_3d("whoosh", origin, -6.0)
	add_shake(0.08)
	anim_event.emit("blade")
	for target in get_tree().get_nodes_in_group("spirit_targets"):
		if not is_instance_valid(target):
			continue
		var to_target: Vector3 = target.global_position - origin
		if to_target.length() <= BLADE_RANGE and forward.dot(to_target.normalized()) > 0.3:
			if target.has_method("take_hit"):
				target.take_hit(1, "spirit")
			Juice.spark(target.global_position, Color(0.6, 0.85, 1.0))
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(spirit_blade):
		spirit_blade.visible = false


# ---------------------------------------------------------------------------
# Death & resurrection — dying is a beat, not a wall
# ---------------------------------------------------------------------------
## Taken a hit from a drone.
func take_damage(amount: int) -> void:
	if is_dead or _dash_t > 0.0:      # dash grants i-frames
		return
	health = maxi(0, health - amount)
	add_shake(0.28)
	Juice.play_2d("hurt", -2.0)
	anim_event.emit("hurt")
	damaged.emit(float(health) / float(MAX_HEALTH))
	if health <= 0:
		die()


## Shot yourself through a portal. Same consequence as any death: you come back.
func hit_self() -> void:
	die()


# ---------------------------------------------------------------------------
# Dash & parry
# ---------------------------------------------------------------------------
func is_parrying() -> bool:
	return _parry_t > 0.0


func _dash() -> void:
	if _dash_cd > 0.0 or _dash_t > 0.0:
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var d := transform.basis.x * input.x + transform.basis.z * input.y
	if d.length() < 0.1:
		d = -transform.basis.z                    # no input → dash forward
	d = d - d.project(current_up)                 # keep it on the movement plane
	if d.length() < 0.01:
		return
	_dash_dir = d.normalized()
	_dash_t = DASH_TIME
	_dash_cd = DASH_CD
	Juice.play_2d("dash", -4.0)
	add_shake(0.1)
	anim_event.emit("dash")


func _parry() -> void:
	if _parry_cd > 0.0:
		return
	_parry_t = PARRY_WINDOW
	_parry_cd = PARRY_CD


## An attacker's hit landed inside the parry window (called by drones / bolts).
func on_parry_success() -> void:
	_parry_t = 0.0                                 # consume the window
	Juice.play_2d("parry", 0.0)
	Juice.hitstop(0.32, 0.1)
	add_shake(0.14)
	anim_event.emit("parry")
	parried.emit()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	_set_anim_state("dead")
	if in_spirit:
		_exit_spirit()
	velocity = Vector3.ZERO
	died.emit()
	_resurrect()


func _resurrect() -> void:
	await get_tree().create_timer(RESURRECT_DELAY).timeout
	# Return to the body at the last safe spawn, upright and whole.
	current_up = Vector3.UP
	target_up = Vector3.UP
	gravity_strength = GRAVITY
	transform.basis = Basis()
	body_pitch = 0.0
	head.rotation.x = 0.0
	velocity = Vector3.ZERO
	global_position = spawn_point
	up_direction = current_up
	health = MAX_HEALTH
	_dash_t = 0.0
	_parry_t = 0.0
	is_dead = false
	damaged.emit(1.0)
	resurrected.emit()


# ---------------------------------------------------------------------------
# Loot
# ---------------------------------------------------------------------------
func collect(item: String, count: int, color: Color, display_name: String, rarity: String) -> void:
	inventory[item] = inventory.get(item, 0) + count
	picked_up.emit("+%d  %s" % [count, display_name], color, rarity)
	var rare := rarity == "rare" or rarity == "epic" or rarity == "legendary"
	Juice.play_3d("pickup_rare" if rare else "pickup", global_position, -5.0)
