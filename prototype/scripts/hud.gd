extends CanvasLayer
## Quarry prototype — minimal on-screen HUD: controls, current mode, and the
## spirit-projection timer. Set `player` after instancing (world.gd does this).

var player: Node = null

var _controls: Label
var _status: Label
var _meter_bg: ColorRect
var _meter_fill: ColorRect
var _death_bg: ColorRect
var _death_text: Label
var _inv: Label
var _toast_y := 560.0
var _pips: Array = []
var _dmg_flash: ColorRect
var _parry_fx: ColorRect
var _objective: Label
var _win_bg: ColorRect
var _win_text: Label
const HEALTH_PIPS := 5


func _ready() -> void:
	_controls = _make_label()
	_controls.position = Vector2(16, 12)
	_controls.text = "\n".join([
		"QUARRY — The Reclamation",
		"",
		"WASD move · Mouse look · LMB fire / blade · RMB parry",
		"Shift dash (physical) / descend (spirit) · Space jump / ascend",
		"V camera (first-person ⇄ over-the-shoulder)",
		"F spirit projection · E interact / trip lock · Esc mouse",
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

	_build_crosshair()
	_build_death_overlay()
	_build_health()
	_build_objective()

	_inv = _make_label()
	_inv.position = Vector2(16, 402)
	add_child(_inv)

	if player:
		player.mode_changed.connect(_on_mode_changed)
		player.spirit_time_changed.connect(_on_spirit_time)
		player.died.connect(_on_died)
		player.resurrected.connect(_on_resurrected)
		player.picked_up.connect(_on_picked_up)
		player.damaged.connect(_on_damaged)
		player.parried.connect(_on_parried)
	_on_mode_changed(false)
	_on_spirit_time(0.0)
	_refresh_inventory()
	_on_damaged(1.0)


func _build_crosshair() -> void:
	var center := get_viewport().get_visible_rect().size * 0.5
	var dot := Label.new()
	dot.text = "+"
	dot.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	dot.add_theme_font_size_override("font_size", 22)
	dot.position = center - Vector2(7, 16)
	add_child(dot)


func _build_death_overlay() -> void:
	_death_bg = ColorRect.new()
	_death_bg.color = Color(0.02, 0.0, 0.06, 0.6)
	_death_bg.anchor_right = 1.0
	_death_bg.anchor_bottom = 1.0
	_death_bg.visible = false
	add_child(_death_bg)

	_death_text = Label.new()
	_death_text.text = "The World of Emanation…\nreturning"
	_death_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_text.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	_death_text.add_theme_font_size_override("font_size", 28)
	_death_text.position = get_viewport().get_visible_rect().size * 0.5 - Vector2(160, 40)
	_death_text.size = Vector2(320, 80)
	_death_text.visible = false
	add_child(_death_text)


func _build_health() -> void:
	var cx := get_viewport().get_visible_rect().size.x
	var total_w := HEALTH_PIPS * 26.0 - 6.0
	var start_x := cx * 0.5 - total_w * 0.5
	for i in HEALTH_PIPS:
		var pip := ColorRect.new()
		pip.size = Vector2(20, 20)
		pip.position = Vector2(start_x + i * 26.0, 24)
		add_child(pip)
		_pips.append(pip)

	_dmg_flash = ColorRect.new()
	_dmg_flash.color = Color(0.8, 0.1, 0.12, 0.0)
	_dmg_flash.anchor_right = 1.0
	_dmg_flash.anchor_bottom = 1.0
	_dmg_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dmg_flash)

	_parry_fx = ColorRect.new()
	_parry_fx.color = Color(1.0, 0.85, 0.4, 0.0)
	_parry_fx.anchor_right = 1.0
	_parry_fx.anchor_bottom = 1.0
	_parry_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_parry_fx)


func _build_objective() -> void:
	var vp := get_viewport().get_visible_rect().size
	_objective = _make_label()
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective.add_theme_font_size_override("font_size", 18)
	_objective.size = Vector2(780, 26)
	_objective.position = Vector2(vp.x * 0.5 - 390, 52)
	add_child(_objective)


## Update the running objective line.
func set_objective(text: String) -> void:
	if _objective:
		_objective.text = "◈  " + text


## Show the level-complete banner and dim the world.
func level_complete() -> void:
	if _win_bg == null:
		var vp := get_viewport().get_visible_rect().size
		_win_bg = ColorRect.new()
		_win_bg.color = Color(0.04, 0.03, 0.0, 0.0)
		_win_bg.anchor_right = 1.0
		_win_bg.anchor_bottom = 1.0
		_win_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_win_bg)

		_win_text = Label.new()
		_win_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_win_text.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))
		_win_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		_win_text.add_theme_constant_override("outline_size", 6)
		_win_text.add_theme_font_size_override("font_size", 40)
		_win_text.text = "THE RECLAMATION — ESCAPED"
		_win_text.size = Vector2(vp.x, 120)
		_win_text.position = Vector2(0, vp.y * 0.5 - 60)
		add_child(_win_text)
	var tw := create_tween()
	tw.tween_property(_win_bg, "color:a", 0.72, 1.0)


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


func _on_died() -> void:
	_death_bg.visible = true
	_death_text.visible = true


func _on_resurrected() -> void:
	_death_bg.visible = false
	_death_text.visible = false


func _on_damaged(fraction: float) -> void:
	var filled := int(round(fraction * HEALTH_PIPS))
	for i in _pips.size():
		_pips[i].color = Color(0.9, 0.3, 0.32) if i < filled else Color(1, 1, 1, 0.14)
	if fraction < 1.0 and _dmg_flash:
		_dmg_flash.color.a = 0.34
		var tw := create_tween()
		tw.tween_property(_dmg_flash, "color:a", 0.0, 0.3)


func _on_parried() -> void:
	if _parry_fx:
		_parry_fx.color.a = 0.42
		var tw := create_tween()
		tw.tween_property(_parry_fx, "color:a", 0.0, 0.35)


func _on_picked_up(text: String, color: Color, rarity: String) -> void:
	var t := Label.new()
	t.text = text
	t.add_theme_color_override("font_color", color)
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	t.add_theme_constant_override("outline_size", 5)
	var big := rarity == "rare" or rarity == "epic" or rarity == "legendary"
	t.add_theme_font_size_override("font_size", 23 if big else 18)
	var cx := get_viewport().get_visible_rect().size.x
	t.position = Vector2(cx * 0.5 - 70, _toast_y)
	add_child(t)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(t, "position:y", t.position.y - 62, 1.4)
	tw.tween_property(t, "modulate:a", 0.0, 1.1).set_delay(0.4)
	tw.chain().tween_callback(t.queue_free)
	_refresh_inventory()


func _refresh_inventory() -> void:
	if player == null:
		return
	var inv: Dictionary = player.inventory
	if inv.is_empty():
		_inv.text = "SATCHEL — empty"
		return
	var lines := ["SATCHEL"]
	for id in inv:
		var nm: String = Loot.item_info(id).get("name", id)
		lines.append("%s  ×%d" % [nm, inv[id]])
	_inv.text = "\n".join(lines)
