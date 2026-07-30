extends CanvasLayer
class_name StoragePanel
## Storage/inventory drawer: a bottom-anchored panel (not a full-screen
## modal) so the board stays visible and reachable above it - items here
## are real draggable ItemViews that can be dropped straight onto a board
## cell without an intermediate "select then place" step.

signal item_tapped(instance_id: String)
signal item_long_pressed(instance_id: String)

@onready var _grid: GridContainer = %Grid
@onready var _capacity_label: Label = %CapacityLabel
@onready var _close_button: Button = %CloseButton

func _ready() -> void:
	layer = 91
	visible = false
	_close_button.pressed.connect(hide_panel)

func show_panel() -> void:
	refresh()
	visible = true

func hide_panel() -> void:
	visible = false

func refresh() -> void:
	_capacity_label.text = "%d / %d" % [BoardState.storage_order.size(), BoardState.storage_capacity]
	for child in _grid.get_children():
		child.queue_free()
	for instance_id in BoardState.storage_order:
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(72, 72)
		var view := ItemView.new()
		view.instance_id = instance_id
		view.set_anchors_preset(Control.PRESET_FULL_RECT)
		view.tapped.connect(func(id): item_tapped.emit(id))
		view.long_pressed.connect(func(id): item_long_pressed.emit(id))
		cell.add_child(view)
		_grid.add_child(cell)
