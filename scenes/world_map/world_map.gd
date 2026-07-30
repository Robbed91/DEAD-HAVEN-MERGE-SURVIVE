extends Control
## WorldMap
##
## Phase 1 placeholder for residences: a single active location marker
## (Hollow Creek Farmhouse) with a gentle pulse, and locked markers for the
## residences documented in the design spec. Routes, weather overlays and
## day/night cycling are Phase 8 (World map expansion) work.
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
	for locked_name in ["RedwaterMarker", "GreybridgeMarker", "SaintMercyMarker", "NorthgateMarker"]:
		var marker: Button = get_node("%" + locked_name)
		marker.pressed.connect(func(): EventBus.show_toast.emit("Locked - reach this residence by progressing the campaign."))
	_pulse_marker(%HollowCreekMarker)
	_build_scavenging_markers()

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
	if GameManager.settings.get("reduced_motion", false):
		return
	var tween := create_tween().set_loops()
	tween.tween_property(marker, "scale", Vector2(1.12, 1.12), 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(marker, "scale", Vector2(1.0, 1.0), 0.9).set_trans(Tween.TRANS_SINE)
