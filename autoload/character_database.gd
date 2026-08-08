extends Node
## CharacterDatabase
##
## Loads every SurvivorDefinition once at startup. Read-only at runtime,
## same as ItemDatabase - recruitment/trust/health are all tracked
## elsewhere (GameManager.unlocked_survivor_ids for now; a real per
## -survivor runtime-state store is Phase 6+ follow-up work once trust/
## health/morale actually do something beyond display - see
## DEVELOPMENT_LOG.md Known issues).

const CHARACTERS_DIR := "res://data/characters/"
const PackedDirectoryScript := preload("res://scripts/data/packed_directory.gd")

var _survivors: Dictionary = {} # id -> SurvivorDefinition

func _ready() -> void:
	var dir := DirAccess.open(CHARACTERS_DIR)
	if dir == null:
		push_error("CharacterDatabase: could not open %s" % CHARACTERS_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var runtime_name: String = PackedDirectoryScript.resource_name(file_name)
		if not dir.current_is_dir() and not runtime_name.is_empty():
			var def: SurvivorDefinition = load(CHARACTERS_DIR + runtime_name)
			if def == null:
				push_error("CharacterDatabase: failed to load %s" % runtime_name)
			else:
				_survivors[def.id] = def
		file_name = dir.get_next()
	dir.list_dir_end()
	if OS.is_debug_build():
		print("RUNTIME_CATALOG characters=%d" % _survivors.size())

func get_survivor(id: String) -> SurvivorDefinition:
	return _survivors.get(id)

func has_survivor(id: String) -> bool:
	return _survivors.has(id)

func get_all_survivor_ids() -> Array:
	return _survivors.keys()
