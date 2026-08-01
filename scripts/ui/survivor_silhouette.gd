extends Control
class_name SurvivorSilhouette
## Final survivor portrait presenter. The historical class name is retained so
## every existing scene and saved reference continues to resolve unchanged.

@export var silhouette_color: Color = Color("6b7a56") # Legacy scene compatibility.
@export var locked := false:
	set(value):
		locked = value
		_refresh_final_portrait()
@export var survivor_id := "":
	set(value):
		survivor_id = value
		_refresh_final_portrait()
@export_enum("neutral", "concerned", "angry", "afraid", "relieved", "injured", "exhausted", "determined") var expression := "neutral":
	set(value):
		expression = value
		_refresh_final_portrait()

var _portrait_view: TextureRect
var _lock_view: TextureRect
var _animation_player: AnimationPlayer
var _using_procedural_fallback := false
var _override_texture_path := ""

func _ready() -> void:
	_build_presentation()
	_refresh_final_portrait()
	play_state("idle")

func _build_presentation() -> void:
	if _portrait_view != null:
		return
	_portrait_view = TextureRect.new()
	_portrait_view.name = "FinalPortrait"
	_portrait_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_portrait_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait_view)
	_lock_view = TextureRect.new()
	_lock_view.name = "LockPlate"
	_lock_view.texture = load("res://assets/ui/merge_board/lock_plate.png")
	_lock_view.custom_minimum_size = Vector2(24, 28)
	_lock_view.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_lock_view.position -= Vector2(12, 14)
	_lock_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_lock_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_lock_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lock_view)
	_animation_player = AnimationPlayer.new()
	_animation_player.name = "AnimationPlayer"
	add_child(_animation_player)
	var library := AnimationLibrary.new()
	library.add_animation("idle", _portrait_animation(1.9, 1.012, 0.0))
	library.add_animation("speaking", _portrait_animation(0.34, 1.018, -1.3))
	library.add_animation("fear", _portrait_animation(0.26, 1.025, 1.4))
	library.add_animation("injured", _portrait_animation(1.3, 1.006, 1.6))
	_animation_player.add_animation_library("", library)

func _portrait_animation(length: float, zoom: float, angle_degrees: float) -> Animation:
	var animation := Animation.new()
	animation.length = length
	animation.loop_mode = Animation.LOOP_LINEAR
	var scale_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(scale_track, NodePath("FinalPortrait:scale"))
	animation.track_insert_key(scale_track, 0.0, Vector2.ONE)
	animation.track_insert_key(scale_track, length * 0.5, Vector2.ONE * zoom)
	animation.track_insert_key(scale_track, length, Vector2.ONE)
	var rotation_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(rotation_track, NodePath("FinalPortrait:rotation"))
	animation.track_insert_key(rotation_track, 0.0, 0.0)
	animation.track_insert_key(rotation_track, length * 0.5, deg_to_rad(angle_degrees))
	animation.track_insert_key(rotation_track, length, 0.0)
	return animation

func _refresh_final_portrait() -> void:
	if not is_inside_tree():
		return
	_build_presentation()
	var path := _resolve_portrait_path()
	_portrait_view.texture = load(path) if not path.is_empty() else null
	_using_procedural_fallback = _portrait_view.texture == null
	_portrait_view.visible = not _using_procedural_fallback
	_portrait_view.modulate = Color(0.28, 0.31, 0.33, 0.82) if locked else Color.WHITE
	_lock_view.visible = locked
	queue_redraw()

func _resolve_portrait_path() -> String:
	if not _override_texture_path.is_empty() and ResourceLoader.exists(_override_texture_path):
		return _override_texture_path
	var definition: SurvivorDefinition = CharacterDatabase.get_survivor(survivor_id)
	if definition != null:
		var registered_path := str(definition.expressions.get(expression, ""))
		if registered_path.is_empty():
			registered_path = str(definition.portraits.get(expression, ""))
		if registered_path.is_empty():
			registered_path = str(definition.expressions.get("neutral", ""))
		if registered_path.is_empty():
			registered_path = str(definition.portraits.get("neutral", ""))
		if ResourceLoader.exists(registered_path):
			return registered_path
	# Preserve compatibility for survivors whose final art predates data registration.
	var conventional_path := "res://assets/art/characters/%s/portraits/%s.png" % [survivor_id, expression]
	if ResourceLoader.exists(conventional_path):
		return conventional_path
	conventional_path = "res://assets/art/characters/%s/portraits/neutral.png" % survivor_id
	return conventional_path if ResourceLoader.exists(conventional_path) else ""

func is_using_texture_portrait() -> bool:
	return _portrait_view != null and _portrait_view.texture != null

func is_using_procedural_fallback() -> bool:
	return _using_procedural_fallback

func set_override_texture(path: String) -> void:
	_override_texture_path = path
	_refresh_final_portrait()

func _draw() -> void:
	if not _using_procedural_fallback:
		return
	var tint := Color(0.30, 0.32, 0.32, 0.86) if locked else silhouette_color
	var centre_x := size.x * 0.5
	var head_radius := minf(size.x, size.y) * 0.17
	var head_centre := Vector2(centre_x, size.y * 0.32)
	draw_circle(head_centre, head_radius, tint)
	var shoulders := PackedVector2Array([
		Vector2(centre_x, size.y * 0.49),
		Vector2(size.x * 0.16, size.y * 0.94),
		Vector2(size.x * 0.84, size.y * 0.94),
	])
	draw_colored_polygon(shoulders, tint)

func play_state(state_name: String) -> void:
	if _animation_player == null:
		return
	if not _animation_player.has_animation(state_name):
		state_name = "idle"
	_animation_player.play(state_name)
