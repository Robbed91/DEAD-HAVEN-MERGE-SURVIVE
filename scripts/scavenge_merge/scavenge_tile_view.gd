extends Control
class_name ScavengeTileView
## Minimal draggable tile for the scavenging merge challenge - a stripped
## down sibling of scripts/merge/item_view.gd without any of the producer/
## cooldown/lock/cobweb presentation that item doesn't need here (see
## scavenge_merge_state.gd for why this is a separate throwaway system
## rather than reusing BoardState/ItemView directly).

signal tapped(grid_pos: Vector2i)

@export var grid_pos: Vector2i
@export var item_id: String = "":
	set(value):
		item_id = value
		_refresh()

var _art: TextureRect
var _level_badge: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh()

func _refresh() -> void:
	if not is_inside_tree():
		return
	var def := ItemDatabase.get_item(item_id)
	if def == null:
		return
	if _art == null:
		_art = TextureRect.new()
		_art.set_anchors_preset(Control.PRESET_FULL_RECT)
		_art.offset_left = 3.0
		_art.offset_top = 3.0
		_art.offset_right = -3.0
		_art.offset_bottom = -3.0
		_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_art)
	if ResourceLoader.exists(def.icon_path):
		_art.texture = load(def.icon_path)
	if _level_badge == null:
		_level_badge = Label.new()
		_level_badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		_level_badge.offset_left = -22.0
		_level_badge.offset_top = -22.0
		_level_badge.offset_right = -2.0
		_level_badge.offset_bottom = -2.0
		_level_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_level_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_level_badge.add_theme_font_size_override("font_size", 13)
		_level_badge.add_theme_color_override("font_color", Color("e8dcc5"))
		add_child(_level_badge)
	_level_badge.text = str(def.level)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not get_viewport().gui_is_dragging():
			tapped.emit(grid_pos)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_id.is_empty():
		return null
	var preview := ScavengeTileView.new()
	preview.custom_minimum_size = size
	preview.size = size
	preview.item_id = item_id
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.modulate.a = 0.9
	preview.pivot_offset = size * 0.5
	preview.scale = Vector2(1.1, 1.1)
	var wrapper := Control.new()
	wrapper.custom_minimum_size = size * 1.15
	wrapper.add_child(preview)
	preview.position = -size * 0.5
	set_drag_preview(wrapper)
	modulate.a = 0.4
	return {"type": "scavenge_tile", "from_pos": grid_pos}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0
