extends Node3D
## Quarry — game shell (main scene root).
##
## Swaps between the hub and chambers, and remembers which chambers you've completed.
## Adding a chamber = writing a `ChamberBase` subclass and registering it in CHAMBERS;
## no changes here or in the hub logic beyond a pedestal entry.

const HUB := preload("res://chambers/hub.gd")
const CHAMBERS := {
	"reclamation": preload("res://chambers/chamber_reclamation.gd"),
}

var completed := {}
var _current: Node


func _ready() -> void:
	enter_hub()


func enter_hub() -> void:
	_swap(HUB.new())


func enter_chamber(id: String) -> void:
	if not CHAMBERS.has(id):
		return
	var chamber: Node = CHAMBERS[id].new()
	chamber.chamber_id = id
	_swap(chamber)


## Called by a chamber when its win gate is reached.
func complete_chamber(id: String) -> void:
	completed[id] = true
	enter_hub()


func _swap(node: Node) -> void:
	if _current and is_instance_valid(_current):
		_current.queue_free()
	_current = node
	add_child(node)
