extends Control
class_name HollowCreekEnvironment
## Layered, illustrated Hollow Creek vertical slice. Gameplay state is read
## from ResidenceManager; this node only presents it.

const STATE_TEXTURES := [
	"res://assets/art/hollow_creek/environments/runtime/hollow_creek_state_01_destroyed.png",
	"res://assets/art/hollow_creek/environments/runtime/hollow_creek_state_02_secured.png",
	"res://assets/art/hollow_creek/environments/runtime/hollow_creek_state_03_habitable.png",
	"res://assets/art/hollow_creek/environments/runtime/hollow_creek_state_04_defended.png",
	"res://assets/art/hollow_creek/environments/runtime/hollow_creek_state_05_upgraded.png",
]
const BOARDING_FRAMES := "res://assets/art/hollow_creek/animation/window_boarding/window_boarding_%02d.jpg"

var _state_layers: Array[TextureRect] = []
var _current_state := -1
var _cloud_layer: TextureRect
var _foreground_layer: TextureRect
var _lighting_layer: TextureRect
var _mara: LayeredCharacterRig
var _noah: LayeredCharacterRig
var _drifter: LayeredCharacterRig
var _lantern: Sprite2D
var _smoke: CPUParticles2D
var _boarding_overlay: TextureRect
var _ambient_time := 0.0
var _mara_base := Vector2.ZERO
var _noah_base := Vector2.ZERO
var _ambient_particles: Array[CPUParticles2D] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_build_environment_layers()
	_build_ambient_actors()
	_build_particles()
	_build_boarding_overlay()
	resized.connect(_layout_dynamic_layers)
	EventBus.hotspot_state_changed.connect(_on_hotspot_state_changed)
	EventBus.survivor_unlocked.connect(func(_id): _refresh_actor_visibility())
	EventBus.settings_changed.connect(_refresh_effects_setting)
	_layout_dynamic_layers()
	_refresh_state(false)
	_refresh_effects_setting()
	AudioManager.play_music("hollow_creek_residence")
	AudioManager.play_ambience("hollow_creek_storm")
	set_process(true)

func _exit_tree() -> void:
	AudioManager.stop_ambience()
	AudioManager.stop_music()

func play_survivor_repair(hotspot_id: String) -> void:
	if _mara == null or not GameManager.effects_enabled(): return
	var residence := ResidenceManager.get_residence("hollow_creek_farmhouse")
	var target := _mara.position
	for hotspot in residence.hotspots:
		if hotspot.id == hotspot_id:
			target = size * hotspot.area_position + Vector2(-42, 22)
			break
	var origin := _mara.position
	_mara.play_state("walking")
	var tween := _mara.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_mara, "position", origin.lerp(target, 0.58), 0.32)
	tween.tween_callback(func(): _mara.play_state("sawing" if hotspot_id in ["kitchen_window", "front_door", "barn"] else "hammering"))
	tween.tween_interval(0.56)
	tween.tween_callback(func(): _mara.play_state("look_around"))
	tween.tween_interval(0.22)
	tween.tween_property(_mara, "position", origin, 0.34)
	tween.tween_callback(func(): _mara.play_state("idle_breathing"))

func _build_environment_layers() -> void:
	for path in STATE_TEXTURES:
		var layer := _full_texture(path)
		layer.modulate.a = 0.0
		add_child(layer)
		_state_layers.append(layer)

	_cloud_layer = _full_texture("res://assets/art/hollow_creek/environments/layers/sky.png")
	_cloud_layer.modulate = Color(0.75, 0.82, 0.9, 0.13)
	add_child(_cloud_layer)

	_lighting_layer = _full_texture("res://assets/art/hollow_creek/environments/layers/lighting.png")
	_lighting_layer.modulate.a = 0.35
	add_child(_lighting_layer)

	_foreground_layer = _full_texture("res://assets/art/hollow_creek/environments/layers/foreground_vegetation.png")
	_foreground_layer.modulate.a = 0.72
	add_child(_foreground_layer)

func _build_ambient_actors() -> void:
	_drifter = _character("drifter_hollow", 118.0, true, Color(0.62, 0.67, 0.7, 0.74))
	add_child(_drifter)
	_mara = _character("mara_vale", 180.0, false, Color(1.02, 1.0, 0.96, 1.0))
	add_child(_mara)
	_noah = _character("noah_vance", 184.0, false, Color(1.0, 0.98, 0.94, 1.0))
	add_child(_noah)

	_lantern = _actor("res://assets/ui/icons/icon_lantern.svg", Vector2(38, 48), Color.WHITE)
	add_child(_lantern)
	_refresh_actor_visibility()

func _build_particles() -> void:
	var particle_texture: Texture2D = load("res://assets/ui/hollow_creek/particle_soft.png")

	var rain := CPUParticles2D.new()
	rain.name = "WeatherRain"
	rain.amount = 90
	rain.lifetime = 1.8
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(420, 18)
	rain.direction = Vector2(0.18, 1.0)
	rain.spread = 4.0
	rain.gravity = Vector2(20, 420)
	rain.initial_velocity_min = 270.0
	rain.initial_velocity_max = 390.0
	rain.scale_amount_min = 0.035
	rain.scale_amount_max = 0.08
	rain.color = Color(0.72, 0.8, 0.86, 0.32)
	rain.texture = particle_texture
	add_child(rain)
	_ambient_particles.append(rain)

	var dust := CPUParticles2D.new()
	dust.name = "DustMotes"
	dust.amount = 18
	dust.lifetime = 4.5
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(150, 90)
	dust.direction = Vector2(0.2, -1.0)
	dust.spread = 55.0
	dust.gravity = Vector2(2, -4)
	dust.initial_velocity_min = 3.0
	dust.initial_velocity_max = 10.0
	dust.scale_amount_min = 0.025
	dust.scale_amount_max = 0.075
	dust.color = Color(0.94, 0.74, 0.4, 0.32)
	dust.texture = particle_texture
	add_child(dust)
	_ambient_particles.append(dust)

	_smoke = CPUParticles2D.new()
	_smoke.name = "ChimneySmoke"
	_smoke.amount = 12
	_smoke.lifetime = 5.0
	_smoke.direction = Vector2(0.26, -1.0)
	_smoke.spread = 18.0
	_smoke.gravity = Vector2(7, -6)
	_smoke.initial_velocity_min = 9.0
	_smoke.initial_velocity_max = 18.0
	_smoke.scale_amount_min = 0.12
	_smoke.scale_amount_max = 0.32
	_smoke.color = Color(0.38, 0.42, 0.45, 0.28)
	_smoke.texture = particle_texture
	add_child(_smoke)

func _build_boarding_overlay() -> void:
	_boarding_overlay = TextureRect.new()
	_boarding_overlay.name = "WindowBoardingRepair"
	_boarding_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boarding_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_boarding_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_boarding_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boarding_overlay.visible = false
	add_child(_boarding_overlay)

func _full_texture(path: String) -> TextureRect:
	var view := TextureRect.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.offset_left = 0.0
	view.offset_top = 0.0
	view.offset_right = 0.0
	view.offset_bottom = 0.0
	view.texture = load(path)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view

func _actor(path: String, actor_size: Vector2, tint: Color) -> Sprite2D:
	var actor := Sprite2D.new()
	var actor_texture: Texture2D = load(path)
	actor.texture = actor_texture
	actor.centered = true
	actor.scale = Vector2(actor_size.x / actor_texture.get_width(), actor_size.y / actor_texture.get_height())
	actor.modulate = tint
	return actor

func _character(id: String, actor_height: float, is_hollow: bool, tint: Color) -> LayeredCharacterRig:
	var actor := LayeredCharacterRig.new()
	actor.character_id = id
	actor.hollow = is_hollow
	actor.display_height = actor_height
	actor.auto_play = "idle_sway" if is_hollow else "idle_breathing"
	actor.modulate = tint
	return actor

func _layout_dynamic_layers() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	if _cloud_layer:
		_cloud_layer.offset_left = -12.0
		_cloud_layer.offset_right = 12.0
	if _foreground_layer:
		_foreground_layer.offset_left = -6.0
		_foreground_layer.offset_right = 6.0
	if _mara:
		_mara_base = Vector2(size.x * 0.72, size.y * 0.60)
		_mara.position = _mara_base
	if _noah:
		_noah_base = Vector2(size.x * 0.58, size.y * 0.60)
		_noah.position = _noah_base
	if _drifter:
		_drifter.position = Vector2(size.x * 0.13, size.y * 0.49)
	if _lantern:
		_lantern.position = Vector2(size.x * 0.57, size.y * 0.47)
	var rain := get_node_or_null("WeatherRain") as CPUParticles2D
	if rain:
		rain.position = Vector2(size.x * 0.5, -20)
		rain.emission_rect_extents = Vector2(size.x * 0.65, 18)
	var dust := get_node_or_null("DustMotes") as CPUParticles2D
	if dust:
		dust.position = Vector2(size.x * 0.52, size.y * 0.58)
	if _smoke:
		_smoke.position = Vector2(size.x * 0.70, size.y * 0.22)

func _process(delta: float) -> void:
	_ambient_time += delta
	if not GameManager.effects_enabled():
		if _lighting_layer:
			_lighting_layer.modulate.a = 0.33
		return
	if _cloud_layer:
		_cloud_layer.offset_left = -12.0 + sin(_ambient_time * 0.07) * 10.0
		_cloud_layer.offset_right = 12.0 + sin(_ambient_time * 0.07) * 10.0
	if _foreground_layer:
		_foreground_layer.offset_left = -6.0 + sin(_ambient_time * 0.85) * 2.5
		_foreground_layer.offset_right = 6.0 + sin(_ambient_time * 0.85) * 2.5
		_foreground_layer.rotation = sin(_ambient_time * 0.62) * 0.0025
	if _lighting_layer:
		_lighting_layer.modulate.a = 0.31 + sin(_ambient_time * 7.1) * 0.025 + sin(_ambient_time * 2.3) * 0.018
	if _lantern:
		_lantern.rotation = sin(_ambient_time * 1.3) * 0.035
		_lantern.modulate.a = 0.88 + sin(_ambient_time * 8.0) * 0.08
	if _mara:
		_mara.position = _mara_base
	if _noah:
		_noah.position = _noah_base
	if _drifter:
		_drifter.position.x += delta * 1.2
		_drifter.position.y += sin(_ambient_time * 2.0) * delta * 1.0
		if _drifter.position.x > size.x * 0.19:
			_drifter.position.x = size.x * 0.06

func _on_hotspot_state_changed(_hotspot_id: String, _new_state: int) -> void:
	_refresh_state(true)
	_refresh_actor_visibility()

func _refresh_actor_visibility() -> void:
	if _noah:
		_noah.visible = GameManager.is_survivor_unlocked("noah_vance")
	if _smoke:
		_smoke.emitting = GameManager.effects_enabled() and ResidenceManager.get_hotspot_state("fireplace") == ResidenceHotspot.State.COMPLETED

func _refresh_effects_setting() -> void:
	for particles in _ambient_particles:
		particles.emitting = GameManager.effects_enabled()
	_refresh_actor_visibility()

func _refresh_state(animated: bool) -> void:
	var completed := 0
	var residence := ResidenceManager.get_residence("hollow_creek_farmhouse")
	if residence != null:
		for hotspot in residence.hotspots:
			if ResidenceManager.get_hotspot_state(hotspot.id) == ResidenceHotspot.State.COMPLETED:
				completed += 1
	var state := 0
	if completed >= 8:
		state = 4
	elif completed >= 5:
		state = 3
	elif completed >= 3:
		state = 2
	elif completed >= 1:
		state = 1
	if state == _current_state:
		return
	var previous := _current_state
	_current_state = state
	if not animated or previous < 0:
		for index in _state_layers.size():
			_state_layers[index].modulate.a = 1.0 if index == state else 0.0
		return
	_state_layers[state].modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_state_layers[state], "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_state_layers[previous], "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func play_window_boarding() -> void:
	if _boarding_overlay.visible:
		return
	_boarding_overlay.visible = true
	_boarding_overlay.modulate.a = 0.0
	var enter := create_tween()
	enter.tween_property(_boarding_overlay, "modulate:a", 1.0, 0.16)
	await enter.finished
	for index in 10:
		_boarding_overlay.texture = load(BOARDING_FRAMES % index)
		if index == 3 or index == 5 or index == 7:
			AudioManager.play_sfx("window_hammer")
		await get_tree().create_timer(0.13).timeout
	var exit := create_tween()
	exit.tween_property(_boarding_overlay, "modulate:a", 0.0, 0.2)
	await exit.finished
	_boarding_overlay.visible = false
