extends Control
## Haven
##
## Hollow Creek Farmhouse residence screen. Phase 3: hotspots are real,
## data-driven from ResidenceManager/ResidenceDefinition - each one shows
## its current repair state and opens a real task (TaskPanel) that
## consumes a merge-board item and advances it.

const RESIDENCE_ID := "hollow_creek_farmhouse"
const HOTSPOT_SIZE := Vector2(64, 64)

const CHAPTER_TITLES := {
	"chapter_1_the_open_door": "Chapter 1: The Open Door",
	"chapter_2_someone_upstairs": "Chapter 2: Someone Upstairs",
	"chapter_4_the_first_wave": "Chapter 4: The First Wave",
}

@onready var _hotspots_layer: Control = %Hotspots
@onready var _task_panel: TaskPanel = %TaskPanel
@onready var _progress_label: Label = %ProgressLabel
@onready var _chapter_label: Label = %ChapterLabel
@onready var _defence_button: Button = %DefenceButton

var _hotspot_visuals: Dictionary = {} # hotspot_id -> HotspotVisual

func _ready() -> void:
	var residence := ResidenceManager.get_residence(RESIDENCE_ID)
	%ResidenceNameLabel.text = residence.display_name if residence else "Hollow Creek Farmhouse"

	if residence != null:
		for hotspot in residence.hotspots:
			_build_hotspot(hotspot)

	_task_panel.completed.connect(_on_task_completed)
	_defence_button.pressed.connect(func(): SceneRouter.go_to("defence"))
	EventBus.chapter_changed.connect(func(_id): _refresh_chapter_label())
	EventBus.defence_resolved.connect(func(_outcome): _refresh_progress())
	_refresh_progress()
	_refresh_chapter_label()

	# Only auto-launch the intro when this Haven is actually the tree's
	# active scene (i.e. reached through normal navigation) - never when
	# something else instantiates Haven as a child for inspection (e.g.
	# tests/smoke_test.gd), which must not have its own tree replaced out
	# from under it as a side effect of Haven's _ready().
	if get_tree().current_scene == self and not GameManager.get_story_flag("chapter_1_intro_seen", false):
		GameManager.set_story_flag("chapter_1_intro_seen", true)
		DialogueManager.start_dialogue("intro_01")

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
	_defence_button.visible = DefenceManager.can_attempt()
