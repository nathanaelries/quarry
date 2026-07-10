extends Node3D
## Quarry — game shell (main scene root).
##
## Swaps between the hub and shrines, and remembers which shrines you've completed.
## Adding a shrine = writing a `ShrineBase` subclass and registering it in SHRINES;
## no changes here or in the hub logic beyond a pedestal entry.

const HUB := preload("res://shrines/hub.gd")
const SHRINES := {
	"reclamation": preload("res://shrines/shrine_reclamation.gd"),
}

var completed := {}
var _current: Node


func _ready() -> void:
	enter_hub()


func enter_hub() -> void:
	_swap(HUB.new())


func enter_shrine(id: String) -> void:
	if not SHRINES.has(id):
		return
	var shrine: Node = SHRINES[id].new()
	shrine.shrine_id = id
	_swap(shrine)


## Called by a shrine when its win gate is reached.
func complete_shrine(id: String) -> void:
	completed[id] = true
	enter_hub()


func _swap(node: Node) -> void:
	if _current and is_instance_valid(_current):
		_current.queue_free()
	_current = node
	add_child(node)
