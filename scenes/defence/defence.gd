extends Control
## Defence
##
## A residence's climactic attack: pick who leads the response, spend
## energy to commit, choose how to handle it, see the outcome. Same
## three-panel flow as scenes/scavenging/scavenging.gd, reused
## deliberately rather than re-architected. Takes an `event_id` param via
## SceneRouter (see DefenceManager.events) so this one screen serves every
## residence's defence event instead of one screen per residence.

const SURVIVOR_NAMES := {
	"mara_vale": "Mara Vale",
	"noah_vance": "Noah Vance",
	"lena_ortiz": "Lena Ortiz",
	"riley_chen": "Riley Chen",
}
const EVENT_LABELS := {
	"hollow_creek_first_wave": "The First Night",
	"redwater_defence": "Defend the Station",
	"greybridge_defence": "Defend the School",
}
const ENCOUNTER_INTROS := {
	"hollow_creek_first_wave": "Night falls, and they come from the treeline. What now?",
	"redwater_defence": "Movement at the fence line as the light fades. What now?",
	"greybridge_defence": "They're coming across the playground as the light dies. What now?",
}

@onready var _title_label: Label = %TitleLabel
@onready var _survivor_box: VBoxContainer = %SurvivorBox
@onready var _send_button: Button = %SendButton
@onready var _encounter_label: Label = %EncounterLabel
@onready var _choices_box: VBoxContainer = %ChoicesBox
@onready var _outcome_label: Label = %OutcomeLabel
@onready var _return_button: Button = %ReturnButton
@onready var _prep_panel: VBoxContainer = %PrepPanel
@onready var _encounter_panel: VBoxContainer = %EncounterPanel
@onready var _outcome_panel: VBoxContainer = %OutcomePanel

var _event_id: String = ""
var _return_scene_key: String = "haven"
var _selected_survivor_id: String = ""
var _shared_group: ButtonGroup

func _ready() -> void:
	var params := SceneRouter.take_pending_params()
	_event_id = String(params.get("event_id", "hollow_creek_first_wave"))
	_return_scene_key = String(params.get("return_scene_key", "haven"))

	if not DefenceManager.can_attempt(_event_id):
		if get_tree().current_scene == self:
			var reason := "You need to finish repairing here first." if not DefenceManager.all_hotspots_complete(_event_id) else "You've already made it through this one."
			EventBus.show_toast.emit(reason)
			SceneRouter.go_to(_return_scene_key, {}, false)
		return

	_title_label.text = EVENT_LABELS.get(_event_id, "Defence")

	for survivor_id in GameManager.get_unlocked_survivor_ids():
		var btn := Button.new()
		btn.text = SURVIVOR_NAMES.get(survivor_id, survivor_id)
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(0, 52)
		btn.button_group = _survivor_group()
		btn.pressed.connect(func(): _selected_survivor_id = survivor_id)
		_survivor_box.add_child(btn)
		if _selected_survivor_id.is_empty():
			_selected_survivor_id = survivor_id
			btn.button_pressed = true

	_send_button.pressed.connect(_on_send_pressed)
	_return_button.pressed.connect(func(): SceneRouter.go_to(_return_scene_key, {}, false))

func _survivor_group() -> ButtonGroup:
	if _shared_group == null:
		_shared_group = ButtonGroup.new()
	return _shared_group

func _on_send_pressed() -> void:
	var result := DefenceManager.launch(_event_id, _selected_survivor_id)
	if not result.success:
		EventBus.show_toast.emit("Not enough energy to prepare.")
		return
	_prep_panel.visible = false
	_encounter_panel.visible = true
	_encounter_label.text = ENCOUNTER_INTROS.get(_event_id, "What now?")
	for child in _choices_box.get_children():
		child.queue_free()
	var choice_list: Array = DefenceManager.event_choices.get(_event_id, [])
	for i in choice_list.size():
		var choice: Dictionary = choice_list[i]
		var btn := Button.new()
		btn.text = String(choice.get("text", "..."))
		btn.custom_minimum_size = Vector2(0, 56)
		btn.pressed.connect(_on_choice_pressed.bind(i))
		_choices_box.add_child(btn)

func _on_choice_pressed(choice_index: int) -> void:
	var result := DefenceManager.resolve_choice(_event_id, choice_index, _selected_survivor_id)
	_encounter_panel.visible = false
	_outcome_panel.visible = true
	var prefix: String = "You made it through. " if result.outcome_success else "It was close. "
	_outcome_label.text = prefix + String(result.text)
