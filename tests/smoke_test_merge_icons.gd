extends Node
## Verifies that every implemented ItemDefinition resolves to final runtime art.

func _ready() -> void:
	GameManager.new_game()
	var ids := ItemDatabase.get_all_item_ids()
	if ids.size() != 101:
		_fail("expected 101 definitions, found %d" % ids.size())
		return
	for item_id in ids:
		var definition := ItemDatabase.get_item(item_id)
		if definition == null or definition.icon_path.is_empty():
			_fail("%s has no icon path" % item_id)
			return
		if not ResourceLoader.exists(definition.icon_path):
			_fail("%s icon does not exist: %s" % [item_id, definition.icon_path])
			return
		var texture := load(definition.icon_path) as Texture2D
		if texture == null or texture.get_width() != 256 or texture.get_height() != 256:
			_fail("%s icon is not an imported 256x256 texture" % item_id)
			return
		var view := ItemView.new()
		if not view._uses_final_art(definition):
			view.free()
			_fail("%s would still use the procedural placeholder renderer" % item_id)
			return
		view.free()
	print("SMOKE_MERGE_ICONS_OK definitions=101 missing=0 fallback=0")
	get_tree().quit(0)

func _fail(message: String) -> void:
	print("SMOKE_MERGE_ICONS_FAIL: %s" % message)
	get_tree().quit(1)
