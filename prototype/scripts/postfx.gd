extends Node3D
## Quarry — the poster render pipeline (look-dev).
##
## Two fullscreen post passes turn the greybox into the 1960s comic look:
##   1. ink outlines — a 3D fullscreen quad reading depth + normals (poster_outline)
##   2. comic color  — a ColorRect over the frame: posterize / halftone / grain (poster_color)
## Toggle with P to A/B against the raw greybox. Tune via the shader uniforms in the editor.
##
## NOTE: shaders can't be compile-checked headless (no GPU) — verify in-editor.

const OUTLINE_SHADER := preload("res://shaders/poster_outline.gdshader")
const COLOR_SHADER := preload("res://shaders/poster_color.gdshader")

var _outline: MeshInstance3D
var _canvas: CanvasLayer
var _enabled := true


func _ready() -> void:
	# 1. Ink outlines — a fullscreen quad in the 3D scene, never culled.
	_outline = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	_outline.mesh = quad
	_outline.custom_aabb = AABB(Vector3(-100000, -100000, -100000), Vector3(200000, 200000, 200000))
	_outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var omat := ShaderMaterial.new()
	omat.shader = OUTLINE_SHADER
	_outline.material_override = omat
	add_child(_outline)

	# 2. Comic color — a ColorRect below the HUD (layer 0; HUD is layer 1).
	_canvas = CanvasLayer.new()
	_canvas.layer = 0
	add_child(_canvas)
	var rect := ColorRect.new()
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cmat := ShaderMaterial.new()
	cmat.shader = COLOR_SHADER
	rect.material = cmat
	_canvas.add_child(rect)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fx_toggle"):
		_enabled = not _enabled
		_outline.visible = _enabled
		_canvas.visible = _enabled
