extends Control
## WorldMap
##
## Hollow Creek Farmhouse's marker (a single active location with a gentle
## pulse) is always reachable; the other 4 residences in the current
## roster (Redwater, Greybridge, Saint Mercy, Northgate) each unlock and
## become real navigable markers once their story flag is set - see the
## per-residence `_setup_*_marker()` functions below. Routes, weather
## overlays and day/night cycling are still unbuilt.
##
## Phase 5 adds real scavenging location markers, built from
## ScavengingManager's content - positions are display-only UI data here
## (ScavengingMission's schema has no map-position field; spreading them
## isn't gameplay-relevant enough to belong in the data model). Phase 13
## adds 5 more locations (completing the original 10-location spec) and
## wires ScavengingManager.is_available() so a mission with a
## story_condition doesn't show a marker until that flag is set.

const SCAVENGING_MARKER_POSITIONS := {
	"abandoned_grocery_store": Vector2(0.16, 0.24),
	"petrol_station": Vector2(0.82, 0.2),
	"farm_shed": Vector2(0.78, 0.42),
	"roadside_wreck": Vector2(0.2, 0.62),
	"medical_clinic": Vector2(0.75, 0.72),
	"police_checkpoint": Vector2(0.3, 0.3),
	"electronics_workshop": Vector2(0.65, 0.28),
	"clothing_outlet": Vector2(0.12, 0.5),
	"warehouse_depot": Vector2(0.88, 0.58),
	"radio_relay_station": Vector2(0.35, 0.82),
}

func _ready() -> void:
	_configure_marker(%HollowCreekMarker, "farmhouse")
	%HollowCreekMarker.pressed.connect(func(): SceneRouter.go_to("haven"))
	_setup_redwater_marker()
	_setup_greybridge_marker()
	_setup_saint_mercy_marker()
	_setup_northgate_marker()
	_pulse_marker(%HollowCreekMarker)
	_build_scavenging_markers()
	_build_vehicle_marker()

## Redwater Service Station opens up once GameManager.story_flags
## ["redwater_unlocked"] is set - surviving Hollow Creek's first night
## attack (Phase 7). Phase 8 builds the residence itself, so the marker
## now actually routes there instead of the "found, not yet reachable"
## placeholder message Phase 7 shipped with.
func _setup_redwater_marker() -> void:
	var marker: Button = %RedwaterMarker
	if GameManager.get_story_flag("redwater_unlocked", false):
		_configure_marker(marker, "fuel_station")
		marker.tooltip_text = "Redwater Service Station"
		marker.pressed.connect(func(): SceneRouter.go_to("redwater"))
	else:
		_configure_marker(marker, "lock", true)
		marker.pressed.connect(func(): EventBus.show_toast.emit("Locked - reach this residence by progressing the campaign."))

## Same pattern as Redwater, one residence later: opens once
## story_flags["greybridge_unlocked"] is set by a successful
## redwater_defence (Phase 10).
func _setup_greybridge_marker() -> void:
	var marker: Button = %GreybridgeMarker
	if GameManager.get_story_flag("greybridge_unlocked", false):
		_configure_marker(marker, "school")
		marker.tooltip_text = "Greybridge School"
		marker.pressed.connect(func(): SceneRouter.go_to("greybridge"))
	else:
		_configure_marker(marker, "lock", true)
		marker.pressed.connect(func(): EventBus.show_toast.emit("Locked - reach this residence by progressing the campaign."))

## Same pattern again: opens once story_flags["saint_mercy_unlocked"] is
## set by a successful greybridge_defence (Phase 11).
func _setup_saint_mercy_marker() -> void:
	var marker: Button = %SaintMercyMarker
	if GameManager.get_story_flag("saint_mercy_unlocked", false):
		_configure_marker(marker, "hospital")
		marker.tooltip_text = "Saint Mercy Hospital"
		marker.pressed.connect(func(): SceneRouter.go_to("saint_mercy"))
	else:
		_configure_marker(marker, "lock", true)
		marker.pressed.connect(func(): EventBus.show_toast.emit("Locked - reach this residence by progressing the campaign."))

## Same pattern a fourth time: opens once story_flags["northgate_unlocked"]
## is set by a successful saint_mercy_defence (Phase 12) - the last
## residence in the current roster.
func _setup_northgate_marker() -> void:
	var marker: Button = %NorthgateMarker
	if GameManager.get_story_flag("northgate_unlocked", false):
		_configure_marker(marker, "prison")
		marker.tooltip_text = "Northgate Prison"
		marker.pressed.connect(func(): SceneRouter.go_to("northgate"))
	else:
		_configure_marker(marker, "lock", true)
		marker.pressed.connect(func(): EventBus.show_toast.emit("Locked - reach this residence by progressing the campaign."))

func _build_vehicle_marker() -> void:
	if not VehicleManager.is_discovered("delivery_van"):
		return
	var marker := Button.new()
	_configure_marker(marker, "vehicle")
	marker.tooltip_text = "Old Delivery Van"
	marker.set_anchors_preset(Control.PRESET_TOP_LEFT)
	marker.anchor_left = 0.5
	marker.anchor_right = 0.5
	marker.anchor_top = 0.9
	marker.anchor_bottom = 0.9
	marker.offset_left = -32.0
	marker.offset_right = 32.0
	marker.offset_top = -32.0
	marker.offset_bottom = 32.0
	marker.pressed.connect(func(): SceneRouter.go_to("vehicle"))
	%MapArea.add_child(marker)
	if GameManager.effects_enabled():
		var destination := marker.position
		marker.position += Vector2(-140, 70)
		marker.modulate.a = 0.0
		var route_tween := marker.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		route_tween.tween_property(marker, "position", destination, 0.72)
		route_tween.tween_property(marker, "modulate:a", 1.0, 0.36)

func _build_scavenging_markers() -> void:
	var layer: Control = %MapArea
	for mission_id in SCAVENGING_MARKER_POSITIONS:
		var mission := ScavengingManager.get_mission(mission_id)
		if mission == null or not ScavengingManager.is_available(mission_id):
			continue
		var pos: Vector2 = SCAVENGING_MARKER_POSITIONS[mission_id]
		var marker := Button.new()
		_configure_marker(marker, "scavenge")
		marker.tooltip_text = "%s - scavenge" % mission.location_name
		marker.set_anchors_preset(Control.PRESET_TOP_LEFT)
		marker.anchor_left = pos.x
		marker.anchor_right = pos.x
		marker.anchor_top = pos.y
		marker.anchor_bottom = pos.y
		marker.offset_left = -30.0
		marker.offset_right = 30.0
		marker.offset_top = -30.0
		marker.offset_bottom = 30.0
		marker.pressed.connect(func(): SceneRouter.go_to("scavenging", {"mission_id": mission_id}))
		layer.add_child(marker)

func _configure_marker(marker: Button, icon_name: String, locked: bool = false) -> void:
	marker.text = ""
	marker.icon = null
	marker.theme_type_variation = "LockedButton" if locked else "MapMarkerButton"
	marker.modulate = Color(0.72, 0.77, 0.8, 0.82) if locked else Color.WHITE
	marker.focus_mode = Control.FOCUS_ALL
	var icon_view := marker.get_node_or_null("MarkerIcon") as TextureRect
	if icon_view == null:
		icon_view = TextureRect.new()
		icon_view.name = "MarkerIcon"
		marker.add_child(icon_view)
		icon_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_view.offset_left = 7.0
		icon_view.offset_top = 7.0
		icon_view.offset_right = -7.0
		icon_view.offset_bottom = -7.0
		icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_view.texture = load("res://assets/ui/icons/final/icon_%s.png" % icon_name)

func _pulse_marker(marker: Control) -> void:
	if not GameManager.effects_enabled():
		return
	marker.pivot_offset = marker.size * 0.5
	var tween := create_tween().set_loops()
	tween.tween_property(marker, "scale", Vector2(1.12, 1.12), 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(marker, "scale", Vector2(1.0, 1.0), 0.9).set_trans(Tween.TRANS_SINE)
