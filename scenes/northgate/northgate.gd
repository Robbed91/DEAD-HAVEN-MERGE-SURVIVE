extends Control
## Northgate
##
## Northgate Prison residence screen - Phase 12's fifth residence,
## reachable from the World Map once saint_mercy_defence's success sets
## northgate_unlocked. Same data-driven hotspot/task-panel pattern as
## every other residence screen.

const RESIDENCE_ID := "northgate_prison"
const DEFENCE_EVENT_ID := "northgate_defence"
const HOTSPOT_SIZE := Vector2(76, 76)

const CHAPTER_TITLES := {
	"chapter_7_do_no_harm": "Chapter 7: Do No Harm",
	"chapter_8_old_debts": "Chapter 8: Old Debts",
	"chapter_9_the_signal_keeper": "Chapter 9: The Signal Keeper",
}

@onready var _hotspots_layer: Control = %Hotspots
@onready var _task_panel: TaskPanel = %TaskPanel
@onready var _progress_label: Label = %ProgressLabel
@onready var _chapter_label: Label = %ChapterLabel
@onready var _defence_button: Button = %DefenceButton
@onready var _background: Control = $Layout/Scene/Background

var _hotspot_visuals: Dictionary = {} # hotspot_id -> HotspotVisual

func _ready() -> void:
	var residence := ResidenceManager.get_residence(RESIDENCE_ID)
	%ResidenceNameLabel.text = residence.display_name if residence else "Northgate Prison"

	if residence != null:
		for hotspot in residence.hotspots:
			_build_hotspot(hotspot)

	_task_panel.completed.connect(_on_task_completed)
	_task_panel.visibility_changed.connect(func():
		if not _task_panel.visible:
			_set_selected_hotspot("")
	)
	_defence_button.pressed.connect(func(): SceneRouter.go_to("defence", {"event_id": DEFENCE_EVENT_ID, "return_scene_key": "northgate"}))
	EventBus.chapter_changed.connect(func(_id): _refresh_chapter_label())
	EventBus.defence_resolved.connect(func(_outcome): _refresh_progress())
	_refresh_progress()
	_refresh_chapter_label()

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
	_set_selected_hotspot(hotspot_id)
	_task_panel.show_for_hotspot(hotspot_id, RESIDENCE_ID)

func _set_selected_hotspot(hotspot_id: String) -> void:
	for id in _hotspot_visuals:
		_hotspot_visuals[id].set_selected(id == hotspot_id)

func _on_task_completed(hotspot_id: String) -> void:
	AudioManager.play_sfx("fence_repair" if hotspot_id == "sally_port" else ("trap_deploy" if hotspot_id in ["guard_tower", "armory"] else "metal_fastening"))
	_background.play_repair(hotspot_id)
	if _hotspot_visuals.has(hotspot_id):
		_hotspot_visuals[hotspot_id].play_repair_burst()
	AudioManager.play_sfx("repair_whoosh")
	AudioManager.play_sfx("task_complete")
	_refresh_progress()

func _refresh_chapter_label() -> void:
	var chapter_id: String = GameManager.profile.current_chapter_id
	_chapter_label.text = CHAPTER_TITLES.get(chapter_id, chapter_id)

func _refresh_progress() -> void:
	var residence := ResidenceManager.get_residence(RESIDENCE_ID)
	if residence == null:
		return
	var done := 0
	for hotspot in residence.hotspots:
		if ResidenceManager.get_hotspot_state(hotspot.id) == ResidenceHotspot.State.COMPLETED:
			done += 1
	_progress_label.text = "Repairs: %d / %d" % [done, residence.hotspots.size()]
	_defence_button.visible = DefenceManager.can_attempt(DEFENCE_EVENT_ID)
