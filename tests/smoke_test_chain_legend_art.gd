extends Node
## Verifies the merge board's chain-highlight legend shows each chain's real
## final producer art instead of the procedural swatch it used before.

func _ready() -> void:
	GameManager.new_game()
	var gameplay_chain_ids: Array = []
	for chain_id in ItemDatabase.get_all_chain_ids():
		if not ItemDatabase.is_reward_chain(chain_id):
			gameplay_chain_ids.append(chain_id)
	if gameplay_chain_ids.size() != 9:
		_fail("expected 9 gameplay chains in the legend, found %d" % gameplay_chain_ids.size())
		return
	for chain_id in gameplay_chain_ids:
		var icon := ChainLegendIcon.new()
		icon.chain_id = chain_id
		icon._ready()
		if not icon.has_final_illustration():
			icon.free()
			_fail("%s legend swatch still falls back to the procedural renderer" % chain_id)
			return
		icon.free()
	print("SMOKE_CHAIN_LEGEND_ART_OK chains=%d" % gameplay_chain_ids.size())
	get_tree().quit(0)

func _fail(message: String) -> void:
	print("SMOKE_CHAIN_LEGEND_ART_FAIL: %s" % message)
	get_tree().quit(1)
