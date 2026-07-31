extends CanvasLayer
class_name DiscoveryBanner
## Slides in briefly whenever an item is discovered for the first time
## (BoardState.discovered_item_ids). Purely presentational - MergeBoard
## calls show_item(), nothing here mutates game state.

@onready var _panel: PanelContainer = %Panel
@onready var _icon: ItemView = %Icon
@onready var _label: Label = %Label

var _tween: Tween

func _ready() -> void:
	layer = 93
	_panel.theme = get_window().theme
	_panel.modulate.a = 0.0
	_panel.add_theme_stylebox_override("panel", ThemeFactory.parchment_style())
	_label.add_theme_font_override("font", ThemeFactory.display_font())
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color("241f1a"))

func show_item(item_id: String) -> void:
	var def := ItemDatabase.get_item(item_id)
	if def == null:
		return
	_icon.preview_item_id = item_id
	_label.text = "New Discovery!\n%s" % def.display_name

	if _tween:
		_tween.kill()
	var reduced: bool = GameManager.settings.get("reduced_motion", false)
	var fade := 0.08 if reduced else 0.3
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, fade)
	_tween.tween_interval(1.8)
	_tween.tween_property(_panel, "modulate:a", 0.0, fade)
