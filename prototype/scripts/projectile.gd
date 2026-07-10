extends Area3D
## Quarry prototype — a weapon projectile.
##
## Travels in a straight line, damages what it hits, and — crucially — carries
## *through portals*, exiting the partner with its direction remapped. Fire into a
## portal at a bad angle and it can come back out and hit you: the design's
## "you can shoot yourself" risk, for real.

var velocity := Vector3.ZERO
var speed := 40.0
var shooter: Node = null

var _life := 4.0
var _arm := 0.10          # brief window where it can't hit the shooter (muzzle overlap)
var _portal_cd := 0.0     # stops it ping-ponging at a portal boundary


func _ready() -> void:
	add_to_group("projectiles")

	var mesh := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.12
	s.height = 0.24
	mesh.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.1)
	mat.emission_energy_multiplier = 3.0
	mesh.material_override = mat
	add_child(mesh)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.7, 0.25)
	light.omni_range = 3.5
	light.light_energy = 1.5
	add_child(light)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.15
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)


func launch(from: Vector3, dir: Vector3) -> void:
	global_position = from
	velocity = dir.normalized() * speed


func _physics_process(delta: float) -> void:
	_arm = max(0.0, _arm - delta)
	_portal_cd = max(0.0, _portal_cd - delta)
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	global_position += velocity * delta


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_hit"):
		# A drone or a gravity switch.
		body.take_hit(1, "physical")
		queue_free()
	elif body.is_in_group("player"):
		if _arm > 0.0:
			return                       # ignore the muzzle-overlap frame
		if body.has_method("hit_self"):
			body.hit_self()
		queue_free()
	else:
		queue_free()                     # wall / floor / anything solid


## Called by a portal to carry the projectile through to its partner.
func portal_transport(rel: Transform3D) -> void:
	if _portal_cd > 0.0:
		return
	global_transform = rel * global_transform
	velocity = rel.basis * velocity
	_portal_cd = 0.25
	_arm = 0.0                            # once it's been through a portal, self-hits are fair game
