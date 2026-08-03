extends Control
## Survivors
##
## Phase 6: a real, SurvivorDefinition-backed roster. Unlocked survivors
## show their real biography/role/skills from data/characters/; locked
## ones retain concealed identity text while showing the final portrait under
## a dark lock treatment. Character definitions and unlock rules are unchanged.
## A card with an incomplete personal quest is tappable and opens the same
## TaskPanel Haven's hotspots use.

## Display order and unlock rule: Mara is always unlocked; everyone else
## checks GameManager.is_survivor_unlocked(id).
const SURVIVOR_IDS := ["mara_vale", "noah_vance", "lena_ortiz", "imogen_shaw", "riley_chen", "caleb_rusk"]
const SILHOUETTE_COLORS := {
	"mara_vale": Color("6b7a56"),
	"noah_vance": Color("8a3c1f"),
	"lena_ortiz": Color("4d5940"),
	"imogen_shaw": Color("6b4a35"),
	"riley_chen": Color("8a8f8a"),
	"caleb_rusk": Color("b5502b"),
}

@onready var _grid: GridContainer = %RosterGrid
@onready var _task_panel: TaskPanel = %TaskPanel

func _ready() -> void:
	_task_panel.find_requested.connect(func(chain_id: String):
		SceneRouter.go_to(SceneRouter.residence_scene_key(GameManager.profile.current_residence_id), {"highlight_chain_id": chain_id})
	)
	_task_panel.completed.connect(func(_hotspot_id): _rebuild())
	_rebuild()

func _rebuild() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for id in SURVIVOR_IDS:
		_grid.add_child(_build_card(id))

func _is_unlocked(id: String) -> bool:
	return id == "mara_vale" or GameManager.is_survivor_unlocked(id)

func _build_card(id: String) -> Control:
	var def := CharacterDatabase.get_survivor(id)
	var locked := not _is_unlocked(id)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 210)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.theme_type_variation = "LockedCard" if locked else "SurvivorCard"

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	var portrait := SurvivorSilhouette.new()
	portrait.custom_minimum_size = Vector2(88, 88)
	portrait.survivor_id = id
	portrait.silhouette_color = SILHOUETTE_COLORS.get(id, Color("8a8f8a"))
	portrait.locked = locked
	vbox.add_child(portrait)

	var name_label := Label.new()
	name_label.text = (def.display_name if def else id) if not locked else "???"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_override("font", ThemeFactory.display_font())
	name_label.add_theme_color_override("font_color", ThemeFactory.CREAM if locked else ThemeFactory.CHARCOAL_LIGHT)
	vbox.add_child(name_label)

	var role_label := Label.new()
	role_label.text = (def.role if def else "") if not locked else "Not yet found"
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.add_theme_color_override("font_color", ThemeFactory.CREAM if locked else ThemeFactory.CHARCOAL_LIGHT)
	role_label.modulate.a = 0.65
	role_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(role_label)

	if not locked and def != null:
		var skills_label := Label.new()
		skills_label.text = ", ".join(def.skills)
		skills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		skills_label.add_theme_color_override("font_color", ThemeFactory.CHARCOAL_LIGHT)
		skills_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		skills_label.modulate.a = 0.6
		skills_label.add_theme_font_size_override("font_size", 12)
		vbox.add_child(skills_label)

		var quest_id := def.personal_quest_id
		if not quest_id.is_empty() and not ResidenceManager.is_quest_complete(quest_id):
			var quest_button := Button.new()
			quest_button.text = "Personal Task"
			quest_button.custom_minimum_size = Vector2(0, 40)
			quest_button.theme_type_variation = "RustButton"
			quest_button.pressed.connect(func(): _task_panel.show_for_quest(quest_id))
			vbox.add_child(quest_button)

	return card
