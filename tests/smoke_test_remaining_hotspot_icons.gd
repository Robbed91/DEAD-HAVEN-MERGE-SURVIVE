extends Node
## Verifies every post-Hollow-Creek residence hotspot resolves to final RGBA
## artwork and never reaches the procedural fallback renderer.

const SETS := {
	"redwater_service_station": {
		"folder": "redwater",
		"ids": ["fuel_pumps", "service_bay", "convenience_store", "cashier_office", "generator_room", "perimeter_fence", "drainage_tunnel", "garage_workshop"],
	},
	"greybridge_school": {
		"folder": "greybridge",
		"ids": ["main_hall", "gymnasium", "library", "cafeteria", "boiler_room", "admin_office", "playground_fence", "radio_tower"],
	},
	"saint_mercy_hospital": {
		"folder": "saint_mercy",
		"ids": ["reception_er", "pharmacy", "patient_ward", "surgical_suite", "power_room", "ambulance_bay", "records_office", "isolation_ward"],
	},
}

func _ready() -> void:
	GameManager.new_game()
	var verified := 0
	for residence_id in SETS:
		var folder: String = SETS[residence_id].folder
		for hotspot_id in SETS[residence_id].ids:
			var runtime_path := "res://assets/ui/repair_hotspots/%s/runtime/%s.png" % [folder, hotspot_id]
			var source_path := "res://assets/ui/repair_hotspots/%s/source/%s.png" % [folder, hotspot_id]
			if not ResourceLoader.exists(runtime_path):
				_fail("missing runtime icon %s/%s" % [residence_id, hotspot_id])
				return
			var runtime := load(runtime_path) as Texture2D
			if runtime == null or runtime.get_width() != 256 or runtime.get_height() != 256:
				_fail("runtime icon is not 256x256: %s/%s" % [residence_id, hotspot_id])
				return
			var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
			if source == null or source.get_width() != 1024 or source.get_height() != 1024:
				_fail("source icon is not 1024x1024: %s/%s" % [residence_id, hotspot_id])
				return
			if source.get_pixel(0, 0).a > 0.05:
				_fail("source icon canvas corner is opaque: %s/%s" % [residence_id, hotspot_id])
				return
			var visual := HotspotVisual.new()
			visual.residence_id = residence_id
			visual.hotspot_id = hotspot_id
			visual.size = Vector2(76, 76)
			add_child(visual)
			await get_tree().process_frame
			if not visual.has_final_illustration():
				visual.queue_free()
				_fail("procedural fallback is active: %s/%s" % [residence_id, hotspot_id])
				return
			visual.set_selected(true)
			visual.set_selected(false)
			visual.queue_free()
			await get_tree().process_frame
			verified += 1
	print("SMOKE_REMAINING_HOTSPOT_ICONS_OK icons=%d source=1024 runtime=256 fallback=0" % verified)
	get_tree().quit()

func _fail(message: String) -> void:
	print("SMOKE_REMAINING_HOTSPOT_ICONS_FAIL: %s" % message)
	get_tree().quit(1)
