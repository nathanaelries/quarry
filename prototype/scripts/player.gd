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
var _trauma := 0.0                   # camera shake, decays each frame
var _step_t := 0.0

# ---- Nodes (built at runtime) --------------------------------------------
var head: Node3D                    # yaw on the body, pitch on the head
var camera: Camera3D
var body_mesh: MeshInstance3D
var spirit_pivot: Node3D            # top-level: free-flies in world space
var spirit_camera: Camera3D
var spirit_blade: MeshInstance3D

signal mode_changed(is_spirit: bool)
signal spirit_time_changed(fraction: float)
signal died()
signal resurrected()
signal picked_up(text: String, color: Color, rarity: String)

var inventory := {}                 # item id -> count


func _ready() -> void:
	_build_body()
	_build_spirit_rig()
	up_direction = current_up
	add_to_group("player")


func _build_body() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	col.shape = cap
	add_child(col)

	# A visible body so you can see it slumped over while you're in spirit form.
	body_mesh = MeshInstance3D.new()
	var capmesh := CapsuleMesh.new()
	capmesh.radius = 0.4
	capmesh.height = 1.8
	body_mesh.mesh = capmesh
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.86, 0.74, 0.52)
	body_mesh.material_override = bmat
	add_child(body_mesh)

	head = Node3D.new()
	head.position = Vector3(0, 0.7, 0)
	add_child(head)

	camera = Camera3D.new()
	head.add_child(camera)
	camera.current = true


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


## The camera currently driving the screen — physical eye, or the spirit's.
func get_active_camera() -> Camera3D:
	return spirit_camera if in_spirit else camera


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

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("spirit_toggle") and not is_dead:
		_toggle_spirit()

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

	# Gravity + jump along the current up axis.
	if not is_on_floor():
		velocity += -current_up * gravity_strength * delta
	elif Input.is_action_pressed("jump"):
		velocity += current_up * JUMP_SPEED
		if Input.is_action_just_pressed("jump"):
			Juice.play_2d("jump", -3.0)
			add_shake(0.06)

	# Movement in the plane perpendicular to "up".
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis.x * input.x + transform.basis.z * input.y)
	if dir.length() > 0.001:
		dir = dir.normalized()
	var along_up := velocity.project(current_up)
	velocity = dir * SPEED + along_up

	up_direction = current_up
	move_and_slide()
	_footsteps(delta)


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
	var cam := get_active_camera()
	if cam == null:
		return
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - delta * SHAKE_DECAY)
		var amt := _trauma * _trauma
		cam.position = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * SHAKE_MAX * amt
	else:
		cam.position = Vector3.ZERO
	# Keep whichever camera isn't active perfectly centered.
	var other := camera if in_spirit else spirit_camera
	if other:
		other.position = Vector3.ZERO


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
	spirit_camera.current = true

	Juice.set_spirit(true)
	Juice.play_2d("spirit_in", -2.0)
	add_shake(0.15)
	mode_changed.emit(true)
	spirit_time_changed.emit(1.0)


func _exit_spirit() -> void:
	in_spirit = false
	spirit_pivot.visible = false
	camera.current = true
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
## Shot yourself through a portal. Same consequence as any death: you come back.
func hit_self() -> void:
	die()


func die() -> void:
	if is_dead:
		return
	is_dead = true
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
	is_dead = false
	resurrected.emit()


# ---------------------------------------------------------------------------
# Loot
# ---------------------------------------------------------------------------
func collect(item: String, count: int, color: Color, display_name: String, rarity: String) -> void:
	inventory[item] = inventory.get(item, 0) + count
	picked_up.emit("+%d  %s" % [count, display_name], color, rarity)
	var rare := rarity == "rare" or rarity == "epic" or rarity == "legendary"
	Juice.play_3d("pickup_rare" if rare else "pickup", global_position, -5.0)
