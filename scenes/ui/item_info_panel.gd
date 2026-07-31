extends CanvasLayer
class_name ItemInfoPanel
## Combined tap-for-info / long-press-for-detail panel (spec: the two are
## the same content, "detail" just also exposes Collect/Store/Delete
## actions - a plain tap only needs to be non-destructive at a glance).

signal changed()

@onready var _scrim: ColorRect = %Scrim
@onready var _icon: ItemView = %IconPreview
@onready var _name_label: Label = %NameLabel
@onready var _desc_label: Label = %DescLabel
@onready var _meta_label: Label = %MetaLabel
@onready var _collect_button: Button = %CollectButton
@onready var _storage_button: Button = %StorageButton
@onready var _delete_button: Button = %DeleteButton
@onready var _close_button: Button = %CloseButton
@onready var _confirm_dialog: ConfirmationDialog = %ConfirmDialog

var _instance_id: String = ""

func _ready() -> void:
	layer = 92
	visible = false
	$CenterContainer.theme = get_window().theme
	$CenterContainer/Panel.theme_type_variation = "CreamPanel"
	_name_label.add_theme_font_override("font", ThemeFactory.display_font())
	for label in [_name_label, _desc_label, _meta_label]:
		label.add_theme_color_override("font_color", ThemeFactory.CHARCOAL_LIGHT)
	_collect_button.theme_type_variation = "OliveButton"
	_storage_button.theme_type_variation = "RustButton"
	_delete_button.theme_type_variation = "DangerButton"
	_close_button.theme_type_variation = "NavButton"
	_scrim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			hide_panel()
	)
	_close_button.pressed.connect(hide_panel)
	_collect_button.pressed.connect(_on_collect_pressed)
	_storage_button.pressed.connect(_on_storage_toggle_pressed)
	_delete_button.pressed.connect(_on_delete_pressed)
	_confirm_dialog.confirmed.connect(_do_delete)

func show_for(instance_id: String, detailed: bool) -> void:
	if not BoardState.items.has(instance_id):
		return
	_instance_id = instance_id
	var board_item: BoardItem = BoardState.items[instance_id]
	var def := ItemDatabase.get_item(board_item.item_id)
	if def == null:
		return

	_icon.instance_id = instance_id
	_icon.queue_redraw()
	_name_label.text = def.display_name
	_desc_label.text = def.description
	var rarity_name: String = ["Common", "Uncommon", "Rare", "Story"][def.rarity]
	if def.is_producer:
		_meta_label.text = "%s producer - %s" % [rarity_name, _chain_category(def.chain_id)]
	else:
		_meta_label.text = "%s - Level %d of %d - Sell %d coins" % [rarity_name, def.level, def.max_level_in_chain, def.sell_value]

	var chain := ItemDatabase.get_chain(def.chain_id)
	var is_reward: bool = chain.get("is_reward_chain", false)

	_collect_button.visible = detailed and is_reward
	if _collect_button.visible:
		var amount: int = def.level * int(chain.get("per_level_value", 0))
		_collect_button.text = "Collect (+%d %s)" % [amount, String(chain.get("resource", ""))]

	_storage_button.visible = detailed and not def.is_producer and not is_reward
	if _storage_button.visible:
		if board_item.is_on_board():
			_storage_button.text = "Move to Storage"
			_storage_button.disabled = BoardState.storage_order.size() >= BoardState.storage_capacity
		else:
			_storage_button.text = "Move to Board"
			_storage_button.disabled = BoardState.find_empty_cell().x < 0

	_delete_button.visible = detailed and BoardState.can_delete(instance_id)

	visible = true

func hide_panel() -> void:
	visible = false
	_instance_id = ""

func _chain_category(chain_id: String) -> String:
	return String(ItemDatabase.get_chain(chain_id).get("category", chain_id))

func _on_collect_pressed() -> void:
	if BoardState.collect_reward(_instance_id):
		EventBus.show_toast.emit("Collected.")
	hide_panel()
	changed.emit()

func _on_storage_toggle_pressed() -> void:
	var board_item: BoardItem = BoardState.items.get(_instance_id)
	if board_item == null:
		return
	var ok: bool
	if board_item.is_on_board():
		ok = BoardState.move_to_storage(_instance_id)
	else:
		ok = BoardState.move_to_cell(_instance_id, BoardState.find_empty_cell())
	if not ok:
		EventBus.show_toast.emit("No space available.")
	hide_panel()
	changed.emit()

func _on_delete_pressed() -> void:
	if BoardState.requires_delete_confirmation(_instance_id):
		_confirm_dialog.popup_centered()
	else:
		_do_delete()

func _do_delete() -> void:
	var deleted_id := _instance_id
	if BoardState.soft_delete(deleted_id):
		EventBus.show_toast.emit("Deleted.")
	hide_panel()
	changed.emit()
