extends Node

var failed := false

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.settings.reduced_motion = true
	var splash: Control = load("res://scenes/splash/splash.tscn").instantiate()
	add_child(splash)
	await get_tree().process_frame
	var background := splash.get_node("Background") as TextureRect
	_check(background.texture != null and background.texture.resource_path.ends_with("main_menu_safe_haven.png"), "final illustrated background missing")
	_check(splash.get_node("Logo/Titles/Title").text == "DEAD HAVEN", "live title missing")
	_check(splash.get_node("Logo/Titles/Subtitle").text == "MERGE & SURVIVE", "live subtitle missing")
	_check(not background.is_processing(), "reduced motion did not suspend splash ambience")
	var scene_text := FileAccess.get_file_as_string("res://scenes/splash/splash.tscn")
	_check(scene_text.find("logo_stacked_dark.svg") == -1, "broken legacy SVG remains release-facing")
	GameManager.settings.reduced_motion = false
	if failed:
		push_error("SMOKE_SPLASH_PRESENTATION_FAIL")
		get_tree().quit(1)
	else:
		print("SMOKE_SPLASH_PRESENTATION_OK final_art=1 live_title=1 legacy_svg=0 reduced_motion=pass")
		get_tree().quit()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("SMOKE_SPLASH_PRESENTATION: %s" % message)
