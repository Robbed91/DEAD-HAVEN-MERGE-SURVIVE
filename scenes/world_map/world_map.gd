extends Control
## WorldMap
##
## Phase 1 placeholder: a single active location marker (Hollow Creek
## Farmhouse) with a gentle pulse, and locked markers for the residences
## documented in the design spec. Routes, weather overlays and day/night
## cycling are Phase 8 (World map expansion) work.

func _ready() -> void:
	%HollowCreekMarker.pressed.connect(func(): SceneRouter.go_to("haven"))
	for locked_name in ["RedwaterMarker", "GreybridgeMarker", "SaintMercyMarker", "NorthgateMarker"]:
		var marker: Button = get_node("%" + locked_name)
		marker.pressed.connect(func(): EventBus.show_toast.emit("Locked - reach this residence by progressing the campaign."))
	_pulse_marker(%HollowCreekMarker)

func _pulse_marker(marker: Control) -> void:
	if GameManager.settings.get("reduced_motion", false):
		return
	var tween := create_tween().set_loops()
	tween.tween_property(marker, "scale", Vector2(1.12, 1.12), 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(marker, "scale", Vector2(1.0, 1.0), 0.9).set_trans(Tween.TRANS_SINE)
