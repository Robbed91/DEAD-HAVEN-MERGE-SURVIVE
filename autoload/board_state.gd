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
const BOARD_FORMAT_VERSION := 2
const BOARD_LAYOUT_VERSION := 1
const BOARD_LAYOUT_ROOT := "res://data/boards/"
const DEFAULT_RESIDENCE_ID := "hollow_creek_farmhouse"
const RESIDENCE_IDS := [
	"hollow_creek_farmhouse",
	"redwater_service_station",
	"greybridge_school",
	"saint_mercy_hospital",
	"northgate_prison",
]
## Rarity at/above which the UI must ask for confirmation before deleting.
const CONFIRM_DELETE_MIN_RARITY := ItemDefinition.Rarity.RARE

## Producers stay in their established board positions for save compatibility,
## but activation is derived from existing story/repair/vehicle milestones.
## No separate unlock field is added to the save schema.
const PRODUCER_UNLOCK_RULES := {
	"construction_producer": {"kind": "always", "label": "Available from the start"},
	"tool_producer": {"kind": "quest", "id": "q_secure_front_door", "label": "Secure the Front Door"},
	"food_producer": {"kind": "quest", "id": "q_clear_living_room", "label": "Clear the Living Room"},
	"medical_producer": {"kind": "quest", "id": "q_repair_pantry", "label": "Repair the Food Pantry"},
	"trap_producer": {"kind": "quest", "id": "q_rescue_noah", "label": "Rescue Noah"},
	"vehicle_parts_producer": {"kind": "vehicle", "id": "delivery_van", "label": "Discover the delivery van"},
	"fuel_producer": {"kind": "story_flag", "id": "redwater_unlocked", "label": "Unlock Redwater"},
	"electronics_producer": {"kind": "story_flag", "id": "redwater_unlocked", "label": "Unlock Redwater"},
	"clothing_producer": {"kind": "story_flag", "id": "greybridge_unlocked", "label": "Unlock Greybridge"},
}

var items: Dictionary = {} # instance_id -> BoardItem
var grid: Dictionary = {} # Vector2i -> instance_id
var storage_order: Array[String] = [] # instance_id, in storage, display order
var storage_capacity: int = DEFAULT_STORAGE_CAPACITY
var discovered_item_ids: Dictionary = {} # item_id -> true, for one-time discovery rewards
var active_residence_id: String = DEFAULT_RESIDENCE_ID

## Inactive residence boards are stored in the same shape used on disk.
## The existing public items/grid/storage API always represents the active
## residence so merge and quest callers do not need gameplay-facing changes.
var _residence_board_data: Dictionary = {}
var _layout_version: int = BOARD_LAYOUT_VERSION

## instance_id -> {item_id, grid_position, expires_at_unix}. Soft-deleted
## items are already off the board/out of storage but can still be restored
## until expires_at_unix; purge_expired_deletions() clears them for good.
var _pending_deletions: Dictionary = {}

var _next_instance_num: int = 0

func _ready() -> void:
	set_process(true)
	EventBus.quest_completed.connect(func(_quest_id): refresh_producer_locks(true))
	EventBus.story_flag_changed.connect(func(_flag_id, _value): refresh_producer_locks(true))
	EventBus.vehicle_discovered.connect(func(_vehicle_id): refresh_producer_locks(true))

func _process(_delta: float) -> void:
	purge_expired_deletions()

# -- Lifecycle ---------------------------------------------------------------

func reset_new_board() -> void:
	_residence_board_data.clear()
	discovered_item_ids.clear()
	active_residence_id = DEFAULT_RESIDENCE_ID
	_reset_active_board()
	_materialize_missing_boards()

func _reset_active_board() -> void:
	items.clear()
	grid.clear()
	storage_order.clear()
	_pending_deletions.clear()
	storage_capacity = DEFAULT_STORAGE_CAPACITY
	_next_instance_num = 0
	_layout_version = BOARD_LAYOUT_VERSION
	_place_starting_layout()
	refresh_producer_locks(false)

func activate_residence_board(residence_id: String) -> bool:
	if not residence_id in RESIDENCE_IDS:
		push_error("BoardState: unknown residence board '%s'" % residence_id)
		return false
	if residence_id == active_residence_id:
		GameManager.profile.current_residence_id = active_residence_id
		refresh_producer_locks(false)
		return true
	_residence_board_data[active_residence_id] = _active_board_to_data()
	active_residence_id = residence_id
	GameManager.profile.current_residence_id = active_residence_id
	if _residence_board_data.has(residence_id):
		_apply_active_board_data(_residence_board_data[residence_id])
	else:
		_reset_active_board()
	refresh_producer_locks(false)
	return true

func has_residence_board(residence_id: String) -> bool:
	return residence_id == active_residence_id or _residence_board_data.has(residence_id)

func _materialize_missing_boards() -> void:
	var original_residence_id := active_residence_id
	for residence_id in RESIDENCE_IDS:
		activate_residence_board(residence_id)
	activate_residence_board(original_residence_id)
## Every producer remains in its established board position for legacy-save
## compatibility; refresh_producer_locks() activates them progressively.
## Two loose level-1 items make a first construction merge immediately viable.
func _place_starting_layout() -> void:
	var layout := _load_active_layout()
	if layout.is_empty():
		_place_legacy_starting_layout()
		return
	var producer_ids := ItemDatabase.get_producer_ids()
	producer_ids.sort()
	var producer_positions: Array = layout.get("producer_positions", [])
	for index in mini(producer_ids.size(), producer_positions.size()):
		spawn_item(producer_ids[index], _layout_position(producer_positions[index]))
	for raw_starter in layout.get("starter_items", []):
		spawn_item(String(raw_starter.get("item_id", "")), _layout_position(raw_starter.get("position", [])))
	_fill_layout_junk(layout)

func _place_legacy_starting_layout() -> void:
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

func _load_active_layout() -> Dictionary:
	var path := "%s%s.json" % [BOARD_LAYOUT_ROOT, active_residence_id]
	if not FileAccess.file_exists(path):
		push_error("BoardState: missing layout %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("BoardState: invalid layout JSON %s" % path)
		return {}
	return parsed

func _layout_position(raw: Variant) -> Vector2i:
	if raw is Array and raw.size() >= 2:
		return Vector2i(int(raw[0]), int(raw[1]))
	return Vector2i(-1, -1)

func _fill_layout_junk(layout: Dictionary) -> void:
	var empty_cells: Dictionary = {}
	for raw_pos in layout.get("empty_cells", []):
		empty_cells[_layout_position(raw_pos)] = true
	for raw_cobweb in layout.get("cobweb_items", []):
		var pos := _layout_position(raw_cobweb.get("position", []))
		if is_cell_free(pos) and not empty_cells.has(pos):
			var cobwebbed := spawn_item(String(raw_cobweb.get("item_id", "")), pos, false)
			if cobwebbed != null:
				cobwebbed.has_cobweb = true
	var pool: Array = layout.get("covered_item_pool", [])
	if pool.is_empty():
		return
	var seed := int(layout.get("seed", 0))
	for y in ROWS:
		for x in COLUMNS:
			var pos := Vector2i(x, y)
			if not is_cell_free(pos) or empty_cells.has(pos):
				continue
			var item_id := String(pool[(y * COLUMNS + x + seed) % pool.size()])
			var covered := spawn_item(item_id, pos, false)
			if covered != null:
				covered.is_locked = true

func _backfill_active_layout() -> void:
	var layout := _load_active_layout()
	if layout.is_empty():
		return
	_fill_layout_junk(layout)
	_layout_version = BOARD_LAYOUT_VERSION
func is_producer_unlocked(producer_item_id: String) -> bool:
	var rule: Dictionary = PRODUCER_UNLOCK_RULES.get(producer_item_id, {})
	match String(rule.get("kind", "")):
		"always":
			return true
		"quest":
			return ResidenceManager.is_quest_complete(String(rule.get("id", "")))
		"story_flag":
			return bool(GameManager.get_story_flag(String(rule.get("id", "")), false))
		"vehicle":
			return VehicleManager.is_discovered(String(rule.get("id", "")))
		_:
			return false

func get_producer_unlock_label(producer_item_id: String) -> String:
	return String(PRODUCER_UNLOCK_RULES.get(producer_item_id, {}).get("label", "Unknown milestone"))

func get_chain_producer_id(chain_id: String) -> String:
	for producer_item_id in PRODUCER_UNLOCK_RULES:
		var def := ItemDatabase.get_item(producer_item_id)
		if def != null and def.chain_id == chain_id:
			return producer_item_id
	return ""

func get_chain_unlock_label(chain_id: String) -> String:
	var producer_item_id := get_chain_producer_id(chain_id)
	return get_producer_unlock_label(producer_item_id) if not producer_item_id.is_empty() else ""

func is_chain_producer_unlocked(chain_id: String) -> bool:
	var producer_item_id := get_chain_producer_id(chain_id)
	# Reward chains intentionally have no producer and are sourced elsewhere.
	return producer_item_id.is_empty() or is_producer_unlocked(producer_item_id)

func refresh_producer_locks(announce_unlocks: bool = false) -> void:
	for instance_id in items:
		var board_item: BoardItem = items[instance_id]
		var def := ItemDatabase.get_item(board_item.item_id)
		if def == null or not def.is_producer:
			continue
		var was_locked := board_item.is_locked
		board_item.is_locked = not is_producer_unlocked(def.id)
		if announce_unlocks and was_locked and not board_item.is_locked:
			EventBus.producer_unlocked.emit(def.id)
			EventBus.show_toast.emit("Producer unlocked: %s" % def.display_name)

# -- Instance management ------------------------------------------------------

func _make_instance_id() -> String:
	_next_instance_num += 1
	return "bi_%d" % _next_instance_num

func get_item_def(instance_id: String) -> ItemDefinition:
	if not items.has(instance_id):
		return null
	return ItemDatabase.get_item(items[instance_id].item_id)

func is_item_blocked(instance_id: String) -> bool:
	if not items.has(instance_id):
		return true
	var board_item: BoardItem = items[instance_id]
	return board_item.is_locked or board_item.has_cobweb

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
func spawn_item(item_id: String, grid_pos: Vector2i = Vector2i(-1, -1), grant_discovery: bool = true) -> BoardItem:
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

	if grant_discovery:
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
	if is_item_blocked(instance_id):
		return false
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
	if is_item_blocked(instance_id):
		return false
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
	var dragged_item: BoardItem = items[dragged_id]
	var target_item: BoardItem = items[target_id]
	if dragged_item.is_locked or dragged_item.has_cobweb or target_item.is_locked:
		return {"success": false, "reason": "item_blocked"}

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

	var revealed_instance_ids := _reveal_adjacent_boxes(target_pos)
	EventBus.items_merged.emit(dragged_id, target_id, result_item.instance_id)
	return {
		"success": true,
		"resulting_instance_id": result_item.instance_id,
		"resulting_item_id": next_def.id,
		"is_discovery": not was_discovered_before,
		"was_on_board": was_dragged_on_board or target_pos.x >= 0,
		"revealed_instance_ids": revealed_instance_ids,
	}

func _reveal_adjacent_boxes(center: Vector2i) -> Array[String]:
	var revealed: Array[String] = []
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var pos: Vector2i = center + Vector2i(direction)
		var instance_id: String = grid.get(pos, "")
		if instance_id.is_empty() or not items.has(instance_id):
			continue
		var board_item: BoardItem = items[instance_id]
		var def := get_item_def(instance_id)
		if board_item.is_locked and def != null and not def.is_producer:
			board_item.is_locked = false
			board_item.has_cobweb = true
			revealed.append(instance_id)
	return revealed
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
	if board_item.has_cobweb:
		return {"success": false, "reason": "item_blocked"}
	board_item.is_locked = not is_producer_unlocked(def.id)
	if board_item.is_locked:
		return {"success": false, "reason": "producer_locked", "unlock_label": get_producer_unlock_label(def.id)}
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
	return items.has(instance_id) and not is_item_blocked(instance_id) and not get_item_def(instance_id).is_producer

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
		if items[instance_id].item_id == item_id and not is_item_blocked(instance_id):
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
		if items[instance_id].item_id == item_id and not is_item_blocked(instance_id):
			to_remove.append(instance_id)
	if to_remove.size() < count:
		for instance_id in grid.values():
			if to_remove.size() >= count:
				break
			if items[instance_id].item_id == item_id and not is_item_blocked(instance_id):
				to_remove.append(instance_id)
	for instance_id in to_remove:
		_remove_instance(instance_id)
		EventBus.board_item_removed.emit(instance_id)
	return true

# -- Reward-chain collection / gameplay-chain cash-out --------------------

## Whether instance_id can be tapped-to-collect right now, and for what.
## Reward-chain items (energy/coin/xp/token) always qualify per their
## existing per-level formula. Gameplay-chain items qualify wherever their
## already-authored ItemDefinition.sell_value is > 0 (every real level in
## every chain already has one, balanced by whoever set the economy - this
## reuses that data rather than inventing a second, parallel reward table).
## Producer, box-covered, cobwebbed, bubbled, and task-reserved items are
## never collectible, regardless of the above.
func can_collect_reward(instance_id: String) -> Dictionary:
	var def := get_item_def(instance_id)
	if def == null:
		return {"allowed": false, "reason": "invalid_item"}
	if def.is_producer:
		return {"allowed": false, "reason": "producer"}
	if is_item_blocked(instance_id):
		return {"allowed": false, "reason": "blocked"}
	var board_item: BoardItem = items.get(instance_id)
	if board_item != null and board_item.is_in_bubble:
		return {"allowed": false, "reason": "bubbled"}
	var chain := ItemDatabase.get_chain(def.chain_id)
	var reward := _resolve_cash_out_reward(def, chain)
	if reward.is_empty():
		return {"allowed": false, "reason": "not_collectible"}
	if ResidenceManager.is_item_reserved_for_active_task(def.id, active_residence_id, 1):
		return {"allowed": false, "reason": "task_reserved"}
	return {"allowed": true, "reason": "", "resource": reward.get("resource"), "amount": reward.get("amount")}

func _resolve_cash_out_reward(def: ItemDefinition, chain: Dictionary) -> Dictionary:
	if bool(chain.get("is_reward_chain", false)):
		var amount: int = def.level * int(chain.get("per_level_value", 0))
		return {"resource": String(chain.get("resource", "")), "amount": amount} if amount > 0 else {}
	if def.sell_value > 0:
		return {"resource": "coins", "amount": def.sell_value}
	return {}

## Consumes instance_id and grants the resource can_collect_reward() said it
## was worth. Returns false (no mutation at all) if it isn't collectible
## right now for any reason.
func collect_reward(instance_id: String) -> bool:
	var check := can_collect_reward(instance_id)
	if not bool(check.get("allowed", false)):
		return false
	match String(check.get("resource", "")):
		"energy": GameManager.add_energy(int(check.get("amount", 0)))
		"coins": GameManager.add_coins(int(check.get("amount", 0)))
		"xp": GameManager.add_xp(int(check.get("amount", 0)))
		"haven_tokens": GameManager.add_haven_tokens(int(check.get("amount", 0)))
		_: return false
	_remove_instance(instance_id)
	EventBus.board_item_removed.emit(instance_id)
	return true

# -- Save/load -----------------------------------------------------------

func _active_board_to_data() -> Dictionary:
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
		"layout_version": _layout_version,
		"items": items_data,
		"storage_order": storage_order.duplicate(),
		"storage_capacity": storage_capacity,
		"next_instance_num": _next_instance_num,
	}

func to_save_data() -> Dictionary:
	_residence_board_data[active_residence_id] = _active_board_to_data()
	return {
		"format_version": BOARD_FORMAT_VERSION,
		"active_residence_id": active_residence_id,
		"discovered_item_ids": discovered_item_ids.keys(),
		"residences": _residence_board_data.duplicate(true),
	}

func apply_save_data(data: Dictionary) -> void:
	_residence_board_data.clear()
	discovered_item_ids.clear()
	if data.is_empty():
		reset_new_board()
		return

	# SaveManager normally upgrades version-1 data before it reaches here.
	# This fallback keeps direct BoardState fixture loads safe and deterministic.
	if not data.has("residences"):
		active_residence_id = DEFAULT_RESIDENCE_ID
		for item_id in data.get("discovered_item_ids", []):
			discovered_item_ids[item_id] = true
		_apply_active_board_data(data)
		_residence_board_data[active_residence_id] = _active_board_to_data()
		_materialize_missing_boards()
		return

	active_residence_id = String(data.get("active_residence_id", DEFAULT_RESIDENCE_ID))
	if not active_residence_id in RESIDENCE_IDS:
		active_residence_id = DEFAULT_RESIDENCE_ID
	GameManager.profile.current_residence_id = active_residence_id
	for item_id in data.get("discovered_item_ids", []):
		discovered_item_ids[item_id] = true
	var raw_residences: Dictionary = data.get("residences", {})
	for residence_id in raw_residences:
		if residence_id in RESIDENCE_IDS and raw_residences[residence_id] is Dictionary:
			_residence_board_data[residence_id] = raw_residences[residence_id].duplicate(true)
	if _residence_board_data.has(active_residence_id):
		_apply_active_board_data(_residence_board_data[active_residence_id])
	else:
		_reset_active_board()
	_residence_board_data[active_residence_id] = _active_board_to_data()
	_materialize_missing_boards()
	refresh_producer_locks(false)

func _apply_active_board_data(data: Dictionary) -> void:
	items.clear()
	grid.clear()
	storage_order.clear()
	_pending_deletions.clear()
	_layout_version = int(data.get("layout_version", 0))

	if data.is_empty():
		_reset_active_board()
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
	_next_instance_num = data.get("next_instance_num", items.size())

	if items.is_empty():
		_reset_active_board()
	elif _layout_version < BOARD_LAYOUT_VERSION:
		_backfill_active_layout()
