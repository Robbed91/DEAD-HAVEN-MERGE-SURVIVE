extends Control
## WorldMap
##
## Hollow Creek Farmhouse's marker (a single active location with a gentle
## pulse) is always reachable; Redwater Service Station (Phase 8) and
## Greybridge School (Phase 10) unlock and become real navigable markers
## once their story flag is set; Saint Mercy Hospital and Northgate Prison
## remain locked placeholders. Routes, weather overlays and day/night
## cycling are still unbuilt.
##
## Phase 5 adds real scavenging location markers, built from
## ScavengingManager's content - positions are display-only UI data here
## (ScavengingMission's schema has no map-position field; spreading them
## isn't gameplay-relevant enough to belong in the data model).

const SCAVENGING_MARKER_POSITIONS := {
	"abandoned_grocery_store": Vector2(0.16, 0.24),
	"petrol_station": Vector2(0.82, 0.2),
	"farm_shed": Vector2(0.78, 0.42),
	"roadside_wreck": Vector2(0.2, 0.62),
	"medical_clinic": Vector2(0.75, 0.72),
}

func _ready() -> void:
	%HollowCreekMarker.pressed.connect(func(): SceneRouter.go_to("haven"))
	_setup_redwater_marker()
	_setup_greybridge_marker()
	_setup_saint_mercy_marker()
	var locked_marker: Button = %NorthgateMarker
	locked_marker.pressed.connect(func(): EventBus.show_toast.emit("Locked - reach this residence by progressing the campaign."))
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
		marker.modulate.a = 1.0
		marker.text = "⛽"
		marker.tooltip_text = "Redwater Service Station"
		marker.pressed.connect(func(): SceneRouter.go_to("redwater"))
	else:
		marker.pressed.connect(func(): EventBus.show_toast.emit("Locked - reach this residence by progressing the campaign."))

## Same pattern as Redwater, one residence later: opens once
## story_flags["greybridge_unlocked"] is set by a successful
## redwater_defence (Phase 10).
func _setup_greybridge_marker() -> void:
	var marker: Button = %GreybridgeMarker
	if GameManager.get_story_flag("greybridge_unlocked", false):
		marker.modulate.a = 1.0
		marker.text = "🏫"
		marker.tooltip_text = "Greybridge School"
		marker.pressed.connect(func(): SceneRouter.go_to("greybridge"))
	else:
		marker.pressed.connect(func(): EventBus.show_toast.emit("Locked - reach this residence by progressing the campaign."))

## Same pattern again: opens once story_flags["saint_mercy_unlocked"] is
## set by a successful greybridge_defence (Phase 11).
func _setup_saint_mercy_marker() -> void:
	var marker: Button = %SaintMercyMarker
	if GameManager.get_story_flag("saint_mercy_unlocked", false):
		marker.modulate.a = 1.0
		marker.text = "🏥"
		marker.tooltip_text = "Saint Mercy Hospital"
		marker.pressed.connect(func(): SceneRouter.go_to("saint_mercy"))
	else:
		marker.pressed.connect(func(): EventBus.show_toast.emit("Locked - reach this residence by progressing the campaign."))

func _build_vehicle_marker() -> void:
	if not VehicleManager.is_discovered("delivery_van"):
		return
	var marker := Button.new()
	marker.text = "🚐"
	marker.tooltip_text = "Old Delivery Van"
	marker.set_anchors_preset(Control.PRESET_TOP_LEFT)
	marker.anchor_left = 0.5
	marker.anchor_right = 0.5
	marker.anchor_top = 0.9
	marker.anchor_bottom = 0.9
	marker.offset_left = -24.0
	marker.offset_right = 24.0
	marker.offset_top = -24.0
	marker.offset_bottom = 24.0
	marker.pressed.connect(func(): SceneRouter.go_to("vehicle"))
	%MapArea.add_child(marker)

func _build_scavenging_markers() -> void:
	var layer: Control = %MapArea
	for mission_id in SCAVENGING_MARKER_POSITIONS:
		var mission := ScavengingManager.get_mission(mission_id)
		if mission == null:
			continue
		var pos: Vector2 = SCAVENGING_MARKER_POSITIONS[mission_id]
		var marker := Button.new()
		marker.text = "📦"
		marker.tooltip_text = "%s - scavenge" % mission.location_name
		marker.set_anchors_preset(Control.PRESET_TOP_LEFT)
		marker.anchor_left = pos.x
		marker.anchor_right = pos.x
		marker.anchor_top = pos.y
		marker.anchor_bottom = pos.y
		marker.offset_left = -22.0
		marker.offset_right = 22.0
		marker.offset_top = -22.0
		marker.offset_bottom = 22.0
		marker.pressed.connect(func(): SceneRouter.go_to("scavenging", {"mission_id": mission_id}))
		layer.add_child(marker)

func _pulse_marker(marker: Control) -> void:
	if not GameManager.effects_enabled():
		return
	var tween := create_tween().set_loops()
	tween.tween_property(marker, "scale", Vector2(1.12, 1.12), 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(marker, "scale", Vector2(1.0, 1.0), 0.9).set_trans(Tween.TRANS_SINE)
