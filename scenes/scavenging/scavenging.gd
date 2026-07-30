extends Control
## Scavenging
##
## The full mission flow in one screen: pick a survivor to send, spend the
## mission's energy cost to launch it, pick one of the encounter's choices,
## and see the outcome. Everything resolves synchronously (spec's
## "Duration" field is shown as flavour text only - see DEVELOPMENT_LOG.md
## Phase 5 Known issues for why a true timed/background mission is
## deferred).

const SURVIVOR_NAMES := {
	"mara_vale": "Mara Vale",
	"noah_vance": "Noah Vance",
}

@onready var _title_label: Label = %TitleLabel
@onready var _flavor_label: Label = %FlavorLabel
@onready var _survivor_box: VBoxContainer = %SurvivorBox
@onready var _send_button: Button = %SendButton
@onready var _encounter_label: Label = %EncounterLabel
@onready var _choices_box: VBoxContainer = %ChoicesBox
@onready var _outcome_label: Label = %OutcomeLabel
@onready var _return_button: Button = %ReturnButton

var _mission_id: String = ""
var _selected_survivor_id: String = ""

func _ready() -> void:
	var params := SceneRouter.take_pending_params()
	_mission_id = String(params.get("mission_id", ""))
	var mission := ScavengingManager.get_mission(_mission_id)
	if mission == null:
		# Guard against navigating out from under a caller that instantiated
		# this scene directly for inspection (e.g. tests/smoke_test.gd)
		# rather than via SceneRouter - see haven.gd for the same pattern
		# and DEVELOPMENT_LOG.md Phase 4 for the bug this once caused.
		if get_tree().current_scene == self:
			EventBus.show_toast.emit("That location isn't available.")
			SceneRouter.go_to("world_map", {}, false)
		return

	_title_label.text = mission.location_name
	_flavor_label.text = "Danger %d/5 - Zombie threat %d - Human threat %d - Noise %d - Energy cost %d" % [
		mission.danger_rating, mission.zombie_threat, mission.human_threat, mission.noise_level, mission.energy_cost,
	]

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
	_return_button.pressed.connect(func(): SceneRouter.go_to("world_map", {}, false))

var _shared_group: ButtonGroup

func _survivor_group() -> ButtonGroup:
	if _shared_group == null:
		_shared_group = ButtonGroup.new()
	return _shared_group

func _on_send_pressed() -> void:
	var result := ScavengingManager.launch_mission(_mission_id)
	if not result.success:
		EventBus.show_toast.emit("Not enough energy to send anyone out.")
		return
	_show_encounter()

func _show_encounter() -> void:
	%PrepPanel.visible = false
	%EncounterPanel.visible = true
	var mission := ScavengingManager.get_mission(_mission_id)
	_encounter_label.text = "%s heads out to %s." % [SURVIVOR_NAMES.get(_selected_survivor_id, _selected_survivor_id), mission.location_name]
	for child in _choices_box.get_children():
		child.queue_free()
	for i in mission.encounter_choices.size():
		var choice: Dictionary = mission.encounter_choices[i]
		var btn := Button.new()
		btn.text = String(choice.get("text", "..."))
		btn.custom_minimum_size = Vector2(0, 56)
		btn.pressed.connect(_on_choice_pressed.bind(i))
		_choices_box.add_child(btn)

func _on_choice_pressed(choice_index: int) -> void:
	var result := ScavengingManager.resolve_choice(_mission_id, choice_index)
	%EncounterPanel.visible = false
	%OutcomePanel.visible = true
	var prefix: String = "Success. " if result.outcome_success else "It went sideways. "
	_outcome_label.text = prefix + String(result.text)
