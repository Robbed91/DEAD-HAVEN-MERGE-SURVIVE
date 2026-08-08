
extends Control
class_name SaintMercyEnvironment
## Locked, layered Saint Mercy Hospital environment. Presentation reads existing
## hotspot/defence state and never owns progression or save data.

const RESIDENCE_ID := "saint_mercy_hospital"
const DEFENCE_EVENT_ID := "saint_mercy_defence"
const BASE_TEXTURE := "res://assets/art/saint_mercy/runtime/saint_mercy_state_01_destroyed.jpg"
const OVERLAY_DIR := "res://assets/art/saint_mercy/repair_overlays"
const LAYER_DIR := "res://assets/art/saint_mercy/layers"
const HOTSPOT_IDS := [
	"reception_er", "pharmacy", "patient_ward", "surgical_suite", "power_room",
	"ambulance_bay", "records_office", "isolation_ward",
]

var _base: TextureRect
var _sky: TextureRect
var _vegetation: TextureRect
var _foreground: TextureRect
var _lighting: TextureRect
var _damage: TextureRect
var _debris: TextureRect
var _repair_layers: Dictionary = {}
var _rain: CPUParticles2D
var _dust: CPUParticles2D
var _repair_particles: CPUParticles2D
var _imogen: LayeredCharacterRig
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
	set_process(true)

func _build_layers() -> void:
	_base = _full_texture(BASE_TEXTURE)
	add_child(_base)
	_sky = _layer("sky", 0.08)
	_layer("distant_landscape", 0.05)
	_layer("background_structures", 0.04)
	_layer("main_building", 0.035)
	_damage = _layer("damage", 0.06)
	_debris = _layer("debris", 0.06)
	_layer("furniture", 0.035)
	_vegetation = _layer("vegetation", 0.07)
	_foreground = _layer("foreground", 0.13)
	for hotspot_id in HOTSPOT_IDS:
		var overlay := _full_texture("%s/%s.png" % [OVERLAY_DIR, hotspot_id])
		overlay.name = "Repair_%s" % hotspot_id
		overlay.modulate.a = 0.0
		add_child(overlay)
		_repair_layers[hotspot_id] = overlay
	_lighting = _layer("lighting", 0.0)
	_layer("weather", 0.035)

func _layer(layer_name: String, alpha: float) -> TextureRect:
	var layer := _full_texture("%s/%s.png" % [LAYER_DIR, layer_name])
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
	_drifter.display_height = 76.0
	_drifter.auto_play = "distant_wandering"
	_drifter.modulate = Color(0.48, 0.56, 0.62, 0.50)
	add_child(_drifter)
	_imogen = LayeredCharacterRig.new()
	_imogen.character_id = "imogen_shaw"
	_imogen.display_height = 148.0
	_imogen.auto_play = "treating_injury"
	add_child(_imogen)
	_refresh_actor_visibility()

func _build_particles() -> void:
	var particle_texture: Texture2D = load("res://assets/ui/hollow_creek/particle_soft.png")
	_rain = CPUParticles2D.new()
	_rain.amount = 50
	_rain.lifetime = 1.7
	_rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rain.direction = Vector2(0.12, 1.0)
	_rain.spread = 4.0
	_rain.gravity = Vector2(16, 360)
	_rain.initial_velocity_min = 220.0
	_rain.initial_velocity_max = 315.0
	_rain.scale_amount_min = 0.025
	_rain.scale_amount_max = 0.06
	_rain.color = Color(0.66, 0.76, 0.84, 0.24)
	_rain.texture = particle_texture
	add_child(_rain)
	_dust = CPUParticles2D.new()
	_dust.amount = 10
	_dust.lifetime = 3.6
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = Vector2(145, 85)
	_dust.direction = Vector2(0.1, -1.0)
	_dust.spread = 60.0
	_dust.initial_velocity_min = 2.0
	_dust.initial_velocity_max = 7.0
	_dust.color = Color(0.90, 0.69, 0.38, 0.22)
	_dust.texture = particle_texture
	add_child(_dust)
	_repair_particles = CPUParticles2D.new()
	_repair_particles.one_shot = true
	_repair_particles.amount = 24
	_repair_particles.lifetime = 0.75
	_repair_particles.direction = Vector2(0, -1)
	_repair_particles.spread = 70.0
	_repair_particles.gravity = Vector2(0, 120)
	_repair_particles.initial_velocity_min = 42.0
	_repair_particles.initial_velocity_max = 100.0
	_repair_particles.scale_amount_min = 0.04
	_repair_particles.scale_amount_max = 0.10
	_repair_particles.color = Color(1.0, 0.68, 0.26, 0.9)
	_repair_particles.texture = particle_texture
	add_child(_repair_particles)

func _layout_dynamic_content() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_rain.position = Vector2(size.x * 0.5, -16)
	_rain.emission_rect_extents = Vector2(size.x * 0.62, 15)
	_dust.position = Vector2(size.x * 0.56, size.y * 0.56)
	_imogen.position = Vector2(size.x * 0.68, size.y * 0.63)
	_drifter.position = Vector2(size.x * 0.12, size.y * 0.34)

func _process(delta: float) -> void:
	_ambient_time += delta
	if not GameManager.effects_enabled():
		return
	_sky.offset_left = sin(_ambient_time * 0.08) * 8.0
	_sky.offset_right = _sky.offset_left
	_vegetation.offset_left = sin(_ambient_time * 0.66) * 1.6
	_vegetation.offset_right = _vegetation.offset_left
	_foreground.rotation = sin(_ambient_time * 0.52) * 0.0018
	var light_target := 0.04 + float(_state_index) * 0.055
	_lighting.modulate.a = light_target + sin(_ambient_time * 6.2) * 0.014
	if _drifter.visible:
		_drifter.position.x += delta * 0.62
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
	_state_index = 5 if DefenceManager.has_survived(DEFENCE_EVENT_ID) else (4 if completed >= 8 else (3 if completed >= 5 else (2 if completed >= 3 else (1 if completed >= 1 else 0))))
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
	AudioManager.play_sfx("generator_start" if hotspot_id == "power_room" else ("medical_merge" if hotspot_id in ["pharmacy", "surgical_suite"] else "repair_whoosh"))

func _hotspot_position(hotspot_id: String) -> Vector2:
	var residence := ResidenceManager.get_residence(RESIDENCE_ID)
	if residence:
		for hotspot in residence.hotspots:
			if hotspot.id == hotspot_id:
				return Vector2(hotspot.area_position.x * size.x, hotspot.area_position.y * size.y)
	return size * 0.5

func _refresh_actor_visibility() -> void:
	if _imogen:
		_imogen.visible = GameManager.is_survivor_unlocked("imogen_shaw")
	if _drifter:
		_drifter.visible = not DefenceManager.has_survived(DEFENCE_EVENT_ID)

func _refresh_effects_setting() -> void:
	var enabled := GameManager.effects_enabled()
	_rain.emitting = enabled
	_dust.emitting = enabled and _state_index >= 3
	_refresh_actor_visibility()

func state_name() -> String:
	return ["destroyed", "cleared", "temporarily_repaired", "habitable", "defended", "fully_upgraded"][_state_index]

