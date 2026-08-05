extends Control
## Greybridge
##
## Greybridge School residence screen - Phase 10's third residence,
## reachable from the World Map once redwater_defence's success sets
## greybridge_unlocked. Same data-driven hotspot/task-panel pattern as
## scenes/haven/haven.gd and scenes/redwater/redwater.gd.

const RESIDENCE_ID := "greybridge_school"
const DEFENCE_EVENT_ID := "greybridge_defence"
## Shrunk from a near-board-cell-sized 64x64 to a corner badge - see
## haven.gd for why (repair markers were obscuring/input-blocking items).
const HOTSPOT_SIZE := Vector2(40, 40)
const HOTSPOT_CORNER_BIAS := Vector2(20.0, -20.0)

const CHAPTER_TITLES := {
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
@onready var _background: Control = $Layout/Scene/Background
@onready var _board_panel: MergeBoard = %BoardPanel

var _hotspot_visuals: Dictionary = {} # hotspot_id -> HotspotVisual

func _enter_tree() -> void:
	BoardState.activate_residence_board(RESIDENCE_ID)

func _ready() -> void:
	var residence := ResidenceManager.get_residence(RESIDENCE_ID)
	%ResidenceNameLabel.text = residence.display_name if residence else "Greybridge School"

	if residence != null:
		for hotspot in residence.hotspots:
			_build_hotspot(hotspot)

	_task_panel.completed.connect(_on_task_completed)
	_task_panel.find_requested.connect(_board_panel.highlight_chain)
	_defence_button.pressed.connect(func(): SceneRouter.go_to("defence", {"event_id": DEFENCE_EVENT_ID, "return_scene_key": "greybridge"}))
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
	visual.set_anchors_preset(Control.PRESET_TOP_LEFT)
	visual.anchor_left = hotspot.area_position.x
	visual.anchor_right = hotspot.area_position.x
	visual.anchor_top = hotspot.area_position.y
	visual.anchor_bottom = hotspot.area_position.y
	visual.offset_left = HOTSPOT_CORNER_BIAS.x - HOTSPOT_SIZE.x * 0.5
	visual.offset_right = HOTSPOT_CORNER_BIAS.x + HOTSPOT_SIZE.x * 0.5
	visual.offset_top = HOTSPOT_CORNER_BIAS.y - HOTSPOT_SIZE.y * 0.5
	visual.offset_bottom = HOTSPOT_CORNER_BIAS.y + HOTSPOT_SIZE.y * 0.5
	visual.tooltip_text = hotspot.display_name
	visual.tapped.connect(_on_hotspot_tapped)
	_hotspots_layer.add_child(visual)
	_hotspot_visuals[hotspot.id] = visual

func _on_hotspot_tapped(hotspot_id: String) -> void:
	_task_panel.show_for_hotspot(hotspot_id, RESIDENCE_ID)

func _on_task_completed(hotspot_id: String) -> void:
	_board_panel.refresh_board()
	AudioManager.play_sfx("radio_pulse" if hotspot_id == "radio_tower" else ("generator_start" if hotspot_id == "boiler_room" else "metal_fastening"))
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
