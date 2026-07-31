extends Panel
class_name BoardCell
## One cell of the 7x9 merge grid. Purely presentational + a Godot
## drag-and-drop target - it never mutates BoardState itself, it just tells
## MergeBoard a drop was attempted and lets the controller decide (move vs.
## merge) so animations and board-wide state stay in one place.

signal drop_attempted(dragged_instance_id: String, cell: BoardCell)

var grid_pos: Vector2i
var item_view: ItemView
var _feedback_until_ms := 0
var _feedback_state := "normal"

func setup(pos: Vector2i) -> void:
	grid_pos = pos
	custom_minimum_size = Vector2(78, 78)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", ThemeFactory.board_cell_style())
	set_process(false)

## Rebuilds the cell's child ItemView for whatever instance (if any) now
## occupies this grid position. Returns the new ItemView, or null if empty.
func refresh() -> ItemView:
	if item_view != null:
		item_view.queue_free()
		item_view = null
	var occupant_id: String = BoardState.grid.get(grid_pos, "")
	if occupant_id == "":
		add_theme_stylebox_override("panel", ThemeFactory.board_cell_style())
		return null
	var board_item: BoardItem = BoardState.items.get(occupant_id)
	add_theme_stylebox_override("panel", ThemeFactory.board_cell_style("locked" if board_item != null and board_item.is_locked else "normal"))
	item_view = ItemView.new()
	item_view.instance_id = occupant_id
	item_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(item_view)
	return item_view

## Deliberately permissive: accepts any drop onto an empty cell, and onto an
## occupied non-producer cell even if it won't actually merge (chain/level
## mismatch) - MergeBoard resolves the real outcome and plays either a merge
## animation or an "invalid merge" shake, so the player gets feedback
## instead of the drag just silently failing to register.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or data.get("type") != "board_item":
		return false
	var dragged_id: String = data.instance_id
	var occupant_id: String = BoardState.grid.get(grid_pos, "")
	if occupant_id == dragged_id:
		return false
	if occupant_id == "":
		_set_drop_feedback("valid")
		return true
	var occ_def := BoardState.get_item_def(occupant_id)
	var dragged_def := BoardState.get_item_def(dragged_id)
	var visual_valid := occ_def != null and dragged_def != null and not occ_def.is_producer and not dragged_def.is_producer and occ_def.chain_id == dragged_def.chain_id and occ_def.level == dragged_def.level
	_set_drop_feedback("valid" if visual_valid else "invalid")
	return occ_def != null and not occ_def.is_producer

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_clear_drop_feedback()
	drop_attempted.emit(data.instance_id, self)

func _set_drop_feedback(state: String) -> void:
	_feedback_state = state
	_feedback_until_ms = Time.get_ticks_msec() + 130
	add_theme_stylebox_override("panel", ThemeFactory.board_cell_style(state))
	set_process(true)

func _clear_drop_feedback() -> void:
	_feedback_state = "normal"
	_feedback_until_ms = 0
	modulate = Color.WHITE
	var occupant_id: String = BoardState.grid.get(grid_pos, "")
	var board_item: BoardItem = BoardState.items.get(occupant_id)
	add_theme_stylebox_override("panel", ThemeFactory.board_cell_style("locked" if board_item != null and board_item.is_locked else "normal"))
	set_process(false)

func _process(_delta: float) -> void:
	if Time.get_ticks_msec() >= _feedback_until_ms or not get_viewport().gui_is_dragging():
		_clear_drop_feedback()
		return
	var pulse := 0.94 + sin(Time.get_ticks_msec() * 0.018) * 0.06
	modulate = Color(pulse, pulse, pulse, 1.0) if _feedback_state == "valid" else Color(1.0, pulse, pulse, 1.0)
