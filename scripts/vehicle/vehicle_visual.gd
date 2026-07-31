extends Control
class_name VehicleVisual
## Final layered delivery-van presentation. VehicleManager remains the stage
## authority; this node only translates stage and event changes into artwork,
## animation, particles, and light.

const STAGE_ROOT := "res://assets/art/vehicles/delivery_van/runtime/"
const MAX_STAGE := 8

@export_range(0, MAX_STAGE) var stage: int = 0:
	set(value):
		stage = clampi(value, 0, MAX_STAGE)
		if is_node_ready():
			_show_stage(stage)

var _art_root: Control
var _previous_art: TextureRect
var _stage_art: TextureRect
var _upgrade_wash: ColorRect
var _headlight_left: Sprite2D
var _headlight_right: Sprite2D
var _radio_glow: Sprite2D
var _wheel_front: Sprite2D
var _wheel_rear: Sprite2D
var _door_light: Polygon2D
var _exhaust: CPUParticles2D
var _dust: CPUParticles2D
var _stage_tween: Tween
var _action_tween: Tween
var _drive_tween: Tween
var _motion_time := 0.0
var _engine_running := false
var _shown_stage := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_build_layers()
	resized.connect(_layout_effects)
	_show_stage(stage, false)
	call_deferred("_layout_effects")
	set_process(true)

func _build_layers() -> void:
	_art_root = Control.new()
	_art_root.name = "IllustratedVanRig"
	_art_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art_root)
	move_child(_art_root, 0)

	_previous_art = _make_art_layer("PreviousStage")
	_stage_art = _make_art_layer("CurrentStage")

	var light_texture := _make_radial_texture(96, Color(1.0, 0.73, 0.25, 0.7))
	_headlight_left = _make_effect_sprite("LeftHeadlight", light_texture)
	_headlight_right = _make_effect_sprite("RightHeadlight", light_texture)
	_radio_glow = _make_effect_sprite("RadioPulse", _make_radial_texture(112, Color(0.35, 0.72, 0.88, 0.55)))

	var wheel_texture := _make_wheel_motion_texture(84)
	_wheel_front = _make_effect_sprite("FrontWheelMotion", wheel_texture)
	_wheel_rear = _make_effect_sprite("RearWheelMotion", wheel_texture)
	_wheel_front.visible = false
	_wheel_rear.visible = false

	_door_light = Polygon2D.new()
	_door_light.name = "DoorInteriorLight"
	_door_light.polygon = PackedVector2Array([Vector2(-5, -42), Vector2(34, -27), Vector2(30, 46), Vector2(-4, 40)])
	_door_light.color = Color(1.0, 0.62, 0.2, 0.0)
	_art_root.add_child(_door_light)

	_exhaust = _make_particles("Exhaust", Color(0.52, 0.57, 0.59, 0.38), 14, 0.9)
	_exhaust.direction = Vector2.RIGHT
	_exhaust.spread = 30.0
	_exhaust.gravity = Vector2(0, -18)
	_exhaust.initial_velocity_min = 18.0
	_exhaust.initial_velocity_max = 42.0

	_dust = _make_particles("WheelDust", Color(0.52, 0.41, 0.28, 0.32), 22, 0.65)
	_dust.direction = Vector2.RIGHT
	_dust.spread = 55.0
	_dust.gravity = Vector2(0, 20)
	_dust.initial_velocity_min = 28.0
	_dust.initial_velocity_max = 68.0

	_upgrade_wash = ColorRect.new()
	_upgrade_wash.name = "UpgradeWash"
	_upgrade_wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_upgrade_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_upgrade_wash.color = Color(0.94, 0.68, 0.22, 0.0)
	add_child(_upgrade_wash)
	move_child(_upgrade_wash, 1)

func _make_art_layer(node_name: String) -> TextureRect:
	var art := TextureRect.new()
	art.name = node_name
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art_root.add_child(art)
	return art

func _make_effect_sprite(node_name: String, texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.modulate.a = 0.0
	_art_root.add_child(sprite)
	return sprite

func _make_particles(node_name: String, color: Color, amount: int, lifetime: float) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.name = node_name
	particles.one_shot = true
	particles.emitting = false
	particles.amount = amount
	particles.lifetime = lifetime
	particles.texture = _make_radial_texture(24, Color.WHITE)
	particles.color = color
	particles.scale_amount_min = 0.18
	particles.scale_amount_max = 0.48
	_art_root.add_child(particles)
	return particles

func _show_stage(value: int, animate := true) -> void:
	var path := "%sstage_%d.png" % [STAGE_ROOT, value]
	if not ResourceLoader.exists(path):
		push_warning("VehicleVisual: missing final stage artwork %s" % path)
		return
	if _stage_tween != null and _stage_tween.is_valid():
		_stage_tween.kill()
	var old_texture := _stage_art.texture
	_previous_art.texture = old_texture
	_previous_art.visible = old_texture != null
	_previous_art.modulate.a = 1.0
	_stage_art.texture = load(path)
	_stage_art.modulate.a = 1.0
	_stage_art.scale = Vector2.ONE
	_stage_art.pivot_offset = _stage_art.size * 0.5
	_engine_running = value >= 1
	_shown_stage = value
	_layout_effects()
	if not animate or not _effects_allowed() or old_texture == null:
		_previous_art.visible = false
		_sync_effect_visibility()
		return
	_stage_art.modulate.a = 0.0
	_stage_art.scale = Vector2(0.985, 0.985)
	_stage_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_stage_tween.tween_property(_previous_art, "modulate:a", 0.0, 0.28)
	_stage_tween.tween_property(_stage_art, "modulate:a", 1.0, 0.34)
	_stage_tween.tween_property(_stage_art, "scale", Vector2.ONE, 0.38)
	_stage_tween.chain().tween_callback(func(): _previous_art.visible = false)
	_sync_effect_visibility()

func play_upgrade_sequence() -> void:
	if not _effects_allowed():
		_engine_running = stage >= 1
		_sync_effect_visibility()
		return
	if _action_tween != null and _action_tween.is_valid():
		_action_tween.kill()
	_upgrade_wash.color.a = 0.0
	_action_tween = create_tween()
	_action_tween.tween_property(_upgrade_wash, "color:a", 0.24, 0.09)
	_action_tween.tween_property(_upgrade_wash, "color:a", 0.0, 0.34)
	play_door_open()
	play_engine_start()
	if stage >= 2:
		play_drive_preview()
	if stage >= 8:
		var radio_tween := create_tween().set_loops(2)
		radio_tween.tween_property(_radio_glow, "modulate:a", 0.58, 0.25)
		radio_tween.tween_property(_radio_glow, "modulate:a", 0.0, 0.42)

func play_engine_start() -> void:
	_engine_running = stage >= 1
	_sync_effect_visibility()
	if not _engine_running or not _effects_allowed():
		return
	_exhaust.restart()
	var origin_scale := _art_root.scale
	var ignition := create_tween()
	ignition.tween_property(_art_root, "scale", origin_scale * Vector2(1.0, 0.982), 0.07)
	ignition.tween_property(_art_root, "scale", origin_scale * Vector2(1.0, 1.012), 0.09)
	ignition.tween_property(_art_root, "scale", origin_scale, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func play_door_open() -> void:
	if not _effects_allowed():
		_door_light.color.a = 0.0
		return
	_door_light.scale = Vector2(0.05, 1.0)
	_door_light.color.a = 0.0
	var door_tween := create_tween()
	door_tween.tween_property(_door_light, "scale:x", 1.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	door_tween.parallel().tween_property(_door_light, "color:a", 0.22, 0.14)
	door_tween.tween_interval(0.24)
	door_tween.tween_property(_door_light, "color:a", 0.0, 0.22)

func play_drive_preview() -> void:
	if not _effects_allowed() or stage < 2:
		_wheel_front.visible = false
		_wheel_rear.visible = false
		return
	if _drive_tween != null and _drive_tween.is_valid():
		_drive_tween.kill()
	_wheel_front.visible = true
	_wheel_rear.visible = true
	_wheel_front.modulate.a = 0.42
	_wheel_rear.modulate.a = 0.34
	_dust.restart()
	var origin := _art_root.position
	_drive_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_drive_tween.tween_property(_wheel_front, "rotation", _wheel_front.rotation - TAU * 2.5, 0.72)
	_drive_tween.tween_property(_wheel_rear, "rotation", _wheel_rear.rotation - TAU * 2.5, 0.72)
	_drive_tween.tween_property(_art_root, "position:x", origin.x - 7.0, 0.34)
	_drive_tween.chain().tween_property(_art_root, "position:x", origin.x, 0.28)
	_drive_tween.chain().tween_callback(func():
		_wheel_front.visible = false
		_wheel_rear.visible = false
	)

func _process(delta: float) -> void:
	if not _effects_allowed():
		_art_root.position.y = 0.0
		return
	_motion_time += delta
	_art_root.position.y = sin(_motion_time * 8.2) * 1.15 if _engine_running else 0.0
	if _engine_running:
		var lamp_alpha := 0.25 + sin(_motion_time * 3.7) * 0.025
		_headlight_left.modulate.a = lamp_alpha
		_headlight_right.modulate.a = lamp_alpha * 0.82

func _sync_effect_visibility() -> void:
	var alpha := 0.25 if _engine_running else 0.0
	_headlight_left.modulate.a = alpha
	_headlight_right.modulate.a = alpha * 0.82
	if not _engine_running:
		_exhaust.emitting = false

func _layout_effects() -> void:
	if _art_root == null:
		return
	var side := minf(size.x, size.y)
	var origin := (size - Vector2(side, side)) * 0.5
	_headlight_left.position = origin + Vector2(side * 0.215, side * 0.56)
	_headlight_right.position = origin + Vector2(side * 0.385, side * 0.54)
	_radio_glow.position = origin + Vector2(side * 0.26, side * 0.12)
	_wheel_front.position = origin + Vector2(side * 0.59, side * 0.815)
	_wheel_rear.position = origin + Vector2(side * 0.885, side * 0.775)
	_door_light.position = origin + Vector2(side * 0.735, side * 0.565)
	_exhaust.position = origin + Vector2(side * 0.96, side * 0.66)
	_dust.position = origin + Vector2(side * 0.79, side * 0.82)
	var effect_scale := side / 512.0
	for sprite in [_headlight_left, _headlight_right, _radio_glow, _wheel_front, _wheel_rear]:
		sprite.scale = Vector2.ONE * effect_scale
	_door_light.scale = Vector2.ONE * effect_scale

func _effects_allowed() -> bool:
	return is_visible_in_tree() and GameManager.effects_enabled()

func _make_radial_texture(texture_size: int, color: Color) -> ImageTexture:
	var image := Image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)
	var center := Vector2(texture_size - 1, texture_size - 1) * 0.5
	var radius := float(texture_size) * 0.5
	for y in texture_size:
		for x in texture_size:
			var alpha := clampf(1.0 - Vector2(x, y).distance_to(center) / radius, 0.0, 1.0)
			alpha = alpha * alpha
			image.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * alpha))
	return ImageTexture.create_from_image(image)

func _make_wheel_motion_texture(texture_size: int) -> ImageTexture:
	var image := Image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)
	var center := Vector2(texture_size - 1, texture_size - 1) * 0.5
	var radius := float(texture_size) * 0.46
	for y in texture_size:
		for x in texture_size:
			var point := Vector2(x, y) - center
			var distance := point.length()
			var ring := distance > radius * 0.76 and distance < radius
			var angle := atan2(point.y, point.x)
			var spoke := distance < radius * 0.78 and absf(sin(angle * 4.0)) < 0.11
			if ring or spoke:
				image.set_pixel(x, y, Color(0.72, 0.69, 0.6, 0.58))
	return ImageTexture.create_from_image(image)
