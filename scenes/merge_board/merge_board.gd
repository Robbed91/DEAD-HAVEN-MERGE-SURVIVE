extends Control
## MergeBoard
##
## Phase 1 shows the real board dimensions and empty-cell framework only.
## Drag/drop, merging, producers and storage are built in Phase 2 on top of
## this same grid - see scripts/merge/ once that phase lands.

const COLUMNS := 7
const ROWS := 9

func _ready() -> void:
	_build_empty_grid()

func _build_empty_grid() -> void:
	var grid: GridContainer = %BoardGrid
	grid.columns = COLUMNS
	for cell in grid.get_children():
		cell.queue_free()
	for i in COLUMNS * ROWS:
		var cell := Panel.new()
		cell.custom_minimum_size = Vector2(84, 84)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid.add_child(cell)
