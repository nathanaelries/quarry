extends Node
## Quarry prototype — "juice" manager (autoload as `Juice`).
##
## Everything that makes the greybox feel like a game: procedurally synthesized SFX
## (no audio files — generated in code so the repo stays self-contained), positional
## playback, impact sparks, and the spirit-mode audio filter.
##
## These are PLACEHOLDER sounds — rough synth tones meant to validate feel, not ship.
## Swap in authored audio later; the trigger points (Juice.play_3d / play_2d / spark /
## set_spirit) stay the same.

const RATE := 22050

var _lib := {}                 # name -> AudioStreamWAV
var _lp_idx := -1
var _rv_idx := -1


func _ready() -> void:
	_build_library()
	_setup_spirit_bus()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
func play_3d(name: String, pos: Vector3, volume_db := 0.0) -> void:
	if not _lib.has(name):
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = _lib[name]
	p.volume_db = volume_db
	p.unit_size = 6.0
	p.max_distance = 45.0
	add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()


func play_2d(name: String, volume_db := 0.0) -> void:
	if not _lib.has(name):
		return
	var p := AudioStreamPlayer.new()
	p.stream = _lib[name]
	p.volume_db = volume_db
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


## A quick expanding, fading glow at a hit point.
func spark(pos: Vector3, color: Color) -> void:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.15
	s.height = 0.3
	m.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 4.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material_override = mat
	add_child(m)
	m.global_position = pos
	var tw := m.create_tween()
	tw.set_parallel(true)
	tw.tween_property(m, "scale", Vector3(4, 4, 4), 0.25)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tw.chain().tween_callback(m.queue_free)


## Brief time dilation for impact (a parry, say). Real-time restore so it can't stick.
var _hitstopping := false
func hitstop(scale: float, dur: float) -> void:
	if _hitstopping:
		return
	_hitstopping = true
	Engine.time_scale = scale
	await get_tree().create_timer(dur, true, false, true).timeout
	Engine.time_scale = 1.0
	_hitstopping = false


## Toggle the ethereal lowpass + reverb on the whole mix (spirit projection).
func set_spirit(on: bool) -> void:
	if _lp_idx < 0:
		return
	AudioServer.set_bus_effect_enabled(0, _lp_idx, on)
	AudioServer.set_bus_effect_enabled(0, _rv_idx, on)


# ---------------------------------------------------------------------------
# Spirit audio bus
# ---------------------------------------------------------------------------
func _setup_spirit_bus() -> void:
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = 900.0
	var rv := AudioEffectReverb.new()
	rv.room_size = 0.85
	rv.wet = 0.45
	rv.dry = 0.7
	_lp_idx = AudioServer.get_bus_effect_count(0)
	AudioServer.add_bus_effect(0, lp)
	_rv_idx = AudioServer.get_bus_effect_count(0)
	AudioServer.add_bus_effect(0, rv)
	AudioServer.set_bus_effect_enabled(0, _lp_idx, false)
	AudioServer.set_bus_effect_enabled(0, _rv_idx, false)


# ---------------------------------------------------------------------------
# Procedural synthesis
# ---------------------------------------------------------------------------
func _build_library() -> void:
	_lib["shot"] = _wav(_tone(0.10, 520, 170, 0.55, 0.004, 3.0, 0.8))
	_lib["hit"] = _wav(_tone(0.14, 240, 90, 0.75, 0.002, 2.5, 0.9))
	_lib["step"] = _wav(_tone(0.07, 130, 68, 0.85, 0.004, 3.5, 0.7))
	_lib["jump"] = _wav(_tone(0.16, 300, 640, 0.15, 0.010, 2.2, 0.7))
	_lib["whoosh"] = _wav(_tone(0.42, 880, 210, 0.5, 0.12, 1.6, 0.85))
	_lib["whoomph"] = _wav(_mix(_tone(0.5, 150, 52, 0.3, 0.03, 1.8, 1.0), _tone(0.5, 70, 40, 0.0, 0.02, 1.6, 0.6)))
	_lib["spirit_in"] = _wav(_shimmer(0.6, [700, 1040, 1400], 0.22, false))
	_lib["spirit_out"] = _wav(_shimmer(0.42, [1200, 820, 520], 0.02, true))
	_lib["pickup"] = _wav(_tone(0.13, 680, 1080, 0.04, 0.005, 2.6, 0.55))
	_lib["pickup_rare"] = _wav(_shimmer(0.36, [900, 1350, 1780], 0.02, false))
	_lib["break"] = _wav(_tone(0.16, 220, 60, 0.9, 0.002, 2.0, 0.9))
	_lib["drone_alert"] = _wav(_tone(0.28, 480, 900, 0.05, 0.02, 1.4, 0.5))
	_lib["drone_shot"] = _wav(_tone(0.12, 900, 300, 0.3, 0.003, 2.4, 0.7))
	_lib["hurt"] = _wav(_mix(_tone(0.22, 190, 70, 0.55, 0.002, 2.0, 0.9), _tone(0.22, 95, 50, 0.0, 0.002, 1.8, 0.5)))
	_lib["dash"] = _wav(_tone(0.18, 620, 220, 0.5, 0.008, 1.6, 0.6))
	_lib["parry"] = _wav(_mix(_tone(0.15, 1500, 720, 0.18, 0.002, 2.6, 0.7), _tone(0.15, 2200, 1050, 0.08, 0.002, 2.6, 0.4)))


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	wav.data = bytes
	return wav


## A swept tone mixed with noise, shaped by an attack/decay envelope.
func _tone(dur: float, f0: float, f1: float, noise_mix: float, atk: float, curve: float, gain: float) -> PackedFloat32Array:
	var n := maxi(1, int(dur * RATE))
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(f0, f1, t)
		phase += TAU * f / RATE
		var s := lerpf(sin(phase), randf() * 2.0 - 1.0, noise_mix)
		var env := t / atk if t < atk else pow(1.0 - (t - atk) / (1.0 - atk), curve)
		out[i] = s * env * gain
	return out


## A stack of sine partials with a slow attack — an airy, sacred shimmer.
func _shimmer(dur: float, freqs: Array, atk: float, descend: bool) -> PackedFloat32Array:
	var n := maxi(1, int(dur * RATE))
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / float(n)
		var v := 0.0
		for f in freqs:
			var ff: float = f * (1.0 + (0.15 * t if descend else -0.1 * t))
			v += sin(TAU * ff * (float(i) / RATE))
		v /= float(freqs.size())
		var env := t / atk if t < atk else pow(1.0 - (t - atk) / (1.0 - atk), 2.0)
		out[i] = v * env * 0.6
	return out


func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var n := maxi(a.size(), b.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var va := a[i] if i < a.size() else 0.0
		var vb := b[i] if i < b.size() else 0.0
		out[i] = clampf(va + vb, -1.0, 1.0)
	return out
