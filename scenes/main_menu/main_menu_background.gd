extends TextureRect
class_name MainMenuEnvironment
## Final painterly title-screen environment. The illustration remains a static,
## Android-friendly texture; restrained weather and light layers provide the
## cinemagraph treatment without affecting menu behaviour.

var _rain: CPUParticles2D
var _mist: CPUParticles2D
var _house_glow: Sprite2D
var _gate_glow: Sprite2D
var _ambient_time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_build_ambient_layers()
	resized.connect(_layout_ambient_layers)
	EventBus.settings_changed.connect(_refresh_effects_setting)
	visibility_changed.connect(_refresh_effects_setting)
	_layout_ambient_layers()
	_refresh_effects_setting()

func _build_ambient_layers() -> void:
	var particle_texture: Texture2D = load("res://assets/ui/hollow_creek/particle_soft.png")
	_house_glow = _make_glow("HouseGlow", particle_texture, Color(1.0, 0.58, 0.20, 0.15))
	_gate_glow = _make_glow("GateGlow", particle_texture, Color(1.0, 0.48, 0.14, 0.09))
	_rain = CPUParticles2D.new()
	_rain.name = "Rain"
	_rain.amount = 58
	_rain.lifetime = 1.65
	_rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rain.direction = Vector2(0.12, 1.0)
	_rain.spread = 3.5
	_rain.gravity = Vector2(18.0, 390.0)
	_rain.initial_velocity_min = 230.0
	_rain.initial_velocity_max = 330.0
	_rain.scale_amount_min = 0.018
	_rain.scale_amount_max = 0.045
	_rain.color = Color(0.67, 0.77, 0.86, 0.22)
	_rain.texture = particle_texture
	add_child(_rain)
	_mist = CPUParticles2D.new()
	_mist.name = "RoadMist"
	_mist.amount = 8
	_mist.lifetime = 6.0
	_mist.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_mist.direction = Vector2(1.0, -0.08)
	_mist.spread = 16.0
	_mist.initial_velocity_min = 4.0
	_mist.initial_velocity_max = 11.0
	_mist.scale_amount_min = 2.2
	_mist.scale_amount_max = 4.5
	_mist.color = Color(0.48, 0.59, 0.65, 0.045)
	_mist.texture = particle_texture
	add_child(_mist)

func _make_glow(node_name: String, glow_texture: Texture2D, glow_color: Color) -> Sprite2D:
	var glow := Sprite2D.new()
	glow.name = node_name
	glow.texture = glow_texture
	glow.modulate = glow_color
	glow.scale = Vector2(5.5, 5.5)
	add_child(glow)
	return glow

func _layout_ambient_layers() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_rain.position = Vector2(size.x * 0.5, -20.0)
	_rain.emission_rect_extents = Vector2(size.x * 0.64, 18.0)
	_mist.position = Vector2(size.x * 0.48, size.y * 0.77)
	_mist.emission_rect_extents = Vector2(size.x * 0.42, size.y * 0.05)
	_house_glow.position = Vector2(size.x * 0.53, size.y * 0.40)
	_gate_glow.position = Vector2(size.x * 0.48, size.y * 0.59)

func _process(delta: float) -> void:
	if not _effects_active():
		return
	_ambient_time += delta
	_house_glow.modulate.a = 0.13 + sin(_ambient_time * 3.4) * 0.025 + sin(_ambient_time * 7.1) * 0.008
	_gate_glow.modulate.a = 0.075 + sin(_ambient_time * 2.1 + 0.8) * 0.015

func _effects_active() -> bool:
	return is_inside_tree() and is_visible_in_tree() and GameManager.effects_enabled()

func _refresh_effects_setting() -> void:
	var enabled := _effects_active()
	set_process(enabled)
	if _rain:
		_rain.emitting = enabled
	if _mist:
		_mist.emitting = enabled
	if _house_glow:
		_house_glow.modulate.a = 0.13 if enabled else 0.11
	if _gate_glow:
		_gate_glow.modulate.a = 0.075 if enabled else 0.06
