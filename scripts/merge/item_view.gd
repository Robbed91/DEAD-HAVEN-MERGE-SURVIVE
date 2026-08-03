extends Control
class_name ItemView
## Interactive visual for a single BoardItem, used on board cells, in the
## storage panel, and (in preview mode) info/detail panels. Draws itself via
## ItemIconRenderer and turns raw input into tap / double-tap / long-press /
## drag gestures - callers connect to the signals rather than polling.

signal tapped(instance_id: String)
signal double_tapped(instance_id: String)
signal long_pressed(instance_id: String)

const LONG_PRESS_SECONDS := 0.5
const DOUBLE_TAP_WINDOW_SECONDS := 0.35

@export var instance_id: String = "":
	set(value):
		instance_id = value
		queue_redraw()
		if is_inside_tree():
			call_deferred("_refresh_final_art")

## Set instead of instance_id to draw a definition with no live BoardItem
## behind it (e.g. the discovery banner, which may fire after the discovered
## instance has already been merged again).
@export var preview_item_id: String = "":
	set(value):
		preview_item_id = value
		queue_redraw()
		if is_inside_tree():
			call_deferred("_refresh_final_art")

## Preview-only views (info panel, drag ghost) don't respond to input or
## need live cooldown redraws.
@export var interactive: bool = true
@export var show_level_badge: bool = true

var _press_started_at: float = -1.0
var _last_tap_at: float = -999.0
var _final_art: TextureRect
var _level_badge: Label
var _selection_frame: TextureRect
var _lock_plate: TextureRect
var _cobweb: TextureRect
var _selected_visual := false
var _producer_visual_state := ""
var _producer_state_serial := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	set_process(interactive)
	_refresh_final_art()
	_refresh_state_overlays()
	resized.connect(_refresh_state_overlays)
	call_deferred("_refresh_state_overlays")

func _process(_delta: float) -> void:
	var def := _get_def()
	if def != null and def.is_producer:
		var bi := _get_board_item()
		if bi != null and bi.is_on_cooldown():
			queue_redraw()
			_refresh_final_texture(def, bi)
	if GameManager.effects_enabled() and is_visible_in_tree():
		var t := Time.get_ticks_msec() * 0.001
		if _cobweb != null:
			_cobweb.rotation = sin(t * 1.6) * 0.012
		if _final_art != null and _get_board_item() != null and _get_board_item().is_in_bubble:
			_final_art.position.y = 3.0 + sin(t * 2.2) * 1.6

func play_cobweb_removal() -> void:
	if _cobweb == null: return
	if not GameManager.effects_enabled():
		_cobweb.visible = false
		return
	var tween := _cobweb.create_tween().set_parallel(true)
	tween.tween_property(_cobweb, "scale", Vector2(1.35, 0.55), 0.18)
	tween.tween_property(_cobweb, "rotation", 0.34, 0.18)
	tween.tween_property(_cobweb, "modulate:a", 0.0, 0.22)

func play_bubble_pop() -> void:
	if not GameManager.effects_enabled(): return
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.18, 1.18), 0.09)
	tween.tween_property(self, "scale", Vector2(0.93, 0.93), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)

func set_selected_visual(selected: bool) -> void:
	_selected_visual = selected
	_refresh_state_overlays()
	var def := _get_def()
	if def != null:
		_refresh_final_texture(def, _get_board_item())

## Presentation-only producer state override. It does not mutate charges,
## cooldowns, definitions, or any board data.
func play_producer_visual_state(state: String, seconds: float = 0.34) -> void:
	_producer_state_serial += 1
	var serial := _producer_state_serial
	_producer_visual_state = state
	var def := _get_def()
	if def != null:
		_refresh_final_texture(def, _get_board_item())
	if seconds <= 0.0:
		return
	await get_tree().create_timer(seconds).timeout
	if is_instance_valid(self) and serial == _producer_state_serial:
		_producer_visual_state = ""
		def = _get_def()
		if def != null:
			_refresh_final_texture(def, _get_board_item())

## Public accessor - the definition currently being drawn (instance_id or
## preview_item_id, whichever is set), or null if neither resolves.
func get_def() -> ItemDefinition:
	return _get_def()

func _get_board_item() -> BoardItem:
	return BoardState.items.get(instance_id)

func _get_def() -> ItemDefinition:
	if not preview_item_id.is_empty():
		return ItemDatabase.get_item(preview_item_id)
	if instance_id.is_empty():
		return null
	var bi: BoardItem = BoardState.items.get(instance_id)
	if bi == null:
		return null
	return ItemDatabase.get_item(bi.item_id)

func _draw() -> void:
	var def := _get_def()
	if def == null:
		return
	if _uses_final_art(def):
		return
	ItemIconRenderer.draw(self, def, _get_board_item())

func _uses_final_art(def: ItemDefinition) -> bool:
	return not def.icon_path.is_empty() and ResourceLoader.exists(def.icon_path)

func _refresh_final_art() -> void:
	var def := _get_def()
	if def == null or not _uses_final_art(def):
		if _final_art != null:
			_final_art.queue_free()
			_final_art = null
		if _level_badge != null:
			_level_badge.queue_free()
			_level_badge = null
		queue_redraw()
		return
	if _final_art == null:
		_final_art = TextureRect.new()
		_final_art.set_anchors_preset(Control.PRESET_FULL_RECT)
		_final_art.offset_left = 3.0
		_final_art.offset_top = 3.0
		_final_art.offset_right = -3.0
		_final_art.offset_bottom = -3.0
		_final_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_final_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_final_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_final_art)
	if show_level_badge and not def.is_producer and _level_badge == null:
		_level_badge = Label.new()
		_level_badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		_level_badge.offset_left = -24.0
		_level_badge.offset_top = -24.0
		_level_badge.offset_right = -2.0
		_level_badge.offset_bottom = -2.0
		_level_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_level_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_level_badge.add_theme_font_override("font", ThemeFactory.display_font())
		_level_badge.add_theme_font_size_override("font_size", 14)
		_level_badge.add_theme_color_override("font_color", Color("e8dcc5"))
		add_child(_level_badge)
	if _level_badge != null:
		_level_badge.visible = show_level_badge
		_level_badge.text = str(def.level)
	_refresh_final_texture(def, _get_board_item())
	_refresh_state_overlays()
	queue_redraw()

func _refresh_final_texture(def: ItemDefinition, board_item: BoardItem) -> void:
	if _final_art == null:
		return
	var path := def.icon_path
	if def.is_producer and def.chain_id == "construction":
		if not _producer_visual_state.is_empty():
			path = "res://assets/items/construction/producer_%s.png" % _producer_visual_state
		elif board_item != null and board_item.charge_count == 0:
			path = "res://assets/items/construction/producer_empty.png"
		elif board_item != null and board_item.is_on_cooldown():
			path = "res://assets/items/construction/producer_recharge.png"
		elif board_item != null and def.producer_charges > 0 and board_item.charge_count <= maxi(1, int(ceil(def.producer_charges * 0.25))):
			path = "res://assets/items/construction/producer_low_charge.png"
		elif _selected_visual:
			path = "res://assets/items/construction/producer_selected.png"
	_final_art.texture = load(path)
	var tint := Color.WHITE
	if board_item != null and board_item.is_locked:
		tint = Color(0.58, 0.58, 0.58, 0.9)
	elif def.is_producer and def.chain_id != "construction" and board_item != null:
		if board_item.charge_count == 0:
			tint = Color(0.46, 0.46, 0.46, 0.88)
		elif board_item.is_on_cooldown():
			tint = Color(0.68, 0.78, 0.86, 0.9)
		elif _selected_visual or _producer_visual_state == "active":
			tint = Color(1.14, 1.08, 0.82, 1.0)
	_final_art.modulate = tint

func _refresh_state_overlays() -> void:
	var board_item := _get_board_item()
	_selection_frame = _ensure_overlay(_selection_frame, "res://assets/ui/merge_board/selection_frame.png", Rect2(Vector2.ZERO, size)) if _selected_visual else _free_overlay(_selection_frame)
	_lock_plate = _ensure_overlay(_lock_plate, "res://assets/ui/merge_board/lock_plate.png", Rect2(size.x - 43.0, 1.0, 42.0, 42.0)) if board_item != null and board_item.is_locked else _free_overlay(_lock_plate)
	_cobweb = _ensure_overlay(_cobweb, "res://assets/ui/merge_board/cobweb.png", Rect2(0.0, 0.0, size.x * 0.82, size.y * 0.82)) if board_item != null and board_item.has_cobweb else _free_overlay(_cobweb)

func _ensure_overlay(existing: TextureRect, path: String, rect: Rect2) -> TextureRect:
	var overlay := existing
	if overlay == null:
		overlay = TextureRect.new()
		overlay.name = path.get_file().get_basename().to_pascal_case()
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(overlay)
	overlay.texture = load(path)
	overlay.position = rect.position
	overlay.size = rect.size
	overlay.move_to_front()
	return overlay

func _free_overlay(overlay: TextureRect) -> TextureRect:
	if overlay != null:
		overlay.queue_free()
	return null

func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_started_at = Time.get_ticks_msec() / 1000.0
		else:
			if get_viewport().gui_is_dragging():
				return
			if _press_started_at < 0.0:
				return
			var held: float = Time.get_ticks_msec() / 1000.0 - _press_started_at
			_press_started_at = -1.0
			var now: float = Time.get_ticks_msec() / 1000.0
			if held >= LONG_PRESS_SECONDS:
				long_pressed.emit(instance_id)
			elif now - _last_tap_at <= DOUBLE_TAP_WINDOW_SECONDS:
				_last_tap_at = -999.0
				double_tapped.emit(instance_id)
			else:
				_last_tap_at = now
				tapped.emit(instance_id)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not interactive or instance_id.is_empty():
		return null
	if BoardState.is_item_blocked(instance_id):
		return null
	var def := _get_def()
	if def == null:
		return null
	_press_started_at = -1.0# a drag is starting, not a tap

	var preview := ItemView.new()
	preview.custom_minimum_size = size
	preview.size = size
	preview.instance_id = instance_id
	preview.interactive = false
	preview.modulate.a = 0.96
	preview.pivot_offset = size * 0.5
	preview.scale = Vector2(1.12, 1.12)
	var wrapper := Control.new()
	wrapper.custom_minimum_size = size * 1.18
	wrapper.add_child(preview)
	preview.position = -size * 0.5
	set_drag_preview(wrapper)
	modulate.a = 0.42
	AudioManager.play_sfx("item_lift")

	return {"type": "board_item", "instance_id": instance_id}

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		_refresh_state_overlays()
	elif what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0
