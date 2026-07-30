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

## Set instead of instance_id to draw a definition with no live BoardItem
## behind it (e.g. the discovery banner, which may fire after the discovered
## instance has already been merged again).
@export var preview_item_id: String = "":
	set(value):
		preview_item_id = value
		queue_redraw()

## Preview-only views (info panel, drag ghost) don't respond to input or
## need live cooldown redraws.
@export var interactive: bool = true

var _press_started_at: float = -1.0
var _last_tap_at: float = -999.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	set_process(interactive)

func _process(_delta: float) -> void:
	var def := _get_def()
	if def != null and def.is_producer:
		var bi := _get_board_item()
		if bi != null and bi.is_on_cooldown():
			queue_redraw()

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
	ItemIconRenderer.draw(self, def, _get_board_item())

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
	var def := _get_def()
	if def == null:
		return null
	_press_started_at = -1.0# a drag is starting, not a tap

	var preview := ItemView.new()
	preview.custom_minimum_size = size
	preview.size = size
	preview.instance_id = instance_id
	preview.interactive = false
	preview.modulate.a = 0.85
	var wrapper := Control.new()
	wrapper.add_child(preview)
	preview.position = -size * 0.5
	set_drag_preview(wrapper)

	return {"type": "board_item", "instance_id": instance_id}
