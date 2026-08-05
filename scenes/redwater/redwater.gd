extends Control
## Redwater
##
## Redwater Service Station residence screen - Phase 8's second residence,
## reachable once the World Map marker unlocks (see world_map.gd). Same
## data-driven hotspot/task-panel pattern as scenes/haven/haven.gd,
## deliberately reused rather than re-architected: a residence screen is a
## residence screen regardless of which ResidenceDefinition backs it.

const RESIDENCE_ID := "redwater_service_station"
const DEFENCE_EVENT_ID := "redwater_defence"
## Hotspot markers moved off the board grid into a horizontal task strip -
## see haven.gd for why (they used to sit on top of the board and fully
## obscure/input-block whichever merge item shared their cell).
const HOTSPOT_SIZE := Vector2(48, 48)

const CHAPTER_TITLES := {
	"chapter_4_the_first_wave": "Chapter 4: The First Wave",
	"chapter_5_the_station": "Chapter 5: The Station",
	"chapter_6_the_signal": "Chapter 6: The Signal",
	"chapter_7_do_no_harm": "Chapter 7: Do No Harm",
	"chapter_8_old_debts": "Chapter 8: Old Debts",
	"chapter_9_the_signal_keeper": "Chapter 9: The Signal Keeper",
}

@onready var _hotspots_layer: HBoxContainer = %Hotspots
@onready var _task_panel: TaskPanel = %TaskPanel
@onready var _progress_label: Label = %ProgressLabel
@onready var _chapter_label: Label = %ChapterLabel
@onready var _defence_button: Button = %DefenceButton
@onready var _background: RedwaterEnvironment = $Layout/Scene/Background
@onready var _board_panel: MergeBoard = %BoardPanel

var _hotspot_visuals: Dictionary = {} # hotspot_id -> HotspotVisual

func _enter_tree() -> void:
	BoardState.activate_residence_board(RESIDENCE_ID)

func _ready() -> void:
	var residence := ResidenceManager.get_residence(RESIDENCE_ID)
	%ResidenceNameLabel.text = residence.display_name if residence else "Redwater Service Station"

	if residence != null:
		for hotspot in residence.hotspots:
			_build_hotspot(hotspot)

	_task_panel.completed.connect(_on_task_completed)
	_task_panel.find_requested.connect(_board_panel.highlight_chain)
	_defence_button.pressed.connect(func(): SceneRouter.go_to("defence", {"event_id": DEFENCE_EVENT_ID, "return_scene_key": "redwater"}))
	EventBus.chapter_changed.connect(func(_id): _refresh_chapter_label())
	EventBus.defence_resolved.connect(func(_outcome): _refresh_progress())
	_refresh_progress()
	_refresh_chapter_label()
	_apply_board_params()

func _build_hotspot(hotspot: ResidenceHotspot) -> void:
	var visual := HotspotVisual.new()
	visual.hotspot_id = hotspot.id
	visual.residence_id = RESIDENCE_ID
	visual.custom_minimum_size = HOTSPOT_SIZE
	visual.size = HOTSPOT_SIZE
	visual.tooltip_text = hotspot.display_name
	visual.tapped.connect(_on_hotspot_tapped)
	_hotspots_layer.add_child(visual)
	_hotspot_visuals[hotspot.id] = visual

func _on_hotspot_tapped(hotspot_id: String) -> void:
	_task_panel.show_for_hotspot(hotspot_id, RESIDENCE_ID)

func _on_task_completed(hotspot_id: String) -> void:
	_board_panel.refresh_board()
	AudioManager.play_sfx("generator_start" if hotspot_id == "generator_room" else ("fence_repair" if hotspot_id == "perimeter_fence" else "metal_fastening"))
	if hotspot_id == "generator_room": AudioManager.play_ambience_layer("generator", -13.0)
	_background.play_repair(hotspot_id)
	if _hotspot_visuals.has(hotspot_id):
		_hotspot_visuals[hotspot_id].play_repair_burst()
	AudioManager.play_sfx("repair_whoosh")
	AudioManager.play_sfx("task_complete")
	_refresh_progress()

func _apply_board_params() -> void:
	var params := SceneRouter.take_pending_params()
	if params.has("highlight_chain_id"):
		_board_panel.highlight_chain(String(params.highlight_chain_id))

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
