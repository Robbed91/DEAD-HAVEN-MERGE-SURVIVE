extends Node
## DialogueManager
##
## Loads every DialogueEntry once at startup and knows how to launch the
## Dialogue screen at a given entry id. The screen itself (scenes/dialogue/)
## owns walking the chain/branches at runtime; this autoload is just the
## content index plus the single entry point every trigger (Haven arrival,
## a completed quest, ...) calls through.

const DIALOGUE_DIR := "res://data/dialogue/"

var _entries: Dictionary = {} # id -> DialogueEntry

func _ready() -> void:
	var dir := DirAccess.open(DIALOGUE_DIR)
	if dir == null:
		push_error("DialogueManager: could not open %s" % DIALOGUE_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var entry: DialogueEntry = load(DIALOGUE_DIR + file_name)
			if entry == null:
				push_error("DialogueManager: failed to load %s" % file_name)
			else:
				_entries[entry.id] = entry
		file_name = dir.get_next()
	dir.list_dir_end()

func get_entry(id: String) -> DialogueEntry:
	if not _entries.has(id):
		push_warning("DialogueManager: unknown dialogue entry '%s'" % id)
		return null
	return _entries[id]

func has_entry(id: String) -> bool:
	return _entries.has(id)

## Routes to the Dialogue screen starting at entry_id; return_scene_key is
## where it routes back to once the chain ends (default "haven", since
## every current trigger fires from there).
func start_dialogue(entry_id: String, return_scene_key: String = "haven") -> void:
	if not has_entry(entry_id):
		push_warning("DialogueManager: start_dialogue called with unknown id '%s', skipping" % entry_id)
		return
	SceneRouter.go_to("dialogue", {"start_id": entry_id, "return_scene_key": return_scene_key})
