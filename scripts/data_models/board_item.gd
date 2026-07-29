extends Resource
class_name BoardItem
## Runtime instance of an item sitting on (or in storage off) the merge
## board. Many BoardItems can share the same ItemDefinition id.

@export var instance_id: String
@export var item_id: String
@export var grid_position: Vector2i = Vector2i(-1, -1) # (-1,-1) == in storage, not on the board
@export var charge_count: int = -1 # remaining producer uses, -1 == unlimited
@export var cooldown_end_unix: float = 0.0
@export var is_locked: bool = false
@export var has_cobweb: bool = false
@export var is_in_bubble: bool = false

func is_on_board() -> bool:
	return grid_position.x >= 0 and grid_position.y >= 0

func is_on_cooldown() -> bool:
	return cooldown_end_unix > Time.get_unix_time_from_system()
