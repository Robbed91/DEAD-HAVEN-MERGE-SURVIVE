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
const BACKGROUNDS := {
	"intro": "res://assets/concepts/vertical_slice/dialogue/intro_farmhouse_approach_concept.png",
	"noah": "res://assets/art/hollow_creek/environments/runtime/hollow_creek_state_03_habitable.png",
	"lena": "res://assets/art/redwater/runtime/redwater_state_03_temporary.jpg",
	"riley": "res://assets/art/greybridge/runtime/greybridge_state_03_temporary.jpg",
	"imogen": "res://assets/art/saint_mercy/runtime/saint_mercy_state_03_temporary.jpg",
	"caleb": "res://assets/art/northgate/runtime/northgate_state_03_temporary.jpg",
	"signal_keeper": "res://assets/art/scavenging/runtime/radio_relay_station.png",
}
const LOCATION_NAMES := {
	"intro": "HOLLOW CREEK — FARMHOUSE APPROACH",
	"noah": "HOLLOW CREEK — WEST FIELD",
	"lena": "REDWATER — SERVICE WORKSHOP",
	"riley": "GREYBRIDGE — SCHOOL HALL",
	"imogen": "SAINT MERCY — EMERGENCY WARD",
	"caleb": "NORTHGATE — CELL BLOCK",
	"signal_keeper": "HAVEN SEVEN — NIGHT TRANSMISSION",
}
const SIGNAL_KEEPER_ART := "res://assets/ui/world_map/markers/runtime/radio_relay_station.png"

@onready var _portrait: SurvivorSilhouette = %Portrait
@onready var _speaker_label: Label = %SpeakerLabel
@onready var _text_label: Label = %TextLabel
@onready var _continue_button: Button = %ContinueButton
@onready var _choices_box: VBoxContainer = %ChoicesBox
@onready var _scene_art: TextureRect = %SceneArt
@onready var _location_label: Label = %LocationLabel
@onready var _portrait_margin: MarginContainer = %PortraitMargin
@onready var _text_panel: PanelContainer = %TextPanel

var _current_id: String = ""
var _return_scene_key: String = "haven"

func _ready() -> void:
	AudioManager.set_dialogue_active(true)
	$Layout/Row/TextPanel.theme_type_variation = "DialoguePanel"
	_speaker_label.add_theme_font_override("font", ThemeFactory.display_font())
	_speaker_label.add_theme_color_override("font_color", ThemeFactory.RUST_DARK)
	_text_label.add_theme_color_override("font_color", ThemeFactory.CHARCOAL_LIGHT)
	_continue_button.theme_type_variation = "OliveButton"
	_scene_art.pivot_offset = _scene_art.size * 0.5
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
	_update_scene_art(id)

	var has_speaker: bool = not entry.speaker_id.is_empty()
	_speaker_label.visible = has_speaker
	_speaker_label.text = SPEAKER_NAMES.get(entry.speaker_id, entry.speaker_id)
	_portrait.visible = has_speaker
	_portrait_margin.visible = has_speaker
	_portrait.silhouette_color = SPEAKER_COLORS.get(entry.speaker_id, Color("8a8f8a"))
	_portrait.survivor_id = entry.speaker_id
	_portrait.set_override_texture(SIGNAL_KEEPER_ART if entry.speaker_id == "signal_keeper" else "")
	_portrait.expression = _expression_for_entry(entry)
	if _portrait.expression in ["injured", "relieved", "exhausted"]:
		AudioManager.play_music("emotional")
	_portrait.play_state("fear" if _portrait.expression == "afraid" else ("injured" if _portrait.expression == "injured" else "speaking"))
	_text_label.text = entry.text
	_play_entry_reveal(has_speaker)
	if entry.speaker_id == "mara_vale" or entry.speaker_id == "noah_vance":
		AudioManager.play_sfx("dialogue_radio" if entry.speaker_id == "mara_vale" and _current_id.begins_with("intro") else "ui_tap")

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
			btn.theme_type_variation = "RustButton"
			btn.pressed.connect(_on_choice_selected.bind(option))
			_choices_box.add_child(btn)
			if GameManager.effects_enabled():
				btn.modulate.a = 0.0
				var choice_tween := btn.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				choice_tween.tween_property(btn, "modulate:a", 1.0, 0.22).set_delay(0.07 * float(btn.get_index()))
	else:
		_choices_box.visible = false
		_continue_button.visible = true
		_continue_button.text = "Continue" if not entry.next_id.is_empty() else "Done"

func _expression_for_entry(entry: DialogueEntry) -> String:
	# Use the existing authored key. Historical data used two labels that do
	# not have dedicated portrait exports, so they map to the nearest approved
	# expression without changing the dialogue resource.
	var authored: String = entry.expression_key
	if authored == "suspicious":
		return "concerned"
	if authored == "defensive":
		return "angry"
	if authored in ["neutral", "concerned", "angry", "afraid", "relieved", "injured", "exhausted", "determined"]:
		return authored
	return "neutral"

func _sequence_key(id: String) -> String:
	for raw_key in BACKGROUNDS:
		var key: String = raw_key
		if id.begins_with("%s_" % key):
			return key
	return "intro"

func _update_scene_art(id: String) -> void:
	var key: String = _sequence_key(id)
	var path: String = BACKGROUNDS[key]
	if _scene_art.texture == null or _scene_art.texture.resource_path != path:
		_scene_art.texture = load(path)
		if GameManager.effects_enabled():
			_scene_art.modulate = Color(0.48, 0.52, 0.56, 0.0)
			_scene_art.scale = Vector2(1.025, 1.025)
			var scene_tween := _scene_art.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			scene_tween.tween_property(_scene_art, "modulate", Color(0.72, 0.76, 0.80, 0.82), 0.44)
			scene_tween.tween_property(_scene_art, "scale", Vector2.ONE, 1.8)
		else:
			_scene_art.modulate = Color(0.72, 0.76, 0.80, 0.82)
			_scene_art.scale = Vector2.ONE
	_location_label.text = LOCATION_NAMES[key]

func _play_entry_reveal(has_speaker: bool) -> void:
	_text_label.visible_ratio = 1.0
	_text_panel.modulate = Color.WHITE
	if not GameManager.effects_enabled():
		return
	_text_panel.modulate.a = 0.0
	_text_label.visible_ratio = 0.0
	var panel_tween := _text_panel.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	panel_tween.tween_property(_text_panel, "modulate:a", 1.0, 0.24)
	panel_tween.tween_property(_text_label, "visible_ratio", 1.0, clampf(_text_label.text.length() * 0.012, 0.35, 1.15))
	if has_speaker:
		_portrait.modulate.a = 0.0
		_portrait.scale = Vector2(0.94, 0.94)
		_portrait.pivot_offset = _portrait.size * 0.5
		var portrait_tween := _portrait.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		portrait_tween.tween_property(_portrait, "modulate:a", 1.0, 0.24)
		portrait_tween.tween_property(_portrait, "scale", Vector2.ONE, 0.36)

func _on_continue_pressed() -> void:
	AudioManager.play_sfx("dialogue_advance")
	var entry := DialogueManager.get_entry(_current_id)
	if entry == null or entry.next_id.is_empty():
		_finish()
		return
	_show_entry(entry.next_id)

func _on_choice_selected(option: Dictionary) -> void:
	AudioManager.play_sfx("dialogue_choice")
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
	AudioManager.set_dialogue_active(false)
	EventBus.dialogue_finished.emit(_current_id)
	SceneRouter.go_to(_return_scene_key, {}, false)
