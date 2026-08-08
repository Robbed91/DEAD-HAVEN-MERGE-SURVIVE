extends PanelContainer
## BottomNav
##
## Persistent bottom navigation: Haven / Map / Survivors / Inventory.
## Instanced on every main screen with `active_tab` set to that screen's key
## so the current tab renders highlighted. Inventory has no screen yet, so
## its button surfaces an honest "coming later" toast instead of doing
## nothing or silently failing.

@export var active_tab: String = "haven"

@onready var _buttons: Dictionary = {
	"haven": %HavenButton,
	"world_map": %MapButton,
	"survivors": %SurvivorsButton,
	"inventory": %InventoryButton,
}
@onready var _safe_margin: MarginContainer = %SafeMargin
@onready var _row: HBoxContainer = %Row

func _ready() -> void:
	for button in _buttons.values():
		button.add_theme_font_override("font", ThemeFactory.display_font())
		button.add_theme_font_size_override("font_size", 18)
		button.theme_type_variation = "NavButton"
	get_viewport().size_changed.connect(_apply_layout)
	%HavenButton.pressed.connect(_navigate_home)
	%MapButton.pressed.connect(func(): _navigate("world_map"))
	%SurvivorsButton.pressed.connect(func(): _navigate("survivors"))
	%InventoryButton.pressed.connect(func(): EventBus.show_toast.emit("Inventory arrives in a later development phase."))
	_highlight_active()
	_apply_layout()

func _navigate(key: String) -> void:
	if key == active_tab:
		return
	SceneRouter.go_to(key)

func _navigate_home() -> void:
	if active_tab == "haven":
		return
	SceneRouter.go_to(SceneRouter.residence_scene_key(GameManager.profile.current_residence_id))

func _highlight_active() -> void:
	for key in _buttons.keys():
		var btn: Button = _buttons[key]
		btn.button_pressed = (key == active_tab)
		btn.theme_type_variation = "NavSelectedButton" if key == active_tab else "NavButton"
		btn.modulate = Color.WHITE

func _apply_layout() -> void:
	var narrow := size.x > 0.0 and size.x < 560.0
	var bottom_inset := _safe_bottom_inset()
	_safe_margin.add_theme_constant_override("margin_left", 4 if narrow else 8)
	_safe_margin.add_theme_constant_override("margin_right", 4 if narrow else 8)
	_safe_margin.add_theme_constant_override("margin_top", 4)
	_safe_margin.add_theme_constant_override("margin_bottom", 4 + bottom_inset)
	_row.add_theme_constant_override("separation", 2 if narrow else 4)
	for button in _buttons.values():
		button.add_theme_font_size_override("font_size", 15 if narrow else 18)
		button.custom_minimum_size.y = 68 if narrow else 72
	custom_minimum_size.y = (80 if narrow else 88) + bottom_inset

func _safe_bottom_inset() -> int:
	var test_value := OS.get_environment("DEAD_HAVEN_SAFE_BOTTOM")
	if not test_value.is_empty():
		return maxi(0, int(test_value))
	if not OS.has_feature("mobile"):
		return 0
	var safe := DisplayServer.get_display_safe_area()
	var window_size := DisplayServer.window_get_size()
	if window_size.y <= 0:
		return 0
	var physical_bottom := maxi(0, window_size.y - (safe.position.y + safe.size.y))
	return maxi(0, int(round(float(physical_bottom) * get_viewport_rect().size.y / float(window_size.y))))
