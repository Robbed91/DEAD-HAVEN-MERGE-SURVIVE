extends Node
## Verifies the release-facing main menu uses final artwork and that its
## ambient presentation obeys the established effects accessibility gate.

var failed := false

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.settings.reduced_motion = false
	var screen: Control = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	add_child(screen)
	await get_tree().process_frame
	var background := screen.get_node("Background") as TextureRect
	var image := background.texture.get_image()
	_check(background.texture.resource_path.ends_with("main_menu_safe_haven.png"), "final menu environment is not integrated")
	_check(image.get_width() == 720 and image.get_height() == 1280, "runtime art must be 720x1280")
	_check(background.get_node_or_null("Rain") is CPUParticles2D, "bounded rain layer missing")
	_check(background.get_node_or_null("RoadMist") is CPUParticles2D, "road mist layer missing")
	_check(background.get_node_or_null("HouseGlow") is Sprite2D, "warm light layer missing")
	var title := screen.get_node("Content/TitlePlate/Titles/TitleLabel") as Label
	var subtitle := screen.get_node("Content/TitlePlate/Titles/SubtitleLabel") as Label
	_check(title.text == "DEAD HAVEN" and title.modulate.a > 0.99, "live branded title missing")
	_check(subtitle.text == "MERGE & SURVIVE", "live subtitle missing")
	for button_name in ["NewGameButton", "ContinueButton", "SettingsButton", "QuitButton"]:
		var button := screen.find_child(button_name, true, false) as Button
		_check(button != null and button.custom_minimum_size.y >= 70.0, "%s lost mobile touch target" % button_name)
	var source: GDScript = load("res://scenes/main_menu/main_menu_background.gd")
	_check(source.source_code.find("draw_") == -1 and source.source_code.find("_draw()") == -1, "procedural primitive artwork remains")
	GameManager.settings.reduced_motion = true
	EventBus.settings_changed.emit()
	await get_tree().process_frame
	_check(not background.is_processing(), "reduced motion did not stop menu animation")
	_check(not (background.get_node("Rain") as CPUParticles2D).emitting, "reduced motion did not stop rain")
	screen.queue_free()
	GameManager.settings.reduced_motion = false
	if failed:
		push_error("SMOKE_MAIN_MENU_PRESENTATION_FAIL")
		get_tree().quit(1)
	else:
		print("SMOKE_MAIN_MENU_PRESENTATION_OK final_art=1 runtime=720x1280 controls=4 ambient_layers=4 reduced_motion=pass primitives=0")
		get_tree().quit()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("SMOKE_MAIN_MENU_PRESENTATION: %s" % message)
