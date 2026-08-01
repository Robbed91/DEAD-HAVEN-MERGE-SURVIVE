extends Node
## Verifies the final map marker library and visual states without changing
## any navigation destination, story condition, or save field.

const MISSION_IDS := [
	"abandoned_grocery_store", "petrol_station", "farm_shed", "roadside_wreck",
	"medical_clinic", "police_checkpoint", "electronics_workshop",
	"clothing_outlet", "warehouse_depot", "radio_relay_station",
]
const FLAGS := ["redwater_unlocked", "greybridge_unlocked", "saint_mercy_unlocked", "northgate_unlocked"]
var failed := false

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(1.0, false, false)
	GameManager.new_game()
	GameManager.settings.reduced_motion = true
	for id in MISSION_IDS:
		_check_asset(id)

	var locked_map: Control = load("res://scenes/world_map/world_map.tscn").instantiate()
	add_child(locked_map)
	await get_tree().process_frame
	var redwater: Button = locked_map.get_node("Layout/MapArea/RedwaterMarker")
	_check(redwater.get_meta("map_locked", false), "Redwater locked state missing")
	_check(redwater.get_node_or_null("LockBadge") != null, "separate lock badge missing")
	var locked_icon := redwater.get_node("MarkerIcon") as TextureRect
	_check(locked_icon.texture != null and locked_icon.texture.resource_path.ends_with("icon_fuel_station.png"), "locked state replaced the residence identity")
	locked_map.queue_free()
	await get_tree().process_frame

	for flag in FLAGS:
		GameManager.profile.story_flags[flag] = true
	VehicleManager.discovered_vehicle_ids["delivery_van"] = true
	var open_map: Control = load("res://scenes/world_map/world_map.tscn").instantiate()
	add_child(open_map)
	await get_tree().process_frame
	await get_tree().process_frame
	var unique_paths := {}
	for id in MISSION_IDS:
		var marker := open_map.get_node_or_null("Layout/MapArea/Scavenge_%s" % id) as Button
		_check(marker != null, "%s map marker missing" % id)
		if marker != null:
			var icon := marker.get_node("MarkerIcon") as TextureRect
			_check(icon.texture != null, "%s marker texture missing" % id)
			if icon.texture != null:
				unique_paths[icon.texture.resource_path] = true
	_check(unique_paths.size() == MISSION_IDS.size(), "scavenging markers are not all visually unique")
	var background = open_map.get_node("Layout/MapArea/Background")
	_check(background.unlocked_segments == 4, "route does not reflect four existing unlock flags")
	_check(open_map.get_node_or_null("Layout/MapArea/DeliveryVanMarker") != null, "discovered vehicle marker missing")
	open_map.queue_free()
	await get_tree().process_frame

	if failed:
		push_error("SMOKE_WORLD_MAP_PRESENTATION_FAIL")
		get_tree().quit(1)
	else:
		print("SMOKE_WORLD_MAP_PRESENTATION_OK unique_scavenge=10 locked_identity=1 routes=4 vehicle=1")
		get_tree().quit()

func _check_asset(id: String) -> void:
	for tier in ["source", "runtime"]:
		var path := "res://assets/ui/world_map/markers/%s/%s.png" % [tier, id]
		var texture := load(path) as Texture2D
		var image: Image = texture.get_image() if texture != null else null
		_check(image != null and not image.is_empty(), "%s %s asset missing" % [id, tier])
		if image == null or image.is_empty():
			continue
		var expected := 1024 if tier == "source" else 256
		_check(image.get_width() == expected and image.get_height() == expected, "%s %s dimensions wrong" % [id, tier])
		_check(image.get_pixel(0, 0).a < 0.05, "%s %s background is not transparent" % [id, tier])

func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("SMOKE_WORLD_MAP_PRESENTATION: %s" % message)
