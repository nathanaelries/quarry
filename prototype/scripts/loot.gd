extends Node
## Quarry prototype — loot system (autoload as `Loot`).
##
## A BOTW-style weighted drop system, themed to Quarry:
##   • Weighted pools with guaranteed drops + probability rolls.
##   • Rank escalation — Junior/Middle/Senior drones roll more, richer loot.
##   • A "condition" mechanic (BOTW's burnt→cooked): the mechanic you KILL WITH
##     transforms the drop. Shoot it → salvage. Spirit-blade it → spirit essence.
##   • Breakable containers with their own pools.
##
## Rarity colors come straight from the Art Bible palette.

const PICKUP := preload("res://scripts/pickup.gd")

const RARITY_COLOR := {
	"common": Color("D8C9A6"),      # Bone Ivory
	"uncommon": Color("7FBF6B"),    # Harvest Green
	"rare": Color("4FD4E0"),        # Portal Cyan
	"epic": Color("B79BFF"),        # Merkavah Violet
	"legendary": Color("FFE39A"),   # Emanation Gold
}

var ITEMS := {
	"chitin_shard":    {"name": "Chitin Shard",        "rarity": "common"},
	"sap_vial":        {"name": "Sap Vial",            "rarity": "common"},
	"drone_core":      {"name": "Drone Core",          "rarity": "uncommon"},
	"rune_fragment":   {"name": "Rune Fragment",       "rarity": "uncommon"},
	"gravity_cell":    {"name": "Gravity Cell",        "rarity": "rare"},
	"portal_filament": {"name": "Portal Filament",     "rarity": "rare"},
	"sefirah_mote":    {"name": "Sefirah Mote",        "rarity": "epic"},
	"keeper_core":     {"name": "Ancient Keeper Core", "rarity": "legendary"},
}

# rolls = number of probability picks; higher rank = more (and thus more rare shots).
var ROLLS := {"junior": 1, "middle": 2, "senior": 3}

var POOLS := {
	# Shot dead → salvage.
	"drone_salvage": {
		"guaranteed": [{"item": "chitin_shard", "min": 1, "max": 2}],
		"table": [
			{"item": "sap_vial", "weight": 40, "min": 1, "max": 2},
			{"item": "drone_core", "weight": 30, "min": 1, "max": 1},
			{"item": "gravity_cell", "weight": 15, "min": 1, "max": 1},
			{"item": "rune_fragment", "weight": 13, "min": 1, "max": 1},
			{"item": "keeper_core", "weight": 2, "min": 1, "max": 1},
		],
	},
	# Slain by the spirit blade → its soul yields essence.
	"drone_essence": {
		"guaranteed": [{"item": "rune_fragment", "min": 1, "max": 2}],
		"table": [
			{"item": "sefirah_mote", "weight": 34, "min": 1, "max": 1},
			{"item": "portal_filament", "weight": 26, "min": 1, "max": 1},
			{"item": "drone_core", "weight": 23, "min": 1, "max": 1},
			{"item": "sap_vial", "weight": 14, "min": 1, "max": 1},
			{"item": "keeper_core", "weight": 3, "min": 1, "max": 1},
		],
	},
	# A salvage crate.
	"salvage_crate": {
		"guaranteed": [{"item": "chitin_shard", "min": 1, "max": 3}],
		"table": [
			{"item": "sap_vial", "weight": 45, "min": 1, "max": 2},
			{"item": "drone_core", "weight": 27, "min": 1, "max": 1},
			{"item": "gravity_cell", "weight": 22, "min": 1, "max": 1},
			{"item": "keeper_core", "weight": 6, "min": 1, "max": 1},
		],
	},
	# A sacred reliquary — spirit loot.
	"reliquary": {
		"guaranteed": [{"item": "rune_fragment", "min": 1, "max": 2}],
		"table": [
			{"item": "sefirah_mote", "weight": 40, "min": 1, "max": 2},
			{"item": "portal_filament", "weight": 28, "min": 1, "max": 1},
			{"item": "sap_vial", "weight": 24, "min": 1, "max": 1},
			{"item": "keeper_core", "weight": 8, "min": 1, "max": 1},
		],
	},
}


func item_info(id: String) -> Dictionary:
	var info: Dictionary = ITEMS.get(id, {"name": id, "rarity": "common"})
	var out := info.duplicate()
	out["color"] = RARITY_COLOR.get(out["rarity"], Color.WHITE)
	return out


## Roll a pool at a rank → [{item, count}, ...] with stacks merged.
func roll(pool_name: String, rank := "junior") -> Array:
	if not POOLS.has(pool_name):
		return []
	var pool: Dictionary = POOLS[pool_name]
	var stacks := {}
	for g in pool["guaranteed"]:
		stacks[g["item"]] = stacks.get(g["item"], 0) + randi_range(g["min"], g["max"])
	var rolls: int = ROLLS.get(rank, 1)
	for _i in rolls:
		var pick := _weighted_pick(pool["table"])
		if not pick.is_empty():
			stacks[pick["item"]] = stacks.get(pick["item"], 0) + randi_range(pick["min"], pick["max"])
	var out := []
	for item in stacks:
		out.append({"item": item, "count": stacks[item]})
	return out


## Roll and spawn floating pickups around `pos`.
func spawn_drops(pool_name: String, pos: Vector3, rank := "junior") -> void:
	var drops := roll(pool_name, rank)
	var scene := get_tree().current_scene
	if scene == null:
		return
	var n := maxi(1, drops.size())
	for i in drops.size():
		var pk: Node3D = PICKUP.new()
		pk.item = drops[i]["item"]
		pk.count = drops[i]["count"]
		var ang := TAU * float(i) / float(n)
		# Set position BEFORE add_child so the pickup captures its bob-height in _ready.
		# (The world root is at identity, so local position == world position here.)
		pk.position = pos + Vector3(cos(ang) * 0.8, 0.7, sin(ang) * 0.8)
		scene.add_child(pk)


func _weighted_pick(table: Array) -> Dictionary:
	var total := 0
	for e in table:
		total += int(e["weight"])
	if total <= 0:
		return {}
	var r := randi_range(1, total)
	var acc := 0
	for e in table:
		acc += int(e["weight"])
		if r <= acc:
			return e
	return table[table.size() - 1]
