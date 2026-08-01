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
	"imogen_shaw": "Dr Imogen Shaw",
	"caleb_rusk": "Caleb Rusk",
}
const EVENT_LABELS := {
	"hollow_creek_first_wave": "The First Night",
	"redwater_defence": "Defend the Station",
	"greybridge_defence": "Defend the School",
	"saint_mercy_defence": "Defend the Hospital",
	"northgate_defence": "Defend the Prison",
}
const ENCOUNTER_INTROS := {
	"hollow_creek_first_wave": "Night falls, and they come from the treeline. What now?",
	"redwater_defence": "Movement at the fence line as the light fades. What now?",
	"greybridge_defence": "They're coming across the playground as the light dies. What now?",
	"saint_mercy_defence": "Movement in the car park as the emergency lights flicker. What now?",
	"northgate_defence": "Movement along the perimeter wall as the light dies. What now?",
}
const EVENT_BACKGROUNDS := {
	"hollow_creek_first_wave": "res://assets/art/hollow_creek/environments/runtime/hollow_creek_state_04_defended.png",
	"redwater_defence": "res://assets/art/redwater/runtime/redwater_state_05_defended.jpg",
	"greybridge_defence": "res://assets/art/greybridge/runtime/greybridge_state_05_defended.jpg",
	"saint_mercy_defence": "res://assets/art/saint_mercy/runtime/saint_mercy_state_05_defended.jpg",
	"northgate_defence": "res://assets/art/northgate/runtime/northgate_state_05_defended.jpg",
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
@onready var _scene_art: TextureRect = %SceneArt
@onready var _combat_stage: Control = %CombatStage

var _event_id: String = ""
var _return_scene_key: String = "haven"
var _selected_survivor_id: String = ""
var _shared_group: ButtonGroup
var _survivor_rig: LayeredCharacterRig
var _hollow_rig: LayeredCharacterRig
var _impact_particles: CPUParticles2D

func _ready() -> void:
	AudioManager.play_music("defence_preparation")
	AudioManager.play_ambience("distant_hollow")
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
	_scene_art.texture = load(String(EVENT_BACKGROUNDS.get(_event_id, EVENT_BACKGROUNDS.hollow_creek_first_wave)))
	_scene_art.pivot_offset = _scene_art.size * 0.5

	for survivor_id in GameManager.get_unlocked_survivor_ids():
		var btn := Button.new()
		btn.text = SURVIVOR_NAMES.get(survivor_id, survivor_id)
		btn.icon = load("res://assets/art/characters/%s/portraits/determined.png" % survivor_id)
		btn.add_theme_constant_override("icon_max_width", 46)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(0, 62)
		btn.button_group = _survivor_group()
		btn.pressed.connect(_select_survivor.bind(survivor_id))
		_survivor_box.add_child(btn)
		if _selected_survivor_id.is_empty():
			_selected_survivor_id = survivor_id
			btn.button_pressed = true

	_send_button.pressed.connect(_on_send_pressed)
	_return_button.pressed.connect(func(): SceneRouter.go_to(_return_scene_key, {}, false))
	var event: Dictionary = DefenceManager.events.get(_event_id, {})
	_send_button.text = "Prepare  •  %d energy" % int(event.get("energy_cost", 0))
	_build_combat_stage()
	call_deferred("_layout_combat_stage")
	resized.connect(_layout_combat_stage)

func _survivor_group() -> ButtonGroup:
	if _shared_group == null:
		_shared_group = ButtonGroup.new()
	return _shared_group

func _select_survivor(survivor_id: String) -> void:
	_selected_survivor_id = survivor_id
	_build_survivor_rig()
	if _survivor_rig != null:
		_survivor_rig.play_state("idle_breathing")

func _build_combat_stage() -> void:
	_build_survivor_rig()
	_hollow_rig = LayeredCharacterRig.new()
	_hollow_rig.name = "DrifterHollow"
	_hollow_rig.character_id = "drifter_hollow"
	_hollow_rig.hollow = true
	_hollow_rig.display_height = 245.0
	_hollow_rig.modulate = Color(0.72, 0.78, 0.80, 0.94)
	_combat_stage.add_child(_hollow_rig)
	_build_impact_particles()

func _build_survivor_rig() -> void:
	if _selected_survivor_id.is_empty():
		return
	if _survivor_rig != null:
		_survivor_rig.queue_free()
	_survivor_rig = LayeredCharacterRig.new()
	_survivor_rig.name = "SelectedSurvivor"
	_survivor_rig.character_id = _selected_survivor_id
	_survivor_rig.display_height = 285.0
	_survivor_rig.modulate = Color(1.04, 1.0, 0.92, 1.0)
	_combat_stage.add_child(_survivor_rig)
	_layout_combat_stage()

func _build_impact_particles() -> void:
	_impact_particles = CPUParticles2D.new()
	_impact_particles.name = "ImpactParticles"
	_impact_particles.amount = 26
	_impact_particles.one_shot = true
	_impact_particles.explosiveness = 0.9
	_impact_particles.lifetime = 0.65
	_impact_particles.direction = Vector2(0, -1)
	_impact_particles.spread = 62.0
	_impact_particles.gravity = Vector2(0, 190)
	_impact_particles.initial_velocity_min = 65.0
	_impact_particles.initial_velocity_max = 145.0
	_impact_particles.scale_amount_min = 0.04
	_impact_particles.scale_amount_max = 0.11
	_impact_particles.color = Color(0.84, 0.58, 0.27, 0.86)
	_impact_particles.texture = load("res://assets/ui/hollow_creek/particle_soft.png")
	_combat_stage.add_child(_impact_particles)

func _layout_combat_stage() -> void:
	if _survivor_rig != null:
		_survivor_rig.position = Vector2(size.x * 0.30, size.y * 0.79)
	if _hollow_rig != null:
		_hollow_rig.position = Vector2(size.x * 0.75, size.y * 0.79)
	if _impact_particles != null:
		_impact_particles.position = Vector2(size.x * 0.54, size.y * 0.81)

func _on_send_pressed() -> void:
	var result := DefenceManager.launch(_event_id, _selected_survivor_id)
	if not result.success:
		AudioManager.play_sfx("error")
		EventBus.show_toast.emit("Not enough energy to prepare.")
		return
	AudioManager.play_sfx("defence_warning")
	AudioManager.play_music("defence")
	_play_encounter_transition()
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
		btn.theme_type_variation = "RustButton"
		btn.pressed.connect(_on_choice_pressed.bind(i))
		_choices_box.add_child(btn)
		if GameManager.effects_enabled():
			btn.modulate.a = 0.0
			btn.create_tween().tween_property(btn, "modulate:a", 1.0, 0.22).set_delay(0.06 * float(i))

func _on_choice_pressed(choice_index: int) -> void:
	AudioManager.play_sfx("barricade_impact")
	var result := DefenceManager.resolve_choice(_event_id, choice_index, _selected_survivor_id)
	_encounter_panel.visible = false
	_outcome_panel.visible = true
	var prefix: String = "You made it through. " if result.outcome_success else "It was close. "
	_outcome_label.text = prefix + String(result.text)
	_play_outcome(bool(result.outcome_success))

func _play_encounter_transition() -> void:
	if _survivor_rig != null:
		_survivor_rig.play_state("defensive_action")
	if _hollow_rig != null:
		_hollow_rig.play_state("detect_target")
	if not GameManager.effects_enabled():
		return
	var original := _scene_art.position
	var tween := _scene_art.create_tween()
	tween.tween_property(_scene_art, "position", original + Vector2(-4, 1), 0.06)
	tween.tween_property(_scene_art, "position", original + Vector2(4, -1), 0.06)
	tween.tween_property(_scene_art, "position", original, 0.08)
	if _impact_particles != null:
		_impact_particles.restart()

func _play_outcome(success: bool) -> void:
	if _survivor_rig != null:
		_survivor_rig.play_state("celebration" if success else "injured_idle")
	if _hollow_rig != null:
		_hollow_rig.play_state("collapse" if success else "attack_barricade")
	if _impact_particles != null and GameManager.effects_enabled():
		_impact_particles.color = Color(0.93, 0.72, 0.31, 0.92) if success else Color(0.68, 0.18, 0.12, 0.82)
		_impact_particles.restart()
	if GameManager.effects_enabled():
		_outcome_panel.modulate.a = 0.0
		_outcome_panel.create_tween().tween_property(_outcome_panel, "modulate:a", 1.0, 0.32)
