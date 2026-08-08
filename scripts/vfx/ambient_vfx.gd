extends Control
class_name AmbientVFX
## Cheap procedural atmosphere for residence artwork. Particles are a data
## array redrawn each frame (no per-particle nodes), capped by graphics
## tier, and processing stops while hidden/off-screen. Each residence
## combines whichever named layers actually suit it (a farmhouse doesn't
## need Northgate's sparks, Saint Mercy doesn't need Hollow Creek's chimney
## smoke) instead of picking one exclusive preset for the whole screen -
## see ui_animation_director.gd's per-scene layer lists.

const VALID_LAYERS := ["rain", "fog", "dust", "leaves", "smoke", "embers", "sparks", "radio_pulse", "foliage"]

## Which named effects this instance combines. Invalid/unknown names are
## ignored rather than erroring, so a typo degrades to "no extra layer"
## instead of breaking the whole background.
@export var layers: Array[String] = ["dust"]

var _time := 0.0
var _layer_particles: Dictionary = {} # layer name -> Array[Dictionary]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	_build_particles()
	visibility_changed.connect(_update_processing)
	EventBus.settings_changed.connect(_on_settings_changed)
	_update_processing()

func _on_settings_changed() -> void:
	_build_particles()
	_update_processing()

func _update_processing() -> void:
	set_process(is_visible_in_tree() and GameManager.effects_enabled())
	queue_redraw()

func _particle_budget() -> int:
	var quality := String(GameManager.settings.get("graphics_quality", "standard"))
	if quality == "low":
		return 0
	return 18 if quality == "high" else 10

func _build_particles() -> void:
	_layer_particles.clear()
	var count := _particle_budget()
	for layer in layers:
		if not VALID_LAYERS.has(layer):
			continue
		var layer_count: int = 1 if layer == "radio_pulse" else count
		var particles: Array[Dictionary] = []
		for i in layer_count:
			particles.append({"p": Vector2(randf(), randf()), "s": randf_range(0.35, 1.0), "o": randf_range(0.25, 1.0)})
		_layer_particles[layer] = particles

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	if not GameManager.effects_enabled(): return
	_draw_cloud_shadows()
	for layer in layers:
		if not VALID_LAYERS.has(layer):
			continue
		match layer:
			"rain": _draw_rain()
			"fog": _draw_fog()
			"dust": _draw_dust()
			"leaves": _draw_leaves()
			"smoke": _draw_smoke()
			"embers": _draw_embers()
			"sparks": _draw_sparks()
			"radio_pulse": _draw_radio_pulse()
			"foliage": _draw_foliage()
	_draw_lantern_flicker()

## Slow-moving cloud shadow bands, present regardless of the specific layer
## list - cheap, universal, and already correct before this rewrite (was
## previously drawn unconditionally at the top of _draw for every preset).
func _draw_cloud_shadows() -> void:
	var cloud_x := fmod(_time * 7.0, size.x + 260.0) - 260.0
	draw_circle(Vector2(cloud_x, size.y * 0.16), 150.0, Color(0.31, 0.38, 0.42, 0.055))
	draw_circle(Vector2(size.x - cloud_x, size.y * 0.25), 110.0, Color(0.18, 0.22, 0.24, 0.045))

## Lantern/interior-light flicker, present for the same reason as the cloud
## shadows above - subtle warm light over final art, on every residence.
func _draw_lantern_flicker() -> void:
	var flicker := 0.025 + sin(_time * 8.3) * 0.009 + sin(_time * 13.7) * 0.006
	draw_circle(Vector2(size.x * 0.58, size.y * 0.47), size.x * 0.11, Color(0.95, 0.55, 0.20, maxf(0.0, flicker)))

func _drift(d: Dictionary, horizontal_speed: float, vertical_speed: float) -> Vector2:
	var p: Vector2 = d.p
	var speed: float = d.s
	var x := fmod(p.x * size.x + _time * horizontal_speed * (0.6 + speed * 0.6), size.x + 20.0) - 10.0
	var y := fmod(p.y * size.y + _time * vertical_speed * speed, size.y + 20.0) - 10.0
	return Vector2(x, y)

func _draw_rain() -> void:
	for d in _layer_particles.get("rain", []):
		var pos: Vector2 = _drift(d, 10.0, 52.0)
		draw_line(pos, pos + Vector2(-5, 13), Color(0.66, 0.77, 0.82, 0.12 + 0.12 * float(d.o)), 1.0)

func _draw_fog() -> void:
	for d in _layer_particles.get("fog", []):
		var pos: Vector2 = _drift(d, 6.0, -3.0)
		draw_circle(pos, 18.0 * float(d.s), Color(0.64, 0.68, 0.66, 0.035))

func _draw_dust() -> void:
	for d in _layer_particles.get("dust", []):
		var pos: Vector2 = _drift(d, 10.0, -6.0)
		draw_circle(pos, 1.2 + float(d.s), Color(0.77, 0.68, 0.52, 0.18))

## Leaves: falls faster than dust/fog and tumbles (rotation), drifting more
## horizontally - a small triangle rather than a dot so tumbling reads.
func _draw_leaves() -> void:
	for d in _layer_particles.get("leaves", []):
		var pos: Vector2 = _drift(d, 26.0, 34.0)
		var spin := _time * (1.4 + float(d.s))
		var r := 4.0 + float(d.s) * 2.0
		var pts := PackedVector2Array([
			pos + Vector2(cos(spin), sin(spin)) * r,
			pos + Vector2(cos(spin + TAU / 3.0), sin(spin + TAU / 3.0)) * r,
			pos + Vector2(cos(spin + TAU * 2.0 / 3.0), sin(spin + TAU * 2.0 / 3.0)) * r,
		])
		draw_colored_polygon(pts, Color(0.62, 0.48, 0.22, 0.22 + 0.1 * float(d.o)))

## Smoke: rises and slowly expands/fades from a low source - distinct from
## fog by moving upward rather than drifting sideways at fixed height.
func _draw_smoke() -> void:
	for d in _layer_particles.get("smoke", []):
		var p: Vector2 = d.p
		var speed: float = d.s
		var rise := fmod(_time * (14.0 + speed * 10.0), size.y * 0.9)
		var pos := Vector2(p.x * size.x * 0.3 + size.x * 0.1 + sin(_time * 0.6 + speed * 6.0) * 10.0, size.y * 0.55 - rise)
		var puff_radius := 6.0 + rise * 0.05
		var fade := clampf(1.0 - rise / (size.y * 0.9), 0.0, 1.0)
		draw_circle(pos, puff_radius, Color(0.22, 0.21, 0.19, 0.10 * fade))

## Embers: small warm motes rising from a fire/chimney source, brighter and
## smaller than smoke, with a flicker instead of smoke's steady fade.
func _draw_embers() -> void:
	for d in _layer_particles.get("embers", []):
		var p: Vector2 = d.p
		var speed: float = d.s
		var rise := fmod(_time * (30.0 + speed * 24.0), size.y * 0.7)
		var pos := Vector2(p.x * size.x * 0.2 + size.x * 0.15 + sin(_time * 1.4 + speed * 9.0) * 6.0, size.y * 0.6 - rise)
		var glow := 0.5 + 0.5 * sin(_time * 9.0 + speed * 20.0)
		var fade := clampf(1.0 - rise / (size.y * 0.7), 0.0, 1.0)
		draw_circle(pos, 1.4, Color(0.95, 0.55, 0.18, 0.5 * fade * glow))

func _draw_sparks() -> void:
	var particles: Array = _layer_particles.get("sparks", [])
	for index in particles.size():
		var d: Dictionary = particles[index]
		var pos: Vector2 = _drift(d, 10.0, -6.0)
		var spark_alpha := 0.8 if fmod(_time * 3.0 + index, 11.0) < 0.18 else 0.0
		draw_line(pos, pos + Vector2(4, 6), Color(0.95, 0.67, 0.24, spark_alpha), 1.5)

## Radio pulse: concentric rings expanding from a fixed point, same motif as
## the old industrial-only version, now its own independently placeable layer.
func _draw_radio_pulse() -> void:
	var radio_center := Vector2(size.x * 0.78, size.y * 0.35)
	for ring in 3:
		var radius := fmod(_time * 18.0 + ring * 10.0, 30.0)
		draw_circle(radio_center, radius, Color(0.37, 0.75, 0.82, 0.12 * (1.0 - radius / 30.0)), false, 1.2)

## Foliage: grass/low vegetation swaying side to side near the bottom edge -
## motion is a sway, not a fall/rise, so it reads distinct from leaves/dust.
func _draw_foliage() -> void:
	var blade_count := 5
	for i in blade_count:
		var base_x := size.x * (0.08 + 0.85 * float(i) / float(blade_count - 1))
		var base_y := size.y - 6.0
		var sway := sin(_time * 1.6 + float(i) * 1.3) * 5.0
		draw_line(Vector2(base_x, base_y), Vector2(base_x + sway, base_y - 22.0), Color(0.34, 0.4, 0.26, 0.22), 2.0)
