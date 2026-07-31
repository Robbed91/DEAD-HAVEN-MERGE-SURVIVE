extends Control
## Dialogue
##
## Renders one DialogueEntry at a time (speaker, portrait, text), advancing
## via next_id on tap or via branching_options as buttons. A selected
## option's reward is granted immediately (same coins/xp/energy keys as
## quest rewards) and its relationship_changes are written into
## GameManager's story_flags (see set_story_flag doc comment - a lightweight
## stand-in for Phase 6's real relationship system). The "condition" and
## "quest_trigger" option fields are part of the DialogueEntry schema but
## unused by any current content - no dialogue in this build needs them yet.

## Bug fix (Phase 13): these two dicts only ever had Mara/Noah, so every
## later rescue scene's own speaker (Lena, Riley, Imogen, Caleb) fell back
## to a literal id as the displayed name and a generic grey portrait -
## never caught earlier because no smoke test asserts dialogue-screen
## label text (headless tests exercise DialogueManager/branching logic,
## not this screen's rendering - see tests/README.md).
const SPEAKER_NAMES := {
	"": "",
	"mara_vale": "Mara Vale",
	"noah_vance": "Noah Vance",
	"lena_ortiz": "Lena Ortiz",
	"riley_chen": "Riley Chen",
	"imogen_shaw": "Dr Imogen Shaw",
	"caleb_rusk": "Caleb Rusk",
	"signal_keeper": "??? (The Signal Keeper)",
}
const SPEAKER_COLORS := {
	"": Color("8a8f8a"),
	"mara_vale": Color("6b7a56"),
	"noah_vance": Color("8a3c1f"),
	"lena_ortiz": Color("cf6a3f"),
	"riley_chen": Color("4a7a9e"),
	"imogen_shaw": Color("4d8a7a"),
	"caleb_rusk": Color("5a5a4a"),
	"signal_keeper": Color("7fb0b8"),
}

@onready var _portrait: SurvivorSilhouette = %Portrait
@onready var _speaker_label: Label = %SpeakerLabel
@onready var _text_label: Label = %TextLabel
@onready var _continue_button: Button = %ContinueButton
@onready var _choices_box: VBoxContainer = %ChoicesBox

var _current_id: String = ""
var _return_scene_key: String = "haven"

func _ready() -> void:
	var params := SceneRouter.take_pending_params()
	_return_scene_key = String(params.get("return_scene_key", "haven"))
	var start_id := String(params.get("start_id", ""))
	_continue_button.pressed.connect(_on_continue_pressed)

	if start_id.is_empty() or not DialogueManager.has_entry(start_id):
		# Guard against navigating out from under a caller that instantiated
		# this scene directly for inspection (e.g. tests/smoke_test.gd)
		# rather than via SceneRouter - see haven.gd for the same pattern
		# and DEVELOPMENT_LOG.md Phase 4 for the bug this once caused.
		if get_tree().current_scene == self:
			push_error("Dialogue: no valid start_id in pending params, returning to %s" % _return_scene_key)
			SceneRouter.go_to(_return_scene_key, {}, false)
		return
	_show_entry(start_id)

func _show_entry(id: String) -> void:
	var entry := DialogueManager.get_entry(id)
	if entry == null:
		_finish()
		return
	_current_id = id

	var has_speaker: bool = not entry.speaker_id.is_empty()
	_speaker_label.visible = has_speaker
	_speaker_label.text = SPEAKER_NAMES.get(entry.speaker_id, entry.speaker_id)
	_portrait.visible = has_speaker
	_portrait.silhouette_color = SPEAKER_COLORS.get(entry.speaker_id, Color("8a8f8a"))
	_text_label.text = entry.text

	if not entry.sound_cue.is_empty():
		AudioManager.play_sfx(entry.sound_cue)

	for child in _choices_box.get_children():
		child.queue_free()

	if entry.branching_options.size() > 0:
		_continue_button.visible = false
		_choices_box.visible = true
		for option in entry.branching_options:
			var btn := Button.new()
			btn.text = String(option.get("text", "..."))
			btn.custom_minimum_size = Vector2(0, 56)
			btn.pressed.connect(_on_choice_selected.bind(option))
			_choices_box.add_child(btn)
	else:
		_choices_box.visible = false
		_continue_button.visible = true
		_continue_button.text = "Continue" if not entry.next_id.is_empty() else "Done"

func _on_continue_pressed() -> void:
	var entry := DialogueManager.get_entry(_current_id)
	if entry == null or entry.next_id.is_empty():
		_finish()
		return
	_show_entry(entry.next_id)

func _on_choice_selected(option: Dictionary) -> void:
	_apply_option_effects(option)
	var next_id := String(option.get("next_id", ""))
	if next_id.is_empty() or not DialogueManager.has_entry(next_id):
		_finish()
		return
	_show_entry(next_id)

func _apply_option_effects(option: Dictionary) -> void:
	var reward: Dictionary = option.get("reward", {})
	if reward.has("coins"):
		GameManager.add_coins(int(reward.coins))
	if reward.has("xp"):
		GameManager.add_xp(int(reward.xp))
	if reward.has("energy"):
		GameManager.add_energy(int(reward.energy))

	var relationship_changes: Dictionary = option.get("relationship_changes", {})
	for key in relationship_changes:
		GameManager.set_story_flag(String(key), relationship_changes[key])

func _finish() -> void:
	EventBus.dialogue_finished.emit(_current_id)
	SceneRouter.go_to(_return_scene_key, {}, false)
