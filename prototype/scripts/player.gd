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

# ---- State ----------------------------------------------------------------
var current_up := Vector3.UP
var target_up := Vector3.UP
var gravity_strength := GRAVITY     # gravity regions can override this (e.g. a moon-light planetoid)
var body_pitch := 0.0
var spirit_pitch := 0.0
var in_spirit := false
var spirit_time_left := 0.0

# ---- Nodes (built at runtime) --------------------------------------------
var head: Node3D                    # yaw on the body, pitch on the head
var camera: Camera3D
var body_mesh: MeshInstance3D
var spirit_pivot: Node3D            # top-level: free-flies in world space
var spirit_camera: Camera3D

signal mode_changed(is_spirit: bool)
signal spirit_time_changed(fraction: float)


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

	spirit_pivot.visible = false


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("spirit_toggle"):
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
	if in_spirit:
		_process_spirit(delta)
		return

	_reorient(delta)

	# Gravity + jump along the current up axis.
	if not is_on_floor():
		velocity += -current_up * gravity_strength * delta
	elif Input.is_action_pressed("jump"):
		velocity += current_up * JUMP_SPEED

	# Movement in the plane perpendicular to "up".
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis.x * input.x + transform.basis.z * input.y)
	if dir.length() > 0.001:
		dir = dir.normalized()
	var along_up := velocity.project(current_up)
	velocity = dir * SPEED + along_up

	up_direction = current_up
	move_and_slide()


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
	target_up = new_up.normalized()
	gravity_strength = strength


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

	mode_changed.emit(true)
	spirit_time_changed.emit(1.0)


func _exit_spirit() -> void:
	in_spirit = false
	spirit_pivot.visible = false
	camera.current = true
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
