extends Area3D
## Quarry prototype — a switchable gravity region.
##
## A volume whose pull can be flipped by a gravity switch. While the player is
## inside, their "down" is the region's current up; flip it and they fall to what
## used to be the ceiling. Set `player` and `region_size` before adding to the tree.

var player: CharacterBody3D = null
var region_size := Vector3(7.0, 6.0, 7.0)
var normal_up := Vector3.UP
var flipped_up := Vector3.DOWN

var _flipped := false
var _inside := false


func _ready() -> void:
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = region_size
	col.shape = shape
	add_child(col)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node) -> void:
	if body == player:
		_inside = true


func _on_exit(body: Node) -> void:
	if body == player:
		_inside = false
		if player and not player.in_spirit:
			player.set_gravity_up(Vector3.UP)


func toggle() -> void:
	_flipped = not _flipped


func current_up() -> Vector3:
	return flipped_up if _flipped else normal_up


func _physics_process(_delta: float) -> void:
	if _inside and player and not player.in_spirit:
		player.set_gravity_up(current_up())
