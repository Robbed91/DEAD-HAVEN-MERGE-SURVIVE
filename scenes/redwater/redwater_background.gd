extends Control
class_name RedwaterEnvironment
## Locked, layered Redwater Service Station environment. This presentation
## reads the existing hotspot/defence state and never owns progression.

const RESIDENCE_ID := "redwater_service_station"
const DEFENCE_EVENT_ID := "redwater_defence"
const BASE_TEXTURE := "res://assets/art/redwater/runtime/redwater_state_01_destroyed.jpg"
const OVERLAY_DIR := "res://assets/art/redwater/repair_overlays"
const HOTSPOT_IDS := [
	"fuel_pumps", "service_bay", "convenience_store", "cashier_office",
	"generator_room", "perimeter_fence", "drainage_tunnel", "garage_workshop",
]

var _base: TextureRect
var _sky: TextureRect
var _distant: TextureRect
var _background_structures: TextureRect
var _main_building: TextureRect
var _damage: TextureRect
var _debris: TextureRect
var _furniture: TextureRect
var _vegetation: TextureRect
var _foreground: TextureRect
var _lighting: TextureRect
var _weather: TextureRect
var _repair_layers: Dictionary = {}
var _rain: CPUParticles2D
var _dust: CPUParticles2D
var _repair_particles: CPUParticles2D
var _lena: LayeredCharacterRig
var _drifter: LayeredCharacterRig
var _ambient_time := 0.0
var _state_index := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_build_layers()
	_build_actors()
	_build_particles()
	resized.connect(_layout_dynamic_content)
	EventBus.hotspot_state_changed.connect(_on_hotspot_state_changed)
	EventBus.survivor_unlocked.connect(func(_id): _refresh_actor_visibility())
	EventBus.defence_resolved.connect(func(_outcome): _refresh_visual_state(true))
	EventBus.settings_changed.connect(_refresh_effects_setting)
	_layout_dynamic_content()
	_refresh_visual_state(false)
	_refresh_effects_setting()
	AudioManager.stop_music()
	AudioManager.play_ambience("redwater_station")
	set_process(true)

func _exit_tree() -> void:
	AudioManager.stop_ambience()

func _build_layers() -> void:
	_base = _full_texture(BASE_TEXTURE)
	add_child(_base)
	_sky = _layer("sky", 0.10)
	_distant = _layer("distant_landscape", 0.08)
	_background_structures = _layer("background_structures", 0.06)
	_main_building = _layer("main_building", 0.04)
	_damage = _layer("damage", 0.05)
	_debris = _layer("debris", 0.05)
	_furniture = _layer("furniture", 0.04)
	_vegetation = _layer("vegetation", 0.08)
	_foreground = _layer("foreground", 0.18)
	for hotspot_id in HOTSPOT_IDS:
		var overlay := _full_texture("%s/%s.png" % [OVERLAY_DIR, hotspot_id])
		overlay.name = "Repair_%s" % hotspot_id
		overlay.modulate.a = 0.0
		add_child(overlay)
		_repair_layers[hotspot_id] = overlay
	_lighting = _layer("lighting", 0.0)
	_weather = _layer("weather", 0.04)

func _layer(layer_name: String, alpha: float) -> TextureRect:
	var layer := _full_texture("res://assets/art/redwater/layers/%s.png" % layer_name)
	layer.name = layer_name.to_pascal_case()
	layer.modulate.a = alpha
	add_child(layer)
	return layer

func _full_texture(path: String) -> TextureRect:
	var view := TextureRect.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.texture = load(path)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view

func _build_actors() -> void:
	_drifter = LayeredCharacterRig.new()
	_drifter.character_id = "drifter_hollow"
	_drifter.hollow = true
	_drifter.display_height = 82.0
	_drifter.auto_play = "distant_wandering"
	_drifter.modulate = Color(0.48, 0.56, 0.62, 0.58)
	add_child(_drifter)
	_lena = LayeredCharacterRig.new()
	_lena.character_id = "lena_ortiz"
	_lena.display_height = 160.0
	_lena.auto_play = "idle_breathing"
	add_child(_lena)
	_refresh_actor_visibility()

func _build_particles() -> void:
	var particle_texture: Texture2D = load("res://assets/ui/hollow_creek/particle_soft.png")
	_rain = CPUParticles2D.new()
	_rain.name = "Weather"
	_rain.amount = 62
	_rain.lifetime = 1.6
	_rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rain.direction = Vector2(0.14, 1.0)
	_rain.spread = 4.0
	_rain.gravity = Vector2(18, 390)
	_rain.initial_velocity_min = 240.0
	_rain.initial_velocity_max = 340.0
	_rain.scale_amount_min = 0.03
	_rain.scale_amount_max = 0.07
	_rain.color = Color(0.66, 0.76, 0.84, 0.28)
	_rain.texture = particle_texture
	add_child(_rain)
	_dust = CPUParticles2D.new()
	_dust.name = "Particles"
	_dust.amount = 14
	_dust.lifetime = 3.8
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = Vector2(130, 75)
	_dust.direction = Vector2(0.1, -1.0)
	_dust.spread = 60.0
	_dust.initial_velocity_min = 2.0
	_dust.initial_velocity_max = 8.0
	_dust.color = Color(0.96, 0.69, 0.32, 0.28)
	_dust.texture = particle_texture
	add_child(_dust)
	_repair_particles = CPUParticles2D.new()
	_repair_particles.name = "RepairParticles"
	_repair_particles.one_shot = true
	_repair_particles.amount = 26
	_repair_particles.lifetime = 0.75
	_repair_particles.direction = Vector2(0, -1)
	_repair_particles.spread = 70.0
	_repair_particles.gravity = Vector2(0, 120)
	_repair_particles.initial_velocity_min = 45.0
	_repair_particles.initial_velocity_max = 105.0
	_repair_particles.scale_amount_min = 0.04
	_repair_particles.scale_amount_max = 0.11
	_repair_particles.color = Color(1.0, 0.68, 0.26, 0.9)
	_repair_particles.texture = particle_texture
	add_child(_repair_particles)

func _layout_dynamic_content() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	if _rain:
		_rain.position = Vector2(size.x * 0.5, -16)
		_rain.emission_rect_extents = Vector2(size.x * 0.62, 15)
	if _dust:
		_dust.position = Vector2(size.x * 0.62, size.y * 0.54)
	if _lena:
		_lena.position = Vector2(size.x * 0.73, size.y * 0.65)
	if _drifter:
		_drifter.position = Vector2(size.x * 0.12, size.y * 0.29)

func _process(delta: float) -> void:
	_ambient_time += delta
	if not GameManager.effects_enabled():
		return
	if _sky:
		_sky.offset_left = sin(_ambient_time * 0.08) * 9.0
		_sky.offset_right = _sky.offset_left
	if _vegetation:
		_vegetation.offset_left = sin(_ambient_time * 0.68) * 1.8
		_vegetation.offset_right = _vegetation.offset_left
	if _foreground:
		_foreground.rotation = sin(_ambient_time * 0.55) * 0.002
	if _lighting:
		var target := 0.06 + float(_state_index) * 0.055
		_lighting.modulate.a = target + sin(_ambient_time * 6.8) * 0.018
	if _drifter:
		_drifter.position.x += delta * 0.7
		if _drifter.position.x > size.x * 0.20:
			_drifter.position.x = size.x * 0.08

func _on_hotspot_state_changed(hotspot_id: String, _new_state: int) -> void:
	if _repair_layers.has(hotspot_id):
		_refresh_visual_state(true)

func _refresh_visual_state(animated: bool) -> void:
	var completed := 0
	for hotspot_id in HOTSPOT_IDS:
		var repaired := ResidenceManager.get_hotspot_state(hotspot_id) == ResidenceHotspot.State.COMPLETED
		if repaired:
			completed += 1
		var layer: TextureRect = _repair_layers[hotspot_id]
		var alpha := 1.0 if repaired else 0.0
		if animated:
			create_tween().tween_property(layer, "modulate:a", alpha, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			layer.modulate.a = alpha
	var next_state := 0
	if DefenceManager.has_survived(DEFENCE_EVENT_ID):
		next_state = 5
	elif completed >= 8:
		next_state = 4
	elif completed >= 5:
		next_state = 3
	elif completed >= 3:
		next_state = 2
	elif completed >= 1:
		next_state = 1
	_state_index = next_state
	_damage.modulate.a = maxf(0.0, 0.07 - completed * 0.008)
	_debris.modulate.a = maxf(0.0, 0.07 - completed * 0.007)
	_refresh_actor_visibility()

func play_repair(hotspot_id: String) -> void:
	if not _repair_layers.has(hotspot_id):
		return
	var layer: TextureRect = _repair_layers[hotspot_id]
	layer.modulate = Color(1.3, 1.1, 0.78, 0.0)
	var tween := create_tween()
	tween.tween_property(layer, "modulate", Color(1.25, 1.08, 0.74, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(layer, "modulate", Color.WHITE, 0.46)
	_repair_particles.position = _hotspot_position(hotspot_id)
	_repair_particles.restart()
	AudioManager.play_sfx("redwater_repair")

func _hotspot_position(hotspot_id: String) -> Vector2:
	var residence := ResidenceManager.get_residence(RESIDENCE_ID)
	if residence:
		for hotspot in residence.hotspots:
			if hotspot.id == hotspot_id:
				return Vector2(hotspot.area_position.x * size.x, hotspot.area_position.y * size.y)
	return size * 0.5

func _refresh_actor_visibility() -> void:
	if _lena:
		_lena.visible = GameManager.is_survivor_unlocked("lena_ortiz")
	if _drifter:
		_drifter.visible = not DefenceManager.has_survived(DEFENCE_EVENT_ID)

func _refresh_effects_setting() -> void:
	var enabled := GameManager.effects_enabled()
	if _rain:
		_rain.emitting = enabled
	if _dust:
		_dust.emitting = enabled and _state_index >= 3
	_refresh_actor_visibility()

func state_name() -> String:
	return ["destroyed", "cleared", "temporarily_repaired", "habitable", "defended", "fully_upgraded"][_state_index]
