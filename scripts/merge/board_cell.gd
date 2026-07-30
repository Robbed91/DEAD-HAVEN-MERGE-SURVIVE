extends Panel
class_name BoardCell
## One cell of the 7x9 merge grid. Purely presentational + a Godot
## drag-and-drop target - it never mutates BoardState itself, it just tells
## MergeBoard a drop was attempted and lets the controller decide (move vs.
## merge) so animations and board-wide state stay in one place.

signal drop_attempted(dragged_instance_id: String, cell: BoardCell)

var grid_pos: Vector2i
var item_view: ItemView

func setup(pos: Vector2i) -> void:
	grid_pos = pos
	custom_minimum_size = Vector2(78, 78)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS

## Rebuilds the cell's child ItemView for whatever instance (if any) now
## occupies this grid position. Returns the new ItemView, or null if empty.
func refresh() -> ItemView:
	if item_view != null:
		item_view.queue_free()
		item_view = null
	var occupant_id: String = BoardState.grid.get(grid_pos, "")
	if occupant_id == "":
		return null
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
		return true
	var occ_def := BoardState.get_item_def(occupant_id)
	return occ_def != null and not occ_def.is_producer

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	drop_attempted.emit(data.instance_id, self)
