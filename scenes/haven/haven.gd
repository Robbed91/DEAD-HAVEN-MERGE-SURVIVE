extends Control
## Haven
##
## Hollow Creek Farmhouse residence screen. Phase 1 shows the residence
## illustration and its named hotspots as inert markers; Phase 3 wires each
## marker to a ResidenceHotspot's real state machine and repair tasks.

const RESIDENCE_NAME := "Hollow Creek Farmhouse"

func _ready() -> void:
	%ResidenceNameLabel.text = RESIDENCE_NAME
	for marker in %Hotspots.get_children():
		if marker is Button:
			marker.pressed.connect(func(): _on_hotspot_pressed(marker.name))

func _on_hotspot_pressed(hotspot_name: String) -> void:
	EventBus.show_toast.emit("%s repairs open up in a later development phase." % hotspot_name.capitalize())
