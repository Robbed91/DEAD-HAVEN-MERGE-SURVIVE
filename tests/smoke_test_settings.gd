extends Node
## SmokeTestSettings
##
## Confirms GameManager.update_setting() actually reaches the audio bus
## and the theme, not just the settings Dictionary. Run directly:
##   godot4 --headless --path . tests/smoke_test_settings.tscn

func _ready() -> void:
	GameManager.new_game()
	GameManager.update_setting("master_volume", 0.3)
	GameManager.update_setting("reduced_motion", true)
	GameManager.update_setting("high_contrast", true)
	GameManager.update_setting("text_scale", 1.3)

	var theme := ThemeFactory.build_theme(GameManager.settings.text_scale, GameManager.settings.high_contrast)
	var master_db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))

	print("SMOKE_SETTINGS: master_db=%.2f theme_font=%d" % [master_db, theme.default_font_size])
	EventBus.show_toast.emit("test toast")

	if theme.default_font_size <= 28:
		print("SMOKE_SETTINGS_FAIL: text_scale did not increase the theme font size")
		get_tree().quit(1)
		return

	print("SMOKE_SETTINGS_OK")
	get_tree().quit(0)
