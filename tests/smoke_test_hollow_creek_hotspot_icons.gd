extends Node
## Verifies every approved Hollow Creek hotspot master/runtime pair and proves
## the running marker uses the final illustration rather than its old proxy.

const IDS := ["front_door", "kitchen_window", "living_room", "fireplace", "pantry", "upstairs_bedroom", "barn", "rear_escape", "perimeter_traps"]

func _ready() -> void:
	GameManager.new_game()
	for hotspot_id in IDS:
		var runtime_path := "res://assets/ui/repair_hotspots/hollow_creek/runtime/%s.png" % hotspot_id
		var source_path := "res://assets/ui/repair_hotspots/hollow_creek/source/%s.png" % hotspot_id
		if not ResourceLoader.exists(runtime_path):
			_fail("missing runtime icon %s" % hotspot_id)
			return
		var runtime := load(runtime_path) as Texture2D
		if runtime == null or runtime.get_width() != 256 or runtime.get_height() != 256:
			_fail("runtime icon is not 256x256: %s" % hotspot_id)
			return
		var import_config := ConfigFile.new()
		if import_config.load(ProjectSettings.globalize_path(runtime_path + ".import")) != OK:
			_fail("missing runtime import configuration: %s" % hotspot_id)
			return
		if int(import_config.get_value("params", "compress/mode", -1)) != 0 \
			or bool(import_config.get_value("params", "mipmaps/generate", true)) \
			or not bool(import_config.get_value("params", "process/fix_alpha_border", false)):
			_fail("runtime import is not lossless alpha-safe UI configuration: %s" % hotspot_id)
			return
		var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
		if source == null or source.get_width() != 1024 or source.get_height() != 1024:
			_fail("approved source is not 1024x1024: %s" % hotspot_id)
			return
		if source.get_pixel(0, 0).a > 0.05:
			_fail("approved source lacks transparent corners: %s" % hotspot_id)
			return
		var visual := HotspotVisual.new()
		visual.residence_id = "hollow_creek_farmhouse"
		visual.hotspot_id = hotspot_id
		visual.size = Vector2(76, 76)
		add_child(visual)
		await get_tree().process_frame
		if not visual.has_final_illustration():
			visual.queue_free()
			_fail("old ring/item proxy still active: %s" % hotspot_id)
			return
		visual.set_selected(true)
		visual.set_selected(false)
		visual.queue_free()
		await get_tree().process_frame
	print("SMOKE_HOLLOW_CREEK_HOTSPOT_ICONS_OK icons=9 source=1024 runtime=256 fallback=0")
	get_tree().quit()

func _fail(message: String) -> void:
	print("SMOKE_HOLLOW_CREEK_HOTSPOT_ICONS_FAIL: %s" % message)
	get_tree().quit(1)
