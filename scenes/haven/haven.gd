extends Control
## Haven
##
## Hollow Creek Farmhouse residence screen. Phase 3: hotspots are real,
## data-driven from ResidenceManager/ResidenceDefinition - each one shows
## its current repair state and opens a real task (TaskPanel) that
## consumes a merge-board item and advances it.

const RESIDENCE_ID := "hollow_creek_farmhouse"
const HOTSPOT_SIZE := Vector2(64, 64)

@onready var _hotspots_layer: Control = %Hotspots
@onready var _task_panel: TaskPanel = %TaskPanel
@onready var _progress_label: Label = %ProgressLabel

var _hotspot_visuals: Dictionary = {} # hotspot_id -> HotspotVisual

func _ready() -> void:
	var residence := ResidenceManager.get_residence(RESIDENCE_ID)
	%ResidenceNameLabel.text = residence.display_name if residence else "Hollow Creek Farmhouse"

	if residence != null:
		for hotspot in residence.hotspots:
			_build_hotspot(hotspot)

	_task_panel.completed.connect(_on_task_completed)
	_refresh_progress()

func _build_hotspot(hotspot: ResidenceHotspot) -> void:
	var visual := HotspotVisual.new()
	visual.hotspot_id = hotspot.id
	visual.residence_id = RESIDENCE_ID
	visual.custom_minimum_size = HOTSPOT_SIZE
	visual.size = HOTSPOT_SIZE
	visual.set_anchors_preset(Control.PRESET_TOP_LEFT)
	visual.anchor_left = hotspot.area_position.x
	visual.anchor_right = hotspot.area_position.x
	visual.anchor_top = hotspot.area_position.y
	visual.anchor_bottom = hotspot.area_position.y
	visual.offset_left = -HOTSPOT_SIZE.x * 0.5
	visual.offset_right = HOTSPOT_SIZE.x * 0.5
	visual.offset_top = -HOTSPOT_SIZE.y * 0.5
	visual.offset_bottom = HOTSPOT_SIZE.y * 0.5
	visual.tooltip_text = hotspot.display_name
	visual.tapped.connect(_on_hotspot_tapped)
	_hotspots_layer.add_child(visual)
	_hotspot_visuals[hotspot.id] = visual

func _on_hotspot_tapped(hotspot_id: String) -> void:
	_task_panel.show_for_hotspot(hotspot_id)

func _on_task_completed(hotspot_id: String) -> void:
	if _hotspot_visuals.has(hotspot_id):
		_hotspot_visuals[hotspot_id].play_repair_burst()
	AudioManager.play_sfx("task_complete")
	_refresh_progress()

func _refresh_progress() -> void:
	var residence := ResidenceManager.get_residence(RESIDENCE_ID)
	if residence == null:
		return
	var done := 0
	for hotspot in residence.hotspots:
		if ResidenceManager.get_hotspot_state(hotspot.id) == ResidenceHotspot.State.COMPLETED:
			done += 1
	_progress_label.text = "Repairs: %d / %d" % [done, residence.hotspots.size()]
