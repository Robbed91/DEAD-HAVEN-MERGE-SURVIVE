extends Panel
class_name ScavengeCell
## One cell of the scavenging merge challenge's grid - a stripped-down
## sibling of scenes/merge_board/board_cell.gd for the throwaway
## ScavengeMergeState board (see that file for why this isn't the same
## grid as the player's real residence board).

signal drop_attempted(from_pos: Vector2i, to_pos: Vector2i)
signal tile_tapped(grid_pos: Vector2i)

var grid_pos: Vector2i
var tile_view: ScavengeTileView

func setup(pos: Vector2i) -> void:
	grid_pos = pos
	custom_minimum_size = Vector2(64, 64)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", ThemeFactory.board_cell_style("normal"))

func refresh(item_id: String) -> void:
	if tile_view != null:
		tile_view.queue_free()
		tile_view = null
	if item_id.is_empty():
		return
	tile_view = ScavengeTileView.new()
	tile_view.grid_pos = grid_pos
	tile_view.item_id = item_id
	tile_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile_view.tapped.connect(func(pos): tile_tapped.emit(pos))
	add_child(tile_view)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("type") == "scavenge_tile" and data.get("from_pos") != grid_pos

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	drop_attempted.emit(data.from_pos, grid_pos)
