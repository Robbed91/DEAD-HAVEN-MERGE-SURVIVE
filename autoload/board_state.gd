extends Node
## BoardState
##
## Owns every BoardItem that exists (on the grid or in storage), the grid
## occupancy map, and merge/producer/deletion rules. UI (merge_board.gd)
## reads this for what to draw and calls into it for every interaction; it
## never mutates BoardItem/grid state directly.

const COLUMNS := 7
const ROWS := 9
const PRODUCER_ENERGY_COST := 1
const DEFAULT_STORAGE_CAPACITY := 30
const DELETE_UNDO_WINDOW_SECONDS := 5.0
## Rarity at/above which the UI must ask for confirmation before deleting.
const CONFIRM_DELETE_MIN_RARITY := ItemDefinition.Rarity.RARE

var items: Dictionary = {} # instance_id -> BoardItem
var grid: Dictionary = {} # Vector2i -> instance_id
var storage_order: Array[String] = [] # instance_id, in storage, display order
var storage_capacity: int = DEFAULT_STORAGE_CAPACITY
var discovered_item_ids: Dictionary = {} # item_id -> true, for one-time discovery rewards

## instance_id -> {item_id, grid_position, expires_at_unix}. Soft-deleted
## items are already off the board/out of storage but can still be restored
## until expires_at_unix; purge_expired_deletions() clears them for good.
var _pending_deletions: Dictionary = {}

var _next_instance_num: int = 0

func _ready() -> void:
	set_process(true)

func _process(_delta: float) -> void:
	purge_expired_deletions()

# -- Lifecycle ---------------------------------------------------------------

func reset_new_board() -> void:
	items.clear()
	grid.clear()
	storage_order.clear()
	discovered_item_ids.clear()
	_pending_deletions.clear()
	storage_capacity = DEFAULT_STORAGE_CAPACITY
	_next_instance_num = 0
	_place_starting_layout()

## Every producer starts on the board (Phase 2 has no producer-unlock
## progression yet - that arrives with residence/quest gating in Phase 3+),
## plus two loose level-1 items so a first merge is immediately available.
func _place_starting_layout() -> void:
	var producer_ids := ItemDatabase.get_producer_ids()
	producer_ids.sort()
	var pos := Vector2i.ZERO
	for producer_id in producer_ids:
		spawn_item(producer_id, pos)
		pos.x += 1
		if pos.x >= COLUMNS:
			pos.x = 0
			pos.y += 1

	var starter_row := pos.y + 2
	spawn_item("construction_1", Vector2i(3, starter_row))
	spawn_item("construction_1", Vector2i(4, starter_row))

# -- Instance management ------------------------------------------------------

func _make_instance_id() -> String:
	_next_instance_num += 1
	return "bi_%d" % _next_instance_num

func get_item_def(instance_id: String) -> ItemDefinition:
	if not items.has(instance_id):
		return null
	return ItemDatabase.get_item(items[instance_id].item_id)

func is_cell_free(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < COLUMNS and pos.y >= 0 and pos.y < ROWS and not grid.has(pos)

func find_empty_cell() -> Vector2i:
	for y in ROWS:
		for x in COLUMNS:
			var pos := Vector2i(x, y)
			if not grid.has(pos):
				return pos
	return Vector2i(-1, -1)

## Spawns a new BoardItem for item_id at grid_pos (or into storage if
## grid_pos is (-1,-1) or already occupied). Returns null if placement is
## impossible (board and storage both full).
func spawn_item(item_id: String, grid_pos: Vector2i = Vector2i(-1, -1)) -> BoardItem:
	if not ItemDatabase.has_item(item_id):
		return null
	var def := ItemDatabase.get_item(item_id)
	var board_item := BoardItem.new()
	board_item.instance_id = _make_instance_id()
	board_item.item_id = item_id
	board_item.charge_count = def.producer_charges
	items[board_item.instance_id] = board_item

	var placed_on_board := grid_pos.x >= 0 and grid_pos.y >= 0 and is_cell_free(grid_pos)
	if placed_on_board:
		board_item.grid_position = grid_pos
		grid[grid_pos] = board_item.instance_id
	elif not _add_to_storage(board_item.instance_id):
		items.erase(board_item.instance_id)
		return null

	_maybe_grant_discovery(def)
	EventBus.board_item_added.emit(board_item.instance_id)
	return board_item

func _add_to_storage(instance_id: String) -> bool:
	if storage_order.size() >= storage_capacity:
		return false
	storage_order.append(instance_id)
	return true

func _maybe_grant_discovery(def: ItemDefinition) -> void:
	if discovered_item_ids.has(def.id):
		return
	discovered_item_ids[def.id] = true
	if not def.discovery_reward.is_empty():
		_grant_rewards(def.discovery_reward)
	EventBus.item_discovered.emit(def.id)

func _grant_rewards(rewards: Dictionary) -> void:
	if rewards.has("coins") and rewards.coins > 0:
		GameManager.add_coins(rewards.coins)
	if rewards.has("energy") and rewards.energy > 0:
		GameManager.add_energy(rewards.energy)
	if rewards.has("xp") and rewards.xp > 0:
		GameManager.add_xp(rewards.xp)
	if rewards.has("haven_tokens") and rewards.haven_tokens > 0:
		GameManager.add_haven_tokens(rewards.haven_tokens)

# -- Movement ------------------------------------------------------------

## Moves an on-board or in-storage item to an empty board cell. Fails (false)
## if the item doesn't exist, is mid-deletion, or the target cell is occupied
## or out of bounds - callers should try try_merge() first when the target
## cell is occupied by a compatible item.
func move_to_cell(instance_id: String, to_pos: Vector2i) -> bool:
	if not items.has(instance_id) or not is_cell_free(to_pos):
		return false
	var board_item: BoardItem = items[instance_id]
	if board_item.is_on_board():
		grid.erase(board_item.grid_position)
	else:
		storage_order.erase(instance_id)
	board_item.grid_position = to_pos
	grid[to_pos] = instance_id
	EventBus.board_item_moved.emit(instance_id)
	return true

func move_to_storage(instance_id: String) -> bool:
	if not items.has(instance_id):
		return false
	var board_item: BoardItem = items[instance_id]
	if not board_item.is_on_board():
		return true
	if storage_order.size() >= storage_capacity:
		return false
	grid.erase(board_item.grid_position)
	board_item.grid_position = Vector2i(-1, -1)
	storage_order.append(instance_id)
	EventBus.board_item_moved.emit(instance_id)
	return true

# -- Merging ---------------------------------------------------------------

## Attempts to merge dragged_id onto target_id. On success the target's
## position now holds the upgraded item (new instance) and both source
## instances are gone; the dragged item is NOT restored to its old cell.
## Returns {success, reason, resulting_instance_id, is_discovery, is_max_level}.
func try_merge(dragged_id: String, target_id: String) -> Dictionary:
	if dragged_id == target_id or not items.has(dragged_id) or not items.has(target_id):
		return {"success": false, "reason": "invalid_instances"}

	var dragged_def := get_item_def(dragged_id)
	var target_def := get_item_def(target_id)
	if dragged_def == null or target_def == null:
		return {"success": false, "reason": "invalid_instances"}

	if dragged_def.is_producer or target_def.is_producer:
		return {"success": false, "reason": "producers_do_not_merge"}
	if dragged_def.chain_id != target_def.chain_id or dragged_def.level != target_def.level:
		return {"success": false, "reason": "not_matching"}

	var next_def := ItemDatabase.get_next_level(target_def)
	if next_def == null:
		return {"success": false, "reason": "max_level", "is_max_level": true}

	var target_pos: Vector2i = items[target_id].grid_position
	var was_dragged_on_board: bool = items[dragged_id].is_on_board()

	_remove_instance(dragged_id)
	_remove_instance(target_id)

	var was_discovered_before := discovered_item_ids.has(next_def.id)
	var result_item := spawn_item(next_def.id, target_pos if target_pos.x >= 0 else Vector2i(-1, -1))
	if result_item == null:
		# Board/storage were both full at the exact instant of merge - extremely
		# unlikely (a cell was just freed by the merge itself) but handled
		# rather than silently dropping the merged item.
		return {"success": false, "reason": "no_space"}

	EventBus.items_merged.emit(dragged_id, target_id, result_item.instance_id)
	return {
		"success": true,
		"resulting_instance_id": result_item.instance_id,
		"resulting_item_id": next_def.id,
		"is_discovery": not was_discovered_before,
		"was_on_board": was_dragged_on_board or target_pos.x >= 0,
	}

func _remove_instance(instance_id: String) -> void:
	if not items.has(instance_id):
		return
	var board_item: BoardItem = items[instance_id]
	if board_item.is_on_board():
		grid.erase(board_item.grid_position)
	else:
		storage_order.erase(instance_id)
	items.erase(instance_id)

# -- Producers ---------------------------------------------------------------

## Taps a producer: spends energy, respects cooldown/charges, spawns a
## level-1 item of its chain into the first empty board cell.
func tap_producer(instance_id: String) -> Dictionary:
	if not items.has(instance_id):
		return {"success": false, "reason": "invalid_instance"}
	var board_item: BoardItem = items[instance_id]
	var def := get_item_def(instance_id)
	if def == null or not def.is_producer:
		return {"success": false, "reason": "not_a_producer"}
	if board_item.is_on_cooldown():
		return {"success": false, "reason": "cooldown", "cooldown_end_unix": board_item.cooldown_end_unix}
	if board_item.charge_count == 0:
		return {"success": false, "reason": "exhausted"}

	var target_cell := find_empty_cell()
	if target_cell.x < 0:
		return {"success": false, "reason": "board_full"}

	if not GameManager.spend_energy(PRODUCER_ENERGY_COST):
		return {"success": false, "reason": "no_energy"}

	var spawned := spawn_item(def.produces_item_id, target_cell)
	if spawned == null:
		GameManager.add_energy(PRODUCER_ENERGY_COST) # refund - placement failed after the spend
		return {"success": false, "reason": "no_space"}

	if board_item.charge_count > 0:
		board_item.charge_count -= 1
	board_item.cooldown_end_unix = Time.get_unix_time_from_system() + def.producer_cooldown_seconds
	EventBus.producer_activated.emit(instance_id, spawned.instance_id)
	return {"success": true, "spawned_instance_id": spawned.instance_id}

func debug_reset_all_cooldowns() -> void:
	for instance_id in items:
		var board_item: BoardItem = items[instance_id]
		board_item.cooldown_end_unix = 0.0
		var def := ItemDatabase.get_item(board_item.item_id)
		if def != null and def.is_producer:
			board_item.charge_count = def.producer_charges

# -- Deletion with undo -----------------------------------------------------

func can_delete(instance_id: String) -> bool:
	return items.has(instance_id) and not get_item_def(instance_id).is_producer

## True if the UI must show a confirmation dialog before calling
## soft_delete() for this item (spec: "confirmation before deleting rare or
## high-level items").
func requires_delete_confirmation(instance_id: String) -> bool:
	var def := get_item_def(instance_id)
	return def != null and def.rarity >= CONFIRM_DELETE_MIN_RARITY

## Removes the item from play immediately but keeps enough to restore it
## until the undo window expires.
func soft_delete(instance_id: String) -> bool:
	if not can_delete(instance_id):
		return false
	var board_item: BoardItem = items[instance_id]
	_pending_deletions[instance_id] = {
		"item_id": board_item.item_id,
		"grid_position": board_item.grid_position,
		"charge_count": board_item.charge_count,
		"expires_at_unix": Time.get_unix_time_from_system() + DELETE_UNDO_WINDOW_SECONDS,
	}
	_remove_instance(instance_id)
	EventBus.board_item_removed.emit(instance_id)
	return true

func can_undo_delete(instance_id: String) -> bool:
	return _pending_deletions.has(instance_id)

func undo_delete(instance_id: String) -> bool:
	if not _pending_deletions.has(instance_id):
		return false
	var pending: Dictionary = _pending_deletions[instance_id]
	_pending_deletions.erase(instance_id)
	var pos: Vector2i = pending.grid_position
	if pos.x >= 0 and not is_cell_free(pos):
		pos = Vector2i(-1, -1) # original cell got taken during the undo window
	var restored := spawn_item(pending.item_id, pos)
	if restored == null:
		return false
	restored.charge_count = pending.charge_count
	return true

func purge_expired_deletions() -> void:
	if _pending_deletions.is_empty():
		return
	var now := Time.get_unix_time_from_system()
	for instance_id in _pending_deletions.keys():
		if _pending_deletions[instance_id].expires_at_unix <= now:
			_pending_deletions.erase(instance_id)

# -- Quantity queries / consumption (used by ResidenceManager tasks) --------

## Total count of item_id across both the board and storage.
func count_item(item_id: String) -> int:
	var total := 0
	for instance_id in items:
		if items[instance_id].item_id == item_id:
			total += 1
	return total

## Removes up to `count` instances of item_id, storage first (keeps the
## board visually stable), then the board. Returns false and removes
## nothing if there weren't enough - callers should check count_item()
## first, but this is safe to call speculatively too.
func consume_item(item_id: String, count: int) -> bool:
	if count_item(item_id) < count:
		return false
	var to_remove: Array[String] = []
	for instance_id in storage_order:
		if to_remove.size() >= count:
			break
		if items[instance_id].item_id == item_id:
			to_remove.append(instance_id)
	if to_remove.size() < count:
		for instance_id in grid.values():
			if to_remove.size() >= count:
				break
			if items[instance_id].item_id == item_id:
				to_remove.append(instance_id)
	for instance_id in to_remove:
		_remove_instance(instance_id)
		EventBus.board_item_removed.emit(instance_id)
	return true

# -- Reward-chain collection ---------------------------------------------

## Reward-chain items (energy/coin/xp/token) are collected instead of used
## in a task: this consumes the item and grants the scaled resource amount.
func collect_reward(instance_id: String) -> bool:
	var def := get_item_def(instance_id)
	if def == null:
		return false
	var chain := ItemDatabase.get_chain(def.chain_id)
	if not chain.get("is_reward_chain", false):
		return false
	var amount: int = def.level * int(chain.get("per_level_value", 0))
	match String(chain.get("resource", "")):
		"energy": GameManager.add_energy(amount)
		"coins": GameManager.add_coins(amount)
		"xp": GameManager.add_xp(amount)
		"haven_tokens": GameManager.add_haven_tokens(amount)
		_: return false
	_remove_instance(instance_id)
	EventBus.board_item_removed.emit(instance_id)
	return true

# -- Save/load -----------------------------------------------------------

func to_save_data() -> Dictionary:
	var items_data := {}
	for instance_id in items:
		var board_item: BoardItem = items[instance_id]
		items_data[instance_id] = {
			"item_id": board_item.item_id,
			"grid_x": board_item.grid_position.x,
			"grid_y": board_item.grid_position.y,
			"charge_count": board_item.charge_count,
			"cooldown_end_unix": board_item.cooldown_end_unix,
			"is_locked": board_item.is_locked,
			"has_cobweb": board_item.has_cobweb,
			"is_in_bubble": board_item.is_in_bubble,
		}
	return {
		"items": items_data,
		"storage_order": storage_order.duplicate(),
		"storage_capacity": storage_capacity,
		"discovered_item_ids": discovered_item_ids.keys(),
		"next_instance_num": _next_instance_num,
	}

func apply_save_data(data: Dictionary) -> void:
	items.clear()
	grid.clear()
	storage_order.clear()
	discovered_item_ids.clear()
	_pending_deletions.clear()

	if data.is_empty():
		reset_new_board()
		return

	for instance_id in data.get("items", {}):
		var raw: Dictionary = data["items"][instance_id]
		if not ItemDatabase.has_item(raw.get("item_id", "")):
			continue # content was removed/renamed since this save; drop it rather than crash
		var board_item := BoardItem.new()
		board_item.instance_id = instance_id
		board_item.item_id = raw.item_id
		board_item.grid_position = Vector2i(raw.get("grid_x", -1), raw.get("grid_y", -1))
		board_item.charge_count = raw.get("charge_count", -1)
		board_item.cooldown_end_unix = raw.get("cooldown_end_unix", 0.0)
		board_item.is_locked = raw.get("is_locked", false)
		board_item.has_cobweb = raw.get("has_cobweb", false)
		board_item.is_in_bubble = raw.get("is_in_bubble", false)
		items[instance_id] = board_item
		if board_item.is_on_board():
			grid[board_item.grid_position] = instance_id

	var loaded_storage: Array = data.get("storage_order", [])
	for instance_id in loaded_storage:
		if items.has(instance_id):
			storage_order.append(instance_id)

	storage_capacity = data.get("storage_capacity", DEFAULT_STORAGE_CAPACITY)
	for item_id in data.get("discovered_item_ids", []):
		discovered_item_ids[item_id] = true
	_next_instance_num = data.get("next_instance_num", items.size())

	if items.is_empty():
		reset_new_board()
