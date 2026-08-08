extends Control
## Scavenging
##
## Existing synchronous mission flow with a state-neutral illustrated
## presentation layer. ScavengingManager remains the sole gameplay authority.

const SURVIVOR_NAMES := {
	"mara_vale": "Mara Vale",
	"noah_vance": "Noah Vance",
	"lena_ortiz": "Lena Ortiz",
	"riley_chen": "Riley Chen",
	"imogen_shaw": "Dr Imogen Shaw",
	"caleb_rusk": "Caleb Rusk",
}

const LOCATION_ART_ROOT := "res://assets/art/scavenging/runtime/"
const SURVIVOR_ART_ROOT := "res://assets/art/characters/"
const LOCATION_CAPTIONS := {
	"abandoned_grocery_store": "Broken glass, stocked shelves, and movement beyond the loading bay.",
	"clothing_outlet": "Exposed racks offer useful layers; the sealed stockroom may hold more.",
	"electronics_workshop": "Quiet benches and intact equipment make every loose cable worth checking.",
	"farm_shed": "Rotten doors shelter timber, hand tools, and a dangerously quiet workbench.",
	"medical_clinic": "The pharmacy is still stocked, but the grounds are crowded with the dead.",
	"petrol_station": "Fuel remains below the forecourt while an abandoned truck tempts a longer search.",
	"police_checkpoint": "The barricades were arranged deliberately. Whoever built them may still be near.",
	"radio_relay_station": "The relay is alive enough to broadcast—and perhaps to reveal who is listening.",
	"roadside_wreck": "The trunk is easy salvage. The exposed engine is valuable enough to risk the trees.",
	"warehouse_depot": "Sealed pallets fill the loading bays; the office catwalk offers a dangerous overview.",
}
const LOCATION_AMBIENCE := {
	"abandoned_grocery_store": ["abandoned_building", "rain"],
	"clothing_outlet": ["abandoned_building", "wind"],
	"electronics_workshop": ["abandoned_building", "electrical_hum"],
	"farm_shed": ["forest", "wind"],
	"medical_clinic": ["rain", "distant_hollow"],
	"petrol_station": ["redwater_station", "road"],
	"police_checkpoint": ["road", "wind"],
	"radio_relay_station": ["wind", "electrical_hum"],
	"roadside_wreck": ["road", "forest"],
	"warehouse_depot": ["abandoned_building", "distant_hollow"],
}

@onready var _title_label: Label = %TitleLabel
@onready var _flavor_label: Label = %FlavorLabel
@onready var _survivor_box: GridContainer = %SurvivorBox
@onready var _send_button: Button = %SendButton
@onready var _encounter_label: Label = %EncounterLabel
@onready var _choices_box: VBoxContainer = %ChoicesBox
@onready var _outcome_label: Label = %OutcomeLabel
@onready var _return_button: Button = %ReturnButton
@onready var _hero_panel: PanelContainer = %HeroPanel
@onready var _hero_image: TextureRect = %HeroImage
@onready var _hero_tint: ColorRect = %HeroTint
@onready var _survivor_portrait: TextureRect = %SurvivorPortrait
@onready var _phase_badge: Label = %PhaseBadge
@onready var _threat_badge: Label = %ThreatBadge
@onready var _hero_caption: Label = %HeroCaption
@onready var _challenge_panel: VBoxContainer = %MergeChallengePanel
@onready var _challenge_label: Label = %ChallengeLabel
@onready var _challenge_grid: GridContainer = %ChallengeGrid
@onready var _retreat_button: Button = %RetreatButton

var _mission_id := ""
var _selected_survivor_id := ""
var _shared_group: ButtonGroup
var _danger_overlay: DangerOverlay
var _state_tween: Tween
var _ambient_tween: Tween
var _challenge_state: ScavengeMergeState
var _challenge_cells: Dictionary = {} # Vector2i -> ScavengeCell
var _pending_choice_index := -1

func _ready() -> void:
	AudioManager.play_music("scavenging")
	var params := SceneRouter.take_pending_params()
	_mission_id = String(params.get("mission_id", ""))
	var mission := ScavengingManager.get_mission(_mission_id)
	if mission == null or not ScavengingManager.is_available(_mission_id):
		if get_tree().current_scene == self:
			EventBus.show_toast.emit("That location isn't available.")
			SceneRouter.go_to("world_map", {}, false)
		return

	_danger_overlay = DangerOverlay.new()
	add_child(_danger_overlay)
	_configure_location(mission)
	_title_label.text = mission.location_name
	_flavor_label.text = "Danger %d/5  •  Hollow threat %d  •  Human threat %d  •  Noise %d  •  Energy %d" % [
		mission.danger_rating, mission.zombie_threat, mission.human_threat, mission.noise_level, mission.energy_cost,
	]

	for survivor_id in GameManager.get_unlocked_survivor_ids():
		var btn := Button.new()
		btn.name = "%sChoice" % survivor_id.to_pascal_case()
		btn.text = SURVIVOR_NAMES.get(survivor_id, survivor_id)
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(0, 50)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.theme_type_variation = "NavButton"
		btn.button_group = _survivor_group()
		btn.pressed.connect(_select_survivor.bind(survivor_id, btn))
		_survivor_box.add_child(btn)
		if _selected_survivor_id.is_empty():
			_selected_survivor_id = survivor_id
			btn.button_pressed = true

	if not _selected_survivor_id.is_empty():
		_update_survivor_portrait(_selected_survivor_id, false)
	_send_button.pressed.connect(_on_send_pressed)
	_retreat_button.pressed.connect(func(): _resolve_challenge(false))
	_return_button.pressed.connect(func(): SceneRouter.go_to("world_map", {}, false))
	visibility_changed.connect(_on_visibility_changed)
	call_deferred("_begin_ambient_motion")

## Danger presentation only - reads the mission's own existing
## danger_rating/human_threat rather than inventing a new signal, and only
## shows a gas cloud for the one real fuel/petrol location in the current
## roster. Never changes danger_rating, human_threat, or resolve odds.
func _apply_danger_presentation(mission) -> void:
	var intensity := 0.0
	if mission.danger_rating >= 3:
		intensity = maxf(intensity, float(mission.danger_rating) / 5.0)
	if mission.human_threat > 0:
		intensity = maxf(intensity, 0.35 + float(mission.human_threat) / 10.0)
	var gas_cloud := _mission_id == "petrol_station"
	_danger_overlay.set_danger(intensity, gas_cloud)

func _configure_location(mission) -> void:
	var art_path := LOCATION_ART_ROOT + _mission_id + ".png"
	if ResourceLoader.exists(art_path):
		_hero_image.texture = load(art_path)
	else:
		push_warning("Scavenging presentation missing location art: %s" % art_path)
	_hero_caption.text = String(LOCATION_CAPTIONS.get(_mission_id, "Assess the approach before committing a survivor."))
	_threat_badge.text = "THREAT %d / 5" % mission.danger_rating
	_phase_badge.text = "ROUTE ASSESSMENT"
	var ambience: Array = LOCATION_AMBIENCE.get(_mission_id, ["forest", "wind"])
	AudioManager.play_ambience(String(ambience[0]))
	AudioManager.play_ambience_layer(String(ambience[1]), -18.0)
	_apply_danger_presentation(mission)

func _survivor_group() -> ButtonGroup:
	if _shared_group == null:
		_shared_group = ButtonGroup.new()
	return _shared_group

func _select_survivor(survivor_id: String, button: Button) -> void:
	_selected_survivor_id = survivor_id
	button.button_pressed = true
	_update_survivor_portrait(survivor_id, true)

func _update_survivor_portrait(survivor_id: String, animate: bool) -> void:
	var path := SURVIVOR_ART_ROOT + survivor_id + "/poses/scavenging.png"
	if not ResourceLoader.exists(path):
		_survivor_portrait.visible = false
		return
	_survivor_portrait.texture = load(path)
	_survivor_portrait.visible = true
	if not animate or not _effects_allowed():
		_survivor_portrait.modulate.a = 1.0
		_survivor_portrait.scale = Vector2.ONE
		return
	_survivor_portrait.modulate.a = 0.35
	_survivor_portrait.scale = Vector2(0.97, 0.97)
	var tween := _survivor_portrait.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_survivor_portrait, "modulate:a", 1.0, 0.18)
	tween.tween_property(_survivor_portrait, "scale", Vector2.ONE, 0.22)

func _on_send_pressed() -> void:
	var result := ScavengingManager.launch_mission(_mission_id)
	if not result.success:
		AudioManager.play_sfx("error")
		EventBus.show_toast.emit("Not enough energy to send anyone out.")
		_shake_panel()
		return
	AudioManager.play_sfx("scavenge_launch")
	_show_encounter()

func _show_encounter() -> void:
	%PrepPanel.visible = false
	%OutcomePanel.visible = false
	%EncounterPanel.visible = true
	var mission := ScavengingManager.get_mission(_mission_id)
	_encounter_label.text = "%s reaches %s. Choose the approach." % [SURVIVOR_NAMES.get(_selected_survivor_id, _selected_survivor_id), mission.location_name]
	for child in _choices_box.get_children():
		child.queue_free()
	for i in mission.encounter_choices.size():
		var choice: Dictionary = mission.encounter_choices[i]
		var btn := Button.new()
		btn.text = String(choice.get("text", "..."))
		btn.custom_minimum_size = Vector2(0, 58)
		btn.theme_type_variation = "RustButton"
		btn.pressed.connect(_on_choice_pressed.bind(i))
		_choices_box.add_child(btn)
	_set_visual_phase("ENCOUNTER", Color(0.09, 0.13, 0.16, 0.24), "The route is committed. Noise and timing now decide the outcome.", %EncounterPanel)

## Success is no longer an instant dice roll - the player has to win a
## merge challenge to actually secure the location (see
## DEVELOPMENT_LOG.md 2026-08-05 "scavenging becomes a merge challenge").
## The chosen approach's own success_chance still matters - it sets how
## many moves the challenge allows via ScavengingManager.compute_challenge_params().
func _on_choice_pressed(choice_index: int) -> void:
	AudioManager.play_sfx("scavenge_search")
	_pending_choice_index = choice_index
	_begin_merge_challenge(choice_index)

func _begin_merge_challenge(choice_index: int) -> void:
	var params := ScavengingManager.compute_challenge_params(_mission_id, choice_index, _selected_survivor_id)
	var chain_ids: Array[String] = params.get("chain_ids", [])
	_challenge_state = ScavengeMergeState.new()
	_challenge_state.setup(chain_ids, int(params.get("moves", 6)), int(params.get("target_level", 3)))
	_build_challenge_grid()
	_refresh_challenge_label()
	%EncounterPanel.visible = false
	%OutcomePanel.visible = false
	_challenge_panel.visible = true
	_set_visual_phase("SALVAGE RUN", Color(0.15, 0.14, 0.11, 0.22), "Merge what you can find before the noise draws attention.", _challenge_panel)

func _build_challenge_grid() -> void:
	for child in _challenge_grid.get_children():
		child.queue_free()
	_challenge_cells.clear()
	for y in ScavengeMergeState.ROWS:
		for x in ScavengeMergeState.COLUMNS:
			var pos := Vector2i(x, y)
			var cell := ScavengeCell.new()
			cell.setup(pos)
			cell.drop_attempted.connect(_on_challenge_drop_attempted)
			_challenge_grid.add_child(cell)
			_challenge_cells[pos] = cell
	_refresh_challenge_cells()

func _refresh_challenge_cells() -> void:
	for pos in _challenge_cells:
		(_challenge_cells[pos] as ScavengeCell).refresh(_challenge_state.item_id_at(pos))

func _refresh_challenge_label() -> void:
	_challenge_label.text = "Merge up to level %d before you run out of moves - %d moves left" % [_challenge_state.target_level, _challenge_state.moves_left]

func _on_challenge_drop_attempted(from_pos: Vector2i, to_pos: Vector2i) -> void:
	if _challenge_state == null:
		return
	if _challenge_state.is_cell_free(to_pos):
		_challenge_state.move(from_pos, to_pos)
	else:
		var result := _challenge_state.try_merge(from_pos, to_pos)
		if result.get("success", false):
			AudioManager.play_sfx("merge_pull")
	_refresh_challenge_cells()
	_refresh_challenge_label()
	if _challenge_state.is_won():
		_resolve_challenge(true)
	elif _challenge_state.is_lost():
		_resolve_challenge(false)

func _resolve_challenge(succeeded: bool) -> void:
	if _pending_choice_index < 0:
		return
	var result := ScavengingManager.resolve_choice_with_outcome(_mission_id, _pending_choice_index, succeeded)
	_pending_choice_index = -1
	_challenge_state = null
	_challenge_panel.visible = false
	%OutcomePanel.visible = true
	var prefix: String = "Success. " if result.outcome_success else "It went sideways. "
	_outcome_label.text = prefix + String(result.text)
	if result.outcome_success:
		_set_visual_phase("SUPPLIES SECURED", Color(0.23, 0.31, 0.16, 0.2), "The survivor clears the location and secures the recovered supplies.", %OutcomePanel)
	else:
		_set_visual_phase("FORCED RETREAT", Color(0.34, 0.11, 0.08, 0.18), "The survivor breaks contact and withdraws before the route closes.", %OutcomePanel)

func _set_visual_phase(label: String, tint: Color, caption: String, panel: Control) -> void:
	_phase_badge.text = label
	_hero_tint.color = tint
	_hero_caption.text = caption
	_animate_panel_reveal(panel)

func _animate_panel_reveal(panel: Control) -> void:
	if _state_tween != null and _state_tween.is_valid():
		_state_tween.kill()
	panel.modulate.a = 1.0
	panel.position.x = 0.0
	if not _effects_allowed():
		return
	panel.modulate.a = 0.0
	panel.position.x = 12.0
	_state_tween = panel.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_state_tween.tween_property(panel, "modulate:a", 1.0, 0.22)
	_state_tween.tween_property(panel, "position:x", 0.0, 0.26)

func _shake_panel() -> void:
	if not _effects_allowed():
		return
	if _state_tween != null and _state_tween.is_valid():
		_state_tween.kill()
	var origin := _hero_panel.position.x
	_state_tween = _hero_panel.create_tween()
	_state_tween.tween_property(_hero_panel, "position:x", origin - 6.0, 0.045)
	_state_tween.tween_property(_hero_panel, "position:x", origin + 5.0, 0.06)
	_state_tween.tween_property(_hero_panel, "position:x", origin, 0.07)

func _begin_ambient_motion() -> void:
	if _ambient_tween != null and _ambient_tween.is_valid():
		_ambient_tween.kill()
	_hero_image.scale = Vector2.ONE
	if not _effects_allowed():
		return
	_hero_image.pivot_offset = _hero_image.size * 0.5
	_ambient_tween = _hero_image.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_ambient_tween.tween_property(_hero_image, "scale", Vector2(1.012, 1.012), 5.5)
	_ambient_tween.tween_property(_hero_image, "scale", Vector2.ONE, 5.5)

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		call_deferred("_begin_ambient_motion")
	elif _ambient_tween != null and _ambient_tween.is_valid():
		_ambient_tween.kill()

func _effects_allowed() -> bool:
	return is_visible_in_tree() and GameManager.effects_enabled()
