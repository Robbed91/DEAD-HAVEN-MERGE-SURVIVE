extends Node
## Verifies the Northgate approval set resolves to final RGBA assets and no
## hotspot falls back to the procedural pictogram renderer.

const IDS := ["sally_port", "guard_tower", "armory", "mess_hall", "cell_block_a", "control_room", "transport_bay", "warden_office"]

func _ready() -> void:
	GameManager.new_game()
	for hotspot_id in IDS:
		var runtime_path := "res://assets/ui/repair_hotspots/northgate/runtime/%s.png" % hotspot_id
		var source_path := "res://assets/ui/repair_hotspots/northgate/source/%s.png" % hotspot_id
		if not ResourceLoader.exists(runtime_path):
			_fail("missing runtime icon %s" % hotspot_id)
			return
		var runtime := load(runtime_path) as Texture2D
		if runtime == null or runtime.get_width() != 256 or runtime.get_height() != 256:
			_fail("runtime icon is not 256x256: %s" % hotspot_id)
			return
		var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
		if source == null or source.get_width() != 1024 or source.get_height() != 1024:
			_fail("source icon is not 1024x1024: %s" % hotspot_id)
			return
		if source.get_pixel(0, 0).a > 0.05:
			_fail("source icon does not have transparent canvas corners: %s" % hotspot_id)
			return
		var visual := HotspotVisual.new()
		visual.residence_id = "northgate_prison"
		visual.hotspot_id = hotspot_id
		visual.size = Vector2(76, 76)
		add_child(visual)
		await get_tree().process_frame
		if not visual.has_final_illustration():
			visual.queue_free()
			_fail("procedural fallback is still active: %s" % hotspot_id)
			return
		visual.set_selected(true)
		visual.set_selected(false)
		visual.queue_free()
		await get_tree().process_frame
	print("SMOKE_NORTHGATE_HOTSPOT_ICONS_OK icons=8 source=1024 runtime=256 fallback=0")
	get_tree().quit()

func _fail(message: String) -> void:
	print("SMOKE_NORTHGATE_HOTSPOT_ICONS_FAIL: %s" % message)
	get_tree().quit(1)
