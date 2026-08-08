extends Control
## Final presentation controller for the illustrated regional map. Existing
## story flags, scene destinations and scavenging availability remain the
## sole source of gameplay truth.

const SCAVENGING_MARKER_POSITIONS := {
	"abandoned_grocery_store": Vector2(0.16, 0.24),
	"petrol_station": Vector2(0.82, 0.20),
	"farm_shed": Vector2(0.78, 0.42),
	"roadside_wreck": Vector2(0.20, 0.62),
	"medical_clinic": Vector2(0.75, 0.72),
	"police_checkpoint": Vector2(0.30, 0.30),
	"electronics_workshop": Vector2(0.65, 0.28),
	"clothing_outlet": Vector2(0.12, 0.50),
	"warehouse_depot": Vector2(0.88, 0.58),
	"radio_relay_station": Vector2(0.35, 0.82),
}
const RESIDENCE_FLAGS := [
	"redwater_unlocked",
	"greybridge_unlocked",
	"saint_mercy_unlocked",
	"northgate_unlocked",
]
const MARKER_ROOT := "res://assets/ui/world_map/markers/runtime/"
const FINAL_ICON_ROOT := "res://assets/ui/icons/final/icon_"

@onready var route_background: Control = %Background

func _ready() -> void:
	_configure_marker(%HollowCreekMarker, "farmhouse", false, "Hollow Creek Farmhouse")
	%HollowCreekMarker.pressed.connect(func(): SceneRouter.go_to("haven"))
	_setup_residence_marker(%RedwaterMarker, "fuel_station", "Redwater Service Station", "redwater_unlocked", "redwater")
	_setup_residence_marker(%GreybridgeMarker, "school", "Greybridge School", "greybridge_unlocked", "greybridge")
	_setup_residence_marker(%SaintMercyMarker, "hospital", "Saint Mercy Hospital", "saint_mercy_unlocked", "saint_mercy")
	_setup_residence_marker(%NorthgateMarker, "prison", "Northgate Prison", "northgate_unlocked", "northgate")
	var route_count := _unlocked_residence_count()
	route_background.set_unlocked_segments(route_count, GameManager.effects_enabled())
	_pulse_marker(%HollowCreekMarker)
	_build_scavenging_markers()
	_build_vehicle_marker(route_count)

func _setup_residence_marker(marker: Button, icon_name: String, display_name: String, flag: String, destination: String) -> void:
	var unlocked: bool = bool(GameManager.get_story_flag(flag, false))
	_configure_marker(marker, icon_name, not unlocked, display_name)
	if unlocked:
		marker.pressed.connect(func(): SceneRouter.go_to(destination))
		_play_unlock_reveal(marker)
	else:
		marker.pressed.connect(func(): EventBus.show_toast.emit("Locked - reach this residence by progressing the campaign."))

func _unlocked_residence_count() -> int:
	var count := 0
	for flag in RESIDENCE_FLAGS:
		if not GameManager.get_story_flag(flag, false):
			break
		count += 1
	return count

func _build_vehicle_marker(route_count: int) -> void:
	if not VehicleManager.is_discovered("delivery_van"):
		return
	var marker := Button.new()
	marker.name = "DeliveryVanMarker"
	_configure_marker(marker, "vehicle", false, "Old Delivery Van")
	marker.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	marker.size = Vector2(66.0, 66.0)
	marker.pressed.connect(func(): SceneRouter.go_to("vehicle"))
	%MapArea.add_child(marker)
	await get_tree().process_frame
	var map_size: Vector2 = %MapArea.size
	var segment: int = clampi(route_count - 1, 0, 3)
	var destination: Vector2 = route_background.call("sample_route_segment", segment, 0.68, map_size) + Vector2(24.0, 2.0) - marker.size * 0.5
	marker.position = destination
	if GameManager.effects_enabled() and is_visible_in_tree():
		var origin: Vector2 = route_background.call("sample_route_segment", segment, 0.12, map_size) + Vector2(24.0, 2.0) - marker.size * 0.5
		marker.position = origin
		marker.modulate.a = 0.0
		var route_tween := marker.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		route_tween.tween_property(marker, "position", destination, 0.82)
		route_tween.tween_property(marker, "modulate:a", 1.0, 0.34)

func _build_scavenging_markers() -> void:
	var layer: Control = %MapArea
	for mission_id in SCAVENGING_MARKER_POSITIONS:
		var mission := ScavengingManager.get_mission(mission_id)
		if mission == null or not ScavengingManager.is_available(mission_id):
			continue
		var position_ratio: Vector2 = SCAVENGING_MARKER_POSITIONS[mission_id]
		var marker := Button.new()
		marker.name = "Scavenge_%s" % mission_id
		_configure_marker(marker, "%s%s.png" % [MARKER_ROOT, mission_id], false, "%s - scavenge" % mission.location_name)
		marker.set_anchors_preset(Control.PRESET_TOP_LEFT)
		marker.anchor_left = position_ratio.x
		marker.anchor_right = position_ratio.x
		marker.anchor_top = position_ratio.y
		marker.anchor_bottom = position_ratio.y
		marker.offset_left = -34.0
		marker.offset_right = 34.0
		marker.offset_top = -34.0
		marker.offset_bottom = 34.0
		marker.pressed.connect(func(): SceneRouter.go_to("scavenging", {"mission_id": mission_id}))
		layer.add_child(marker)

func _configure_marker(marker: Button, icon_name_or_path: String, locked: bool = false, label: String = "") -> void:
	marker.text = ""
	marker.icon = null
	marker.tooltip_text = label
	marker.theme_type_variation = "LockedButton" if locked else "MapMarkerButton"
	marker.modulate = Color(0.62, 0.66, 0.68, 0.88) if locked else Color.WHITE
	marker.focus_mode = Control.FOCUS_ALL
	marker.set_meta("map_locked", locked)
	var icon_view := marker.get_node_or_null("MarkerIcon") as TextureRect
	if icon_view == null:
		icon_view = TextureRect.new()
		icon_view.name = "MarkerIcon"
		marker.add_child(icon_view)
		icon_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_view.offset_left = 4.0
		icon_view.offset_top = 4.0
		icon_view.offset_right = -4.0
		icon_view.offset_bottom = -4.0
		icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var path := icon_name_or_path if icon_name_or_path.begins_with("res://") else "%s%s.png" % [FINAL_ICON_ROOT, icon_name_or_path]
	icon_view.texture = load(path)
	var lock_badge := marker.get_node_or_null("LockBadge") as TextureRect
	if locked:
		if lock_badge == null:
			lock_badge = TextureRect.new()
			lock_badge.name = "LockBadge"
			marker.add_child(lock_badge)
			lock_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			lock_badge.position = Vector2(marker.size.x - 20.0, 1.0)
			lock_badge.size = Vector2(19.0, 19.0)
			lock_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lock_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			lock_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock_badge.texture = load("%slock.png" % FINAL_ICON_ROOT)
		lock_badge.visible = true
	elif lock_badge != null:
		lock_badge.visible = false

func _play_unlock_reveal(marker: Control) -> void:
	if not GameManager.effects_enabled() or not is_visible_in_tree():
		return
	marker.pivot_offset = marker.size * 0.5
	marker.scale = Vector2(0.88, 0.88)
	marker.modulate = Color(1.18, 1.08, 0.84, 0.0)
	var tween := marker.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(marker, "scale", Vector2.ONE, 0.48)
	tween.tween_property(marker, "modulate", Color.WHITE, 0.32)

func _pulse_marker(marker: Control) -> void:
	if not GameManager.effects_enabled() or not is_visible_in_tree():
		return
	marker.pivot_offset = marker.size * 0.5
	var tween := create_tween().set_loops()
	tween.tween_property(marker, "scale", Vector2(1.08, 1.08), 1.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(marker, "scale", Vector2.ONE, 1.05).set_trans(Tween.TRANS_SINE)
