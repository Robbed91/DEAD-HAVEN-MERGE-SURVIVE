extends Node
## SaveManager
##
## Local JSON persistence. One active save slot for the initial build
## (see README for the multi-slot upgrade path). Every write goes to a
## temp file first and the previous good save is kept as a .bak so a crash
## mid-write can never destroy both copies.

const SAVE_DIR := "user://saves/"
const SAVE_FILE := SAVE_DIR + "slot1.json"
const SAVE_FILE_TMP := SAVE_DIR + "slot1.json.tmp"
const BACKUP_FILE := SAVE_DIR + "slot1.bak.json"
const CURRENT_SAVE_VERSION := 2

## Debounce autosave so rapid-fire actions (several merges in a row, etc.)
## don't hammer disk I/O; the timer coalesces them into one write.
var _autosave_timer: Timer

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = 1.5
	_autosave_timer.one_shot = true
	_autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(_autosave_timer)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_CRASH:
			if GameManager.is_game_active:
				save_game()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

func request_autosave() -> void:
	if not GameManager.is_game_active:
		return
	_autosave_timer.start()

func _on_autosave_timeout() -> void:
	save_game()

## Writes the current GameManager state to disk. Returns true on success.
func save_game() -> bool:
	var data := GameManager.to_save_data()
	data["save_version"] = CURRENT_SAVE_VERSION
	data["saved_at_unix"] = Time.get_unix_time_from_system()

	var json_text := JSON.stringify(data, "\t")

	var tmp := FileAccess.open(SAVE_FILE_TMP, FileAccess.WRITE)
	if tmp == null:
		push_error("SaveManager: could not open temp save file (%s)" % error_string(FileAccess.get_open_error()))
		return false
	tmp.store_string(json_text)
	tmp.close()

	# Promote the last known-good save to backup before overwriting it.
	if FileAccess.file_exists(SAVE_FILE):
		DirAccess.copy_absolute(SAVE_FILE, BACKUP_FILE)

	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		push_error("SaveManager: could not open save directory to promote temp file")
		return false
	var rename_err := dir.rename(SAVE_FILE_TMP, SAVE_FILE)
	if rename_err != OK:
		push_error("SaveManager: failed to promote temp save (%s)" % error_string(rename_err))
		return false

	EventBus.game_saved.emit()
	return true

## Loads the save, falling back to the backup copy if the primary file is
## missing or corrupt. Returns an empty Dictionary only if both are unusable
## - callers must treat that as "no save", never as a crash.
func load_game() -> Dictionary:
	var data := _try_load(SAVE_FILE)
	if not data.is_empty():
		return _migrate_if_needed(data)

	push_warning("SaveManager: primary save unreadable, attempting backup")
	data = _try_load(BACKUP_FILE)
	if not data.is_empty():
		EventBus.save_load_failed.emit("primary_corrupt_used_backup")
		return _migrate_if_needed(data)

	push_error("SaveManager: no readable save or backup found")
	EventBus.save_load_failed.emit("no_readable_save")
	return {}

func _try_load(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: save file at '%s' did not parse to a Dictionary" % path)
		return {}
	return parsed

## Placeholder migration hook. Bump CURRENT_SAVE_VERSION and add a branch
## here whenever the save schema changes shape; never delete old branches
## while any shipped save could still be on that version.
func _migrate_if_needed(data: Dictionary) -> Dictionary:
	var version: int = data.get("save_version", 1)
	if version < CURRENT_SAVE_VERSION:
		push_warning("SaveManager: migrating save from version %d to %d" % [version, CURRENT_SAVE_VERSION])
	if version < 2:
		var legacy_board: Dictionary = data.get("board", {})
		var profile: Dictionary = data.get("profile", {})
		var residence_id := String(profile.get("current_residence_id", BoardState.DEFAULT_RESIDENCE_ID))
		if not residence_id in BoardState.RESIDENCE_IDS:
			residence_id = BoardState.DEFAULT_RESIDENCE_ID
		var discoveries: Array = legacy_board.get("discovered_item_ids", [])
		legacy_board.erase("discovered_item_ids")
		data["board"] = {
			"format_version": BoardState.BOARD_FORMAT_VERSION,
			"active_residence_id": residence_id,
			"discovered_item_ids": discoveries,
			"residences": {residence_id: legacy_board},
		}
		data["save_version"] = 2
	return data

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_FILE):
		DirAccess.remove_absolute(SAVE_FILE)
	if FileAccess.file_exists(BACKUP_FILE):
		DirAccess.remove_absolute(BACKUP_FILE)
