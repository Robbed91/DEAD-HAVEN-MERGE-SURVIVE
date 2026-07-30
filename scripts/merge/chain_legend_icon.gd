extends Control
class_name ChainLegendIcon
## One tappable swatch in the merge board's chain-highlight legend. This is
## Phase 2's honest stand-in for spec's "tap a task marker to highlight the
## relevant merge chain": there are no residence tasks yet (Phase 3), so the
## legend lets the player highlight a chain directly instead of via a task.

signal tapped(chain_id: String)

@export var chain_id: String = ""
var is_selected: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(48, 48)
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_selected(value: bool) -> void:
	is_selected = value
	queue_redraw()

func _draw() -> void:
	ItemIconRenderer.draw_chain_swatch(self, chain_id)
	if is_selected:
		draw_rect(Rect2(Vector2.ZERO, size), Color("e8b93d"), false, 3.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		tapped.emit(chain_id)
