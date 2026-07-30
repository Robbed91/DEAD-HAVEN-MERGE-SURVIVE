extends Node
## ItemDatabase
##
## Loads every ItemDefinition under data/items/ once at startup and indexes
## it by id and by chain. Read-only at runtime - item content changes by
## editing/adding .tres files, never by mutating anything here.

const ITEMS_DIR := "res://data/items/"
const CHAINS_DIR := "res://data/chains/"

var _definitions: Dictionary = {} # item_id -> ItemDefinition
var _chains: Dictionary = {} # chain_id -> Dictionary (parsed chain json)
var _chain_order: Array[String] = []

func _ready() -> void:
	_load_definitions()
	_load_chains()

func _load_definitions() -> void:
	var dir := DirAccess.open(ITEMS_DIR)
	if dir == null:
		push_error("ItemDatabase: could not open %s" % ITEMS_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var def: ItemDefinition = load(ITEMS_DIR + file_name)
			if def == null:
				push_error("ItemDatabase: failed to load %s" % file_name)
			elif def.id.is_empty():
				push_error("ItemDatabase: %s has an empty id" % file_name)
			else:
				_definitions[def.id] = def
		file_name = dir.get_next()
	dir.list_dir_end()

func _load_chains() -> void:
	var dir := DirAccess.open(CHAINS_DIR)
	if dir == null:
		push_error("ItemDatabase: could not open %s" % CHAINS_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var f := FileAccess.open(CHAINS_DIR + file_name, FileAccess.READ)
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			f.close()
			if typeof(parsed) == TYPE_DICTIONARY:
				_chains[parsed.chain_id] = parsed
				_chain_order.append(parsed.chain_id)
		file_name = dir.get_next()
	dir.list_dir_end()
	_chain_order.sort()

func get_item(item_id: String) -> ItemDefinition:
	if not _definitions.has(item_id):
		push_warning("ItemDatabase: unknown item id '%s'" % item_id)
		return null
	return _definitions[item_id]

func has_item(item_id: String) -> bool:
	return _definitions.has(item_id)

func get_all_item_ids() -> Array:
	return _definitions.keys()

func get_chain(chain_id: String) -> Dictionary:
	return _chains.get(chain_id, {})

func get_all_chain_ids() -> Array[String]:
	return _chain_order.duplicate()

func get_producer_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in _definitions:
		if _definitions[id].is_producer:
			ids.append(id)
	return ids

## Returns the ItemDefinition for the next level in item_def's chain, or
## null if item_def is already at (or above) its chain's max level.
func get_next_level(item_def: ItemDefinition) -> ItemDefinition:
	if item_def.level >= item_def.max_level_in_chain:
		return null
	return get_item("%s_%d" % [item_def.chain_id, item_def.level + 1])

func is_reward_chain(chain_id: String) -> bool:
	return _chains.get(chain_id, {}).get("is_reward_chain", false)
