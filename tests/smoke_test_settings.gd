extends Node
## SmokeTestSettings
##
## Confirms GameManager.update_setting() actually reaches the audio bus and
## the *live* window theme (Phase 9: previously text_scale/high_contrast/
## colorblind_mode were baked into a Theme once at Boot and never rebuilt,
## so toggling them in Settings had no visible effect until an app
## restart - EventBus.settings_changed had zero listeners). Also confirms
## GameManager.effects_enabled() correctly folds together reduced_motion
## and the graphics_quality tier. Run directly:
##   godot4 --headless --path . tests/smoke_test_settings.tscn

func _fail(msg: String) -> void:
	print("SMOKE_SETTINGS_FAIL: %s" % msg)
	get_tree().quit(1)

func _ready() -> void:
	GameManager.new_game()
	get_window().theme = ThemeFactory.build_theme()

	GameManager.update_setting("master_volume", 0.3)
	var master_db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	if not is_equal_approx(master_db, linear_to_db(0.3)):
		_fail("master_volume should reach the Master audio bus, got %.2f dB" % master_db)
		return
	print("SMOKE_SETTINGS: master_volume reaches the audio bus OK")

	# -- text_scale / high_contrast / colorblind_mode rebuild the LIVE window theme --
	GameManager.update_setting("text_scale", 1.3)
	if get_window().theme.default_font_size <= 28:
		_fail("text_scale should rebuild the live window theme with a larger font, got %d" % get_window().theme.default_font_size)
		return

	GameManager.update_setting("high_contrast", true)
	var hc_normal: StyleBoxFlat = get_window().theme.get_stylebox("normal", "Button")
	if not hc_normal.bg_color.is_equal_approx(ThemeFactory.HC_ACCENT):
		_fail("high_contrast should rebuild the live window theme's button style, got %s" % str(hc_normal.bg_color))
		return

	GameManager.update_setting("high_contrast", false)
	GameManager.update_setting("colorblind_mode", true)
	var cb_normal: StyleBoxFlat = get_window().theme.get_stylebox("normal", "Button")
	if cb_normal.border_width_left < 3:
		_fail("colorblind_mode should rebuild the live window theme with a distinguishing button outline, got border_width_left=%d" % cb_normal.border_width_left)
		return
	print("SMOKE_SETTINGS: text_scale/high_contrast/colorblind_mode rebuild the live window theme OK")

	# -- graphics_quality + reduced_motion both gate GameManager.effects_enabled() --
	GameManager.update_setting("reduced_motion", false)
	GameManager.update_setting("graphics_quality", "standard")
	if not GameManager.effects_enabled():
		_fail("effects_enabled() should be true with reduced_motion off and graphics_quality standard")
		return

	GameManager.update_setting("graphics_quality", "low")
	if GameManager.effects_enabled():
		_fail("effects_enabled() should be false when graphics_quality is low")
		return

	GameManager.update_setting("graphics_quality", "high")
	GameManager.update_setting("reduced_motion", true)
	if GameManager.effects_enabled():
		_fail("effects_enabled() should be false when reduced_motion is on, regardless of graphics_quality")
		return
	print("SMOKE_SETTINGS: effects_enabled() correctly folds reduced_motion + graphics_quality OK")

	EventBus.show_toast.emit("test toast")
	print("SMOKE_SETTINGS_OK")
	get_tree().quit(0)
