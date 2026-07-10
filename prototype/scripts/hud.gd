extends CanvasLayer
## Quarry prototype — minimal on-screen HUD: controls, current mode, and the
## spirit-projection timer. Set `player` after instancing (world.gd does this).

var player: Node = null

var _controls: Label
var _status: Label
var _meter_bg: ColorRect
var _meter_fill: ColorRect


func _ready() -> void:
	_controls = _make_label()
	_controls.position = Vector2(16, 12)
	_controls.text = "\n".join([
		"QUARRY — prototype",
		"",
		"WASD  move        Mouse  look",
		"Space jump/ascend Shift  descend (spirit)",
		"F     spirit projection (Merkavah)",
		"E     trip spirit lock (in spirit form)",
		"Esc   free mouse  ·  click to recapture",
		"",
		"Try: circle the orange planetoid · step",
		"through the cyan portal · press F and fly",
		"the spirit to the purple crystal, then E.",
	])
	add_child(_controls)

	_status = _make_label()
	_status.position = Vector2(16, 320)
	add_child(_status)

	# Spirit meter.
	_meter_bg = ColorRect.new()
	_meter_bg.color = Color(1, 1, 1, 0.15)
	_meter_bg.position = Vector2(16, 356)
	_meter_bg.size = Vector2(220, 14)
	add_child(_meter_bg)

	_meter_fill = ColorRect.new()
	_meter_fill.color = Color(0.4, 0.7, 1.0, 0.9)
	_meter_fill.position = Vector2(16, 356)
	_meter_fill.size = Vector2(0, 14)
	add_child(_meter_fill)

	if player:
		player.mode_changed.connect(_on_mode_changed)
		player.spirit_time_changed.connect(_on_spirit_time)
	_on_mode_changed(false)
	_on_spirit_time(0.0)


func _make_label() -> Label:
	var label := Label.new()
	label.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 4)
	return label


func _on_mode_changed(is_spirit: bool) -> void:
	if is_spirit:
		_status.text = "MODE: SPIRIT (Merkavah) — body left behind"
		_status.add_theme_color_override("font_color", Color(0.55, 0.8, 1.0))
	else:
		_status.text = "MODE: PHYSICAL"
		_status.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))


func _on_spirit_time(fraction: float) -> void:
	_meter_fill.size = Vector2(220.0 * clampf(fraction, 0.0, 1.0), 14)
	_meter_bg.visible = fraction > 0.0
	_meter_fill.visible = fraction > 0.0
