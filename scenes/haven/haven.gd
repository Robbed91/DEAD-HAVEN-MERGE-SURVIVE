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
	"chapter_5_the_station": "Chapter 5: The Station",
	"chapter_6_the_signal": "Chapter 6: The Signal",
	"chapter_7_do_no_harm": "Chapter 7: Do No Harm",
	"chapter_8_old_debts": "Chapter 8: Old Debts",
	"chapter_9_the_signal_keeper": "Chapter 9: The Signal Keeper",
}

@onready var _hotspots_layer: Control = %Hotspots
@onready var _task_panel: TaskPanel = %TaskPanel
@onready var _progress_label: Label = %ProgressLabel
@onready var _chapter_label: Label = %ChapterLabel
@onready var _defence_button: Button = %DefenceButton
@onready var _background: HollowCreekEnvironment = $Layout/Scene/Background

var _hotspot_visuals: Dictionary = {} # hotspot_id -> HotspotVisual

func _ready() -> void:
	for label in [%ResidenceNameLabel, %ChapterLabel, %ProgressLabel]:
		label.add_theme_font_override("font", ThemeFactory.display_font())
	var residence := ResidenceManager.get_residence(RESIDENCE_ID)
	%ResidenceNameLabel.text = residence.display_name if residence else "Hollow Creek Farmhouse"

	if residence != null:
		for hotspot in residence.hotspots:
			_build_hotspot(hotspot)

	_task_panel.completed.connect(_on_task_completed)
	_defence_button.pressed.connect(func(): SceneRouter.go_to("defence", {"event_id": "hollow_creek_first_wave", "return_scene_key": "haven"}))
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

	# Phase 13's main-story capstone: every residence's own defence event
	# only knows about unlocking its immediate neighbour (see
	# DEVELOPMENT_LOG.md Phase 8+ Known issues), so nothing previously
	# recognised "all five secured" as a moment worth its own beat. Same
	# active-scene guard and story-flag-gates-a-one-time-trigger pattern
	# as the Chapter 1 intro above.
	if get_tree().current_scene == self and DefenceManager.all_events_survived() and not GameManager.get_story_flag("signal_keeper_triggered", false):
		GameManager.set_story_flag("signal_keeper_triggered", true)
		GameManager.advance_chapter("chapter_9_the_signal_keeper")
		DialogueManager.start_dialogue("signal_keeper_01")

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
	_task_panel.show_for_hotspot(hotspot_id, RESIDENCE_ID)

func _on_task_completed(hotspot_id: String) -> void:
	AudioManager.play_sfx(_repair_audio_key(hotspot_id))
	if hotspot_id == "fireplace": AudioManager.play_ambience_layer("fire", -12.0)
	_play_repair_camera_sequence(hotspot_id)
	_background.play_survivor_repair(hotspot_id)
	if hotspot_id == "kitchen_window":
		_background.play_window_boarding()
	if _hotspot_visuals.has(hotspot_id):
		_hotspot_visuals[hotspot_id].play_repair_burst()
	AudioManager.play_sfx("repair_whoosh")
	AudioManager.play_sfx("task_complete")
	_refresh_progress()

func _repair_audio_key(hotspot_id: String) -> String:
	if hotspot_id == "kitchen_window": return "window_board"
	if hotspot_id == "front_door": return "door_repair"
	if hotspot_id in ["rear_escape", "perimeter_traps"]: return "trap_deploy"
	if hotspot_id in ["barn", "living_room", "upstairs_bedroom"]: return "hammer"
	if hotspot_id == "fireplace": return "debris_clear"
	return "tool_handle"

func _play_repair_camera_sequence(hotspot_id: String) -> void:
	if not GameManager.effects_enabled(): return
	var scene: Control = $Layout/Scene
	var residence := ResidenceManager.get_residence(RESIDENCE_ID)
	var focus := Vector2(0.5, 0.5)
	for hotspot in residence.hotspots:
		if hotspot.id == hotspot_id:
			focus = hotspot.area_position
			break
	scene.pivot_offset = scene.size * focus
	var tween := scene.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(scene, "scale", Vector2(1.045, 1.045), 0.24)
	tween.tween_interval(0.72)
	tween.tween_property(scene, "scale", Vector2.ONE, 0.28)

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
	_defence_button.visible = DefenceManager.can_attempt("hollow_creek_first_wave")
