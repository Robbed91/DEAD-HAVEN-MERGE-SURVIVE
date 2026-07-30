extends Control
## MergeBoard
##
## Phase 2: the real, playable merge board - grid drag-and-drop, merge
## rules, producers, energy, storage transfer, tap-for-info/long-press
## detail panels, and the chain-highlight legend (this phase's honest stand
## -in for "task highlighting", since real residence tasks don't exist
## until Phase 3 - see DEVELOPMENT_LOG.md).

const COLUMNS := BoardState.COLUMNS
const ROWS := BoardState.ROWS

@onready var _grid: GridContainer = %BoardGrid
@onready var _legend: HBoxContainer = %ChainLegend
@onready var _storage_button: Button = %StorageButton
@onready var _storage_panel: StoragePanel = %StoragePanel
@onready var _info_panel: ItemInfoPanel = %ItemInfoPanel
@onready var _discovery_banner: DiscoveryBanner = %DiscoveryBanner
@onready var _burst_layer: Control = %BurstLayer

var _cells: Dictionary = {} # Vector2i -> BoardCell
var _highlighted_chain_id: String = ""

func _ready() -> void:
	_build_grid()
	_build_legend()
	_storage_button.pressed.connect(func():
		if _storage_panel.visible:
			_storage_panel.hide_panel()
		else:
			_storage_panel.show_panel()
	)
	_storage_panel.item_tapped.connect(func(id): _info_panel.show_for(id, false))
	_storage_panel.item_long_pressed.connect(func(id): _info_panel.show_for(id, true))
	_info_panel.changed.connect(_on_state_changed)
	refresh_board()

	var params := SceneRouter.take_pending_params()
	if params.has("highlight_chain_id") and not String(params.highlight_chain_id).is_empty():
		_on_legend_tapped(String(params.highlight_chain_id))

func _build_grid() -> void:
	_grid.columns = COLUMNS
	for cell in _grid.get_children():
		cell.queue_free()
	_cells.clear()
	for y in ROWS:
		for x in COLUMNS:
			var pos := Vector2i(x, y)
			var cell := BoardCell.new()
			cell.setup(pos)
			cell.drop_attempted.connect(_on_drop_attempted)
			_grid.add_child(cell)
			_cells[pos] = cell

func _build_legend() -> void:
	for child in _legend.get_children():
		child.queue_free()
	for chain_id in ItemDatabase.get_all_chain_ids():
		if ItemDatabase.is_reward_chain(chain_id):
			continue
		var icon := ChainLegendIcon.new()
		icon.chain_id = chain_id
		icon.tapped.connect(_on_legend_tapped)
		_legend.add_child(icon)

func _on_legend_tapped(chain_id: String) -> void:
	_highlighted_chain_id = "" if _highlighted_chain_id == chain_id else chain_id
	for icon in _legend.get_children():
		icon.set_selected(icon.chain_id == _highlighted_chain_id)
	_apply_highlight()

func _apply_highlight() -> void:
	for pos in _cells:
		var cell: BoardCell = _cells[pos]
		if cell.item_view == null:
			continue
		if _highlighted_chain_id.is_empty():
			cell.item_view.modulate.a = 1.0
			continue
		var def := cell.item_view.get_def()
		cell.item_view.modulate.a = 1.0 if (def != null and def.chain_id == _highlighted_chain_id) else 0.3

# -- Board refresh -------------------------------------------------------

func refresh_board() -> void:
	for pos in _cells:
		var cell: BoardCell = _cells[pos]
		var view := cell.refresh()
		if view != null:
			_connect_item_view(view)
	_apply_highlight()
	if _storage_panel.visible:
		_storage_panel.refresh()

func _connect_item_view(view: ItemView) -> void:
	view.tapped.connect(_on_item_tapped)
	view.double_tapped.connect(_on_item_double_tapped)
	view.long_pressed.connect(_on_item_long_pressed)

func _on_state_changed() -> void:
	refresh_board()

# -- Interaction -----------------------------------------------------------

func _on_item_tapped(instance_id: String) -> void:
	_info_panel.show_for(instance_id, false)

func _on_item_long_pressed(instance_id: String) -> void:
	_info_panel.show_for(instance_id, true)

func _on_item_double_tapped(instance_id: String) -> void:
	var def := BoardState.get_item_def(instance_id)
	if def == null:
		return
	if not def.is_producer:
		_info_panel.show_for(instance_id, false)
		return
	var result := BoardState.tap_producer(instance_id)
	if result.success:
		refresh_board()
		_play_pop_at_instance(result.spawned_instance_id)
		AudioManager.play_sfx("producer_activate")
	else:
		_toast_for_producer_failure(result.reason)

func _on_drop_attempted(dragged_id: String, cell: BoardCell) -> void:
	var target_pos := cell.grid_pos
	if BoardState.is_cell_free(target_pos):
		if BoardState.move_to_cell(dragged_id, target_pos):
			refresh_board()
			_play_pop_at_instance(dragged_id)
		return

	var occupant_id: String = BoardState.grid.get(target_pos, "")
	var result := BoardState.try_merge(dragged_id, occupant_id)
	if result.success:
		refresh_board()
		_play_merge_burst(target_pos)
		_play_pop_at_instance(result.resulting_instance_id)
		AudioManager.play_sfx("merge")
		if result.is_discovery:
			_discovery_banner.show_item(result.resulting_item_id)
			AudioManager.play_sfx("discovery")
	else:
		_play_invalid_shake(cell)
		AudioManager.play_sfx("merge_invalid")
		_toast_for_merge_failure(result.reason)

# -- Feedback / animation --------------------------------------------------

func _reduced_motion() -> bool:
	return GameManager.settings.get("reduced_motion", false)

func _play_pop_at_instance(instance_id: String) -> void:
	var bi: BoardItem = BoardState.items.get(instance_id)
	if bi == null or not bi.is_on_board():
		return
	var cell: BoardCell = _cells.get(bi.grid_position)
	if cell == null or cell.item_view == null:
		return
	if _reduced_motion():
		return
	var view := cell.item_view
	view.scale = Vector2(0.5, 0.5)
	view.pivot_offset = view.size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(view, "scale", Vector2(1.15, 1.15), 0.16)
	tween.tween_property(view, "scale", Vector2.ONE, 0.1)

func _play_invalid_shake(cell: BoardCell) -> void:
	if _reduced_motion() or cell.item_view == null:
		return
	var view := cell.item_view
	var base_pos := view.position
	var tween := create_tween()
	for i in 4:
		var offset: float = 6.0 if i % 2 == 0 else -6.0
		tween.tween_property(view, "position", base_pos + Vector2(offset, 0), 0.04)
	tween.tween_property(view, "position", base_pos, 0.04)

## Brief expanding-ring flash on a successful merge (spec: "a particle
## effect appears"). Drawn once - the fade/expand is done entirely via
## modulate/scale tweens, which Godot applies at render time without any
## further redraw calls needed.
func _play_merge_burst(grid_pos: Vector2i) -> void:
	if _reduced_motion():
		return
	var cell: BoardCell = _cells.get(grid_pos)
	if cell == null:
		return
	var burst_size: Vector2 = cell.size
	var burst := Control.new()
	burst.size = burst_size
	burst.global_position = cell.global_position
	burst.pivot_offset = burst_size * 0.5
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.draw.connect(func():
		burst.draw_arc(burst_size * 0.5, burst_size.x * 0.5, 0, TAU, 20, Color("e8dcc5"), 3.0)
	)
	_burst_layer.add_child(burst)

	var tween := create_tween()
	tween.tween_property(burst, "scale", Vector2(1.8, 1.8), 0.35).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(burst, "modulate:a", 0.0, 0.35)
	tween.tween_callback(burst.queue_free)

func _toast_for_merge_failure(reason: String) -> void:
	var messages := {
		"not_matching": "Those items don't match.",
		"max_level": "Already at maximum level.",
		"producers_do_not_merge": "Producers can't be merged.",
		"no_space": "No space for the result.",
	}
	if messages.has(reason):
		EventBus.show_toast.emit(messages[reason])

func _toast_for_producer_failure(reason: String) -> void:
	var messages := {
		"cooldown": "Still recharging.",
		"exhausted": "This producer is used up.",
		"no_energy": "Not enough energy.",
		"board_full": "The board is full.",
	}
	if messages.has(reason):
		EventBus.show_toast.emit(messages[reason])
