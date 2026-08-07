extends RefCounted
class_name ScavengeMergeState
## Self-contained, throwaway merge puzzle used to resolve a scavenging
## encounter choice (see DEVELOPMENT_LOG.md 2026-08-05 "scavenging becomes a
## merge challenge"). Deliberately independent of BoardState/BoardItem -
## this grid is generated fresh per attempt and discarded on
## win/lose/retreat, so it never touches the player's real residence boards
## or save data. Reuses ItemDatabase/ItemDefinition purely for chain/level
## art and naming; no producers, cobwebs, locks, or storage exist here.

const COLUMNS := 5
const ROWS := 5
const ALL_CHAIN_IDS := ["clothing", "construction", "electronics", "food", "fuel", "medical", "tool", "trap", "vehicle_parts"]

var grid: Dictionary = {} # Vector2i -> item_id (String)
var moves_left: int
var target_level: int
var chain_ids: Array[String] = []
var won := false

## Deterministic per mission (same location always salvages the same two
## material types, so repeat visits feel consistent) but the actual board
## layout is randomised per attempt.
static func chain_ids_for_mission(mission_id: String) -> Array[String]:
	var h: int = absi(mission_id.hash())
	var primary: int = h % ALL_CHAIN_IDS.size()
	var secondary: int = (h / ALL_CHAIN_IDS.size()) % (ALL_CHAIN_IDS.size() - 1)
	if secondary >= primary:
		secondary += 1
	var result: Array[String] = [ALL_CHAIN_IDS[primary], ALL_CHAIN_IDS[secondary]]
	return result

func setup(p_chain_ids: Array[String], p_moves: int, p_target_level: int = 3) -> void:
	chain_ids = p_chain_ids
	moves_left = p_moves
	target_level = p_target_level
	won = false
	grid.clear()
	_seed_board()

## Guarantees a solvable board: enough level-1 tiles of the primary chain to
## reach target_level through repeated pairwise merges, plus secondary-chain
## tiles as real (mergeable, not just decorative) alternative material.
func _seed_board() -> void:
	var all_cells: Array[Vector2i] = []
	for x in COLUMNS:
		for y in ROWS:
			all_cells.append(Vector2i(x, y))
	all_cells.shuffle()

	var required_primary: int = int(pow(2, target_level - 1))
	var tiles: Array[String] = []
	for i in required_primary:
		tiles.append("%s_1" % chain_ids[0])
	# Extra primary-chain material beyond the strict minimum, plus a denser
	# secondary count - the first version left ~60% of the grid empty, which
	# read as a broken/unfinished board rather than a real merge puzzle.
	var bonus_primary: int = mini(4, (all_cells.size() - tiles.size()) / 3)
	for i in bonus_primary:
		tiles.append("%s_%d" % [chain_ids[0], 1 + (i % 2)])
	var secondary_count: int = mini(10, all_cells.size() - tiles.size() - 2)
	for i in secondary_count:
		tiles.append("%s_%d" % [chain_ids[1], 1 + (i % 2)])
	tiles.shuffle()

	for i in tiles.size():
		grid[all_cells[i]] = tiles[i]

func item_id_at(pos: Vector2i) -> String:
	return String(grid.get(pos, ""))

func is_cell_free(pos: Vector2i) -> bool:
	return not grid.has(pos)

func find_empty_cell() -> Vector2i:
	for x in COLUMNS:
		for y in ROWS:
			var pos := Vector2i(x, y)
			if is_cell_free(pos):
				return pos
	return Vector2i(-1, -1)

## Mirrors BoardState.try_merge()'s rule (same chain + same level -> next
## level) without any of the producer/lock/cobweb/storage machinery this
## throwaway board has no use for. A move is only spent on a successful
## merge, matching how "moves" are understood in the merge-puzzle genre.
func try_merge(from_pos: Vector2i, to_pos: Vector2i) -> Dictionary:
	if from_pos == to_pos or not grid.has(from_pos) or not grid.has(to_pos):
		return {"success": false}
	var from_def := ItemDatabase.get_item(item_id_at(from_pos))
	var to_def := ItemDatabase.get_item(item_id_at(to_pos))
	if from_def == null or to_def == null:
		return {"success": false}
	if from_def.chain_id != to_def.chain_id or from_def.level != to_def.level:
		return {"success": false}
	var next_def := ItemDatabase.get_next_level(to_def)
	if next_def == null:
		return {"success": false}
	grid.erase(from_pos)
	grid[to_pos] = next_def.id
	moves_left = maxi(0, moves_left - 1)
	if next_def.level >= target_level:
		won = true
	return {"success": true, "resulting_item_id": next_def.id, "reached_target": won}

func move(from_pos: Vector2i, to_pos: Vector2i) -> bool:
	if not is_cell_free(to_pos) or not grid.has(from_pos):
		return false
	grid[to_pos] = grid[from_pos]
	grid.erase(from_pos)
	return true

func is_won() -> bool:
	return won

func is_lost() -> bool:
	return not won and moves_left <= 0
