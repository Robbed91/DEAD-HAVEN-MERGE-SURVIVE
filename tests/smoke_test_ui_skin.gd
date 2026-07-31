extends Node
## Verifies the shared final UI skin without changing any gameplay state.

var _failed := false

func _ready() -> void:
	var theme := ThemeFactory.build_theme(1.0, false, false)
	get_window().theme = theme
	_assert(theme.has_stylebox("normal", "Button"), "normal button style missing")
	_assert(theme.has_stylebox("pressed", "Button"), "pressed button style missing")
	_assert(theme.has_stylebox("disabled", "Button"), "disabled button style missing")
	_assert(theme.has_stylebox("focus", "Button"), "focused button style missing")
	for variation in ["NavSelectedButton", "NotificationButton", "LoadingButton", "LockedButton"]:
		_assert(theme.has_stylebox("normal", variation), "%s style missing" % variation)
	_assert(theme.has_icon("checked", "CheckButton"), "final checked-toggle icon missing")
	_assert(theme.has_icon("unchecked", "CheckButton"), "final unchecked-toggle icon missing")
	_assert(theme.has_stylebox("background", "ProgressBar"), "progress background missing")
	_assert(theme.has_stylebox("fill", "ProgressBar"), "progress fill missing")

	GameManager.new_game()
	var top: Control = load("res://scenes/ui/top_resource_bar.tscn").instantiate()
	add_child(top)
	await get_tree().process_frame
	_assert(top.get_node("Margin/Row/EnergyRow/EnergyTexture").texture != null, "energy icon missing")
	_assert(top.get_node("Margin/Row/NotificationButton/BellIcon").texture != null, "notification icon missing")
	top.queue_free()

	var nav: Control = load("res://scenes/ui/bottom_nav.tscn").instantiate()
	nav.active_tab = "world_map"
	add_child(nav)
	await get_tree().process_frame
	for button_name in ["HavenButton", "MergeButton", "MapButton", "SurvivorsButton", "InventoryButton"]:
		_assert(nav.get_node("SafeMargin/Row/%s" % button_name).icon != null, "%s final icon missing" % button_name)
	_assert(nav.get_node("SafeMargin/Row/MapButton").theme_type_variation == "NavSelectedButton", "selected navigation state missing")
	nav.queue_free()

	var map: Control = load("res://scenes/world_map/world_map.tscn").instantiate()
	add_child(map)
	await get_tree().process_frame
	var farmhouse_marker: Button = map.get_node("Layout/MapArea/HollowCreekMarker")
	_assert(farmhouse_marker.text.is_empty(), "world marker still contains placeholder text")
	_assert(farmhouse_marker.get_node("MarkerIcon").texture != null, "world marker final icon missing")
	map.queue_free()

	await get_tree().process_frame
	if _failed:
		push_error("SMOKE_UI_SKIN_FAIL")
		get_tree().quit(1)
	else:
		print("SMOKE_UI_SKIN_OK states=8 navigation=5 emoji_markers=0")
		get_tree().quit()

func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("SMOKE_UI_SKIN: %s" % message)
