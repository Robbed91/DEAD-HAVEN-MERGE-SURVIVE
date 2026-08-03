extends Control
class_name ChainLegendIcon
## One tappable swatch in the merge board's chain-highlight legend, letting
## the player highlight every board item in a chain at a glance. Shows the
## chain's own final producer art when one exists; the procedural swatch
## remains a defensive fallback only, for any chain without one.

signal tapped(chain_id: String)

@export var chain_id: String = ""
var is_selected: bool = false

var _final_art: TextureRect

func _ready() -> void:
	custom_minimum_size = Vector2(48, 48)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_final_art()

func set_selected(value: bool) -> void:
	is_selected = value
	queue_redraw()

func has_final_illustration() -> bool:
	return _final_art != null

func _final_icon_path() -> String:
	var producer_item_id := String(ItemDatabase.get_chain(chain_id).get("producer_item_id", ""))
	if producer_item_id.is_empty():
		return ""
	var def := ItemDatabase.get_item(producer_item_id)
	return def.icon_path if def != null else ""

func _refresh_final_art() -> void:
	var path := _final_icon_path()
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	_final_art = TextureRect.new()
	_final_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_final_art.offset_left = 2.0
	_final_art.offset_top = 2.0
	_final_art.offset_right = -2.0
	_final_art.offset_bottom = -2.0
	_final_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_final_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_final_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_final_art.texture = load(path)
	add_child(_final_art)

func _draw() -> void:
	if _final_art == null:
		ItemIconRenderer.draw_chain_swatch(self, chain_id)
	if is_selected:
		draw_rect(Rect2(Vector2.ZERO, size), Color("e8b93d"), false, 3.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		tapped.emit(chain_id)
