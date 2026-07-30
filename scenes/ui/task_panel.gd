extends CanvasLayer
class_name TaskPanel
## Repair-task popup shown when a Haven hotspot is tapped: task name,
## description, required item (with an owned/needed count), a button that
## routes to the Merge Board with the right chain highlighted ("Find on
## Board" - spec section 19), and Complete once the requirement is met.

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
	_scrim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			hide_panel()
	)
	_close_button.pressed.connect(hide_panel)
	_find_button.pressed.connect(_on_find_pressed)
	_complete_button.pressed.connect(_on_complete_pressed)

func show_for_hotspot(hotspot_id: String) -> void:
	var quest := ResidenceManager.get_active_quest_for_hotspot(hotspot_id)
	if quest == null:
		EventBus.show_toast.emit("Already repaired.")
		return
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

func hide_panel() -> void:
	visible = false
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
	var result := ResidenceManager.try_complete_quest(_quest_id)
	if result.success:
		EventBus.show_toast.emit("Repaired!")
		completed.emit(result.hotspot_id)
	else:
		EventBus.show_toast.emit("Not enough materials yet.")
	hide_panel()
