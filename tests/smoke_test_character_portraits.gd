extends Node
## Verifies data-driven Mara portraits, safe fallback art, and the fixed board shape.

func _ready() -> void:
	GameManager.new_game()
	var mara: SurvivorDefinition = CharacterDatabase.get_survivor("mara_vale")
	if mara == null:
		_fail("Mara definition did not load")
		return
	for expression_name in ["neutral", "concerned", "injured"]:
		var path := str(mara.expressions.get(expression_name, mara.portraits.get(expression_name, "")))
		if path.is_empty() or not ResourceLoader.exists(path):
			_fail("Mara %s portrait is not registered to an existing texture" % expression_name)
			return

	var portrait := SurvivorSilhouette.new()
	portrait.survivor_id = "mara_vale"
	portrait.expression = "concerned"
	portrait.size = Vector2(160, 160)
	add_child(portrait)
	if not portrait.is_using_texture_portrait() or portrait.is_using_procedural_fallback():
		_fail("Mara concerned state did not select registered final art")
		return
	portrait.queue_free()

	var fallback := SurvivorSilhouette.new()
	fallback.survivor_id = "missing_test_survivor"
	fallback.size = Vector2(160, 160)
	add_child(fallback)
	if fallback.is_using_texture_portrait() or not fallback.is_using_procedural_fallback():
		_fail("missing portrait did not select the procedural fallback")
		return
	fallback.queue_free()

	if BoardState.COLUMNS != 7 or BoardState.ROWS != 9:
		_fail("merge-board dimensions changed from 7x9")
		return
	var board: Node = load("res://scenes/merge_board/merge_board.tscn").instantiate()
	add_child(board)
	var grid := board.get_node("Layout/BoardMargin/BoardGrid") as GridContainer
	if grid == null or grid.columns != 7 or grid.get_child_count() != 63:
		_fail("runtime merge grid is not exactly 7 columns by 9 rows")
		return
	print("SMOKE_CHARACTER_PORTRAITS_OK data_portraits=3 fallback=pass grid=7x9")
	get_tree().quit(0)

func _fail(message: String) -> void:
	print("SMOKE_CHARACTER_PORTRAITS_FAIL: %s" % message)
	get_tree().quit(1)
