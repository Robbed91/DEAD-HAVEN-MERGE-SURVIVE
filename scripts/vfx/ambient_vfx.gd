extends Control
class_name AmbientVFX
## Cheap procedural atmosphere for residence artwork. Particles are pooled,
## capped by graphics tier, and processing stops while hidden/off-screen.

@export_enum("storm", "dust", "fog", "industrial") var preset := "storm"
var _time := 0.0
var _particles: Array[Dictionary] = []

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

func _build_particles() -> void:
	_particles.clear()
	var quality := String(GameManager.settings.get("graphics_quality", "standard"))
	var count := 10 if quality == "standard" else 18
	if quality == "low": count = 0
	for i in count:
		_particles.append({"p": Vector2(randf(), randf()), "s": randf_range(0.35, 1.0), "o": randf_range(0.25, 1.0)})

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	if not GameManager.effects_enabled(): return
	# Slow fog/cloud bands and intermittent warm flicker.
	var cloud_x := fmod(_time * 7.0, size.x + 260.0) - 260.0
	draw_circle(Vector2(cloud_x, size.y * 0.16), 150.0, Color(0.31, 0.38, 0.42, 0.055))
	draw_circle(Vector2(size.x - cloud_x, size.y * 0.25), 110.0, Color(0.18, 0.22, 0.24, 0.045))
	for index in _particles.size():
		var d: Dictionary = _particles[index]
		var p: Vector2 = d.p
		var speed: float = d.s
		var x := fmod(p.x * size.x + _time * (10.0 + speed * 18.0), size.x + 20.0) - 10.0
		var vertical_speed := 52.0 if preset == "storm" else -6.0
		var y := fmod(p.y * size.y + _time * vertical_speed * speed, size.y + 20.0) - 10.0
		match preset:
			"storm": draw_line(Vector2(x, y), Vector2(x - 5, y + 13), Color(0.66, 0.77, 0.82, 0.12 + 0.12 * d.o), 1.0)
			"industrial":
				var spark_alpha := 0.8 if fmod(_time * 3.0 + index, 11.0) < 0.18 else 0.0
				draw_line(Vector2(x, y), Vector2(x + 4, y + 6), Color(0.95, 0.67, 0.24, spark_alpha), 1.5)
			"fog": draw_circle(Vector2(x, y), 18.0 * speed, Color(0.64, 0.68, 0.66, 0.035))
			_: draw_circle(Vector2(x, y), 1.2 + speed, Color(0.77, 0.68, 0.52, 0.18))
	# Lantern/firelight pulse. It is deliberately subtle over final art.
	var flicker := 0.025 + sin(_time * 8.3) * 0.009 + sin(_time * 13.7) * 0.006
	draw_circle(Vector2(size.x * 0.58, size.y * 0.47), size.x * 0.11, Color(0.95, 0.55, 0.20, maxf(0.0, flicker)))
	# Reusable radio pulse and generator vibration motifs. Residence art can
	# place its own detailed objects beneath these deliberately faint accents.
	if preset in ["industrial", "fog"]:
		var radio_center := Vector2(size.x * 0.78, size.y * 0.35)
		for ring in 3:
			var radius := fmod(_time * 18.0 + ring * 10.0, 30.0)
			draw_circle(radio_center, radius, Color(0.37, 0.75, 0.82, 0.12 * (1.0 - radius / 30.0)), false, 1.2)
		var generator_y := sin(_time * 18.0) * 1.2
		draw_rect(Rect2(size.x * 0.13, size.y * 0.72 + generator_y, 34, 18), Color(0.16, 0.15, 0.13, 0.16), false, 1.5)
