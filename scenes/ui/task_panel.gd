extends CanvasLayer
class_name TaskPanel
const MotionFXScript = preload("res://scripts/vfx/motion_fx.gd")
## Task popup: name, description, required item (with an owned/needed
## count), a button that routes to the Merge Board with the right chain
## highlighted ("Find on Board" - spec section 19), and Complete once the
## requirement is met. Used for Haven hotspot repairs (show_for_hotspot)
## and, since Phase 6, survivor personal quests (show_for_quest) - both
## are just QuestDefinition underneath.

signal completed(hotspot_id: String)

@onready var _scrim: ColorRect = %Scrim
@onready var _title_label: Label = %TitleLabel
@onready var _desc_label: Label = %DescLabel
@onready var _icon: ItemView = %RequirementIcon
@onready var _requirement_label: Label = %RequirementLabel
@onready var _reward_label: Label = %RewardLabel
@onready var _find_button: Button = %FindButton
@onready var _complete_button: Button = %CompleteButton
@onready var _close_button: Button = %CloseButton

var _quest_id: String = ""

func _ready() -> void:
	layer = 92
	visible = false
	$CenterContainer.theme = get_window().theme
	$CenterContainer/Panel.theme_type_variation = "CreamPanel"
	_title_label.add_theme_font_override("font", ThemeFactory.display_font())
	for label in [_title_label, _desc_label, _requirement_label, _reward_label]:
		label.add_theme_color_override("font_color", Color("2a2825"))
	_scrim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			hide_panel()
	)
	_close_button.pressed.connect(hide_panel)
	_find_button.pressed.connect(_on_find_pressed)
	_complete_button.pressed.connect(_on_complete_pressed)

func show_for_hotspot(hotspot_id: String, residence_id: String = "hollow_creek_farmhouse") -> void:
	var quest := ResidenceManager.get_active_quest_for_hotspot(hotspot_id, residence_id)
	if quest == null:
		EventBus.show_toast.emit("Already repaired.")
		return
	_show_quest(quest)

## For quests not tied to a hotspot (e.g. a survivor's personal quest) -
## same panel, same Complete/Find-on-Board flow, just reached a different
## way. Completion still emits `completed` with an empty hotspot_id;
## callers that only care about hotspots already handle that as a no-op.
func show_for_quest(quest_id: String) -> void:
	var quest := ResidenceManager.get_quest(quest_id)
	if quest == null or ResidenceManager.is_quest_complete(quest_id):
		EventBus.show_toast.emit("Nothing more to do here.")
		return
	_show_quest(quest)

func _show_quest(quest: QuestDefinition) -> void:
	_quest_id = quest.id

	_title_label.text = quest.title
	_desc_label.text = quest.description

	var item_id: String = quest.requirements.keys()[0]
	var needed: int = int(quest.requirements[item_id])
	var owned: int = BoardState.count_item(item_id)
	var def := ItemDatabase.get_item(item_id)

	_icon.preview_item_id = item_id
	_requirement_label.text = "%s: %d / %d" % [def.display_name if def else item_id, owned, needed]

	var reward_parts: Array[String] = []
	if quest.rewards.has("coins"):
		reward_parts.append("+%d coins" % int(quest.rewards.coins))
	if quest.rewards.has("xp"):
		reward_parts.append("+%d XP" % int(quest.rewards.xp))
	if quest.rewards.has("unlock_survivor"):
		reward_parts.append("a new survivor")
	_reward_label.text = "Reward: " + ", ".join(reward_parts)

	_complete_button.disabled = owned < needed
	visible = true
	AudioManager.play_sfx("modal_open")
	MotionFXScript.reveal($CenterContainer, Vector2(0, 22), 0.24)
	MotionFXScript.pulse(_icon, Color("e8b93d"), 1)

func hide_panel() -> void:
	AudioManager.play_sfx("modal_close")
	$CenterContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MotionFXScript.dismiss($CenterContainer, Vector2(0, 18), 0.15, func():
		visible = false
		$CenterContainer.mouse_filter = Control.MOUSE_FILTER_PASS
	)
	_quest_id = ""

func _on_find_pressed() -> void:
	var quest := ResidenceManager.get_quest(_quest_id)
	if quest == null:
		return
	var item_id: String = quest.requirements.keys()[0]
	var def := ItemDatabase.get_item(item_id)
	hide_panel()
	SceneRouter.go_to("merge_board", {"highlight_chain_id": def.chain_id if def else ""})

func _on_complete_pressed() -> void:
	var quest := ResidenceManager.get_quest(_quest_id)
	var dialogue_id: String = quest.dialogue_trigger_id if quest != null else ""
	var result := ResidenceManager.try_complete_quest(_quest_id)
	if not result.success:
		AudioManager.play_sfx("error")
		EventBus.show_toast.emit("Not enough materials yet.")
		hide_panel()
		return

	hide_panel()
	if not dialogue_id.is_empty():
		# Skip the on-screen repair burst here - we're leaving Haven for the
		# dialogue scene immediately, so there's no time to see it play.
		# The burst still plays for every other hotspot; this one gets a
		# proper scene instead as its payoff.
		DialogueManager.start_dialogue(dialogue_id)
	else:
		completed.emit(result.hotspot_id)
		EventBus.show_toast.emit("Repaired!")
