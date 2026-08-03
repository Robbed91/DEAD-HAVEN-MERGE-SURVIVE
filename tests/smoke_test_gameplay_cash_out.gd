extends Node
## Verifies the merge-chain cash-out feature added in the producer-artwork
## follow-up batch: gameplay-chain items (not just the four reward chains)
## can be tapped to collect their already-authored sell_value as coins,
## except where a producer, box, cobweb, bubble, or an active task's
## remaining requirement should still block it.

func _ready() -> void:
	GameManager.new_game()
	if not _check_gameplay_item_collectible():
		return
	if not _check_producer_not_collectible():
		return
	if not _check_boxed_item_not_collectible():
		return
	if not _check_cobwebbed_item_not_collectible():
		return
	if not _check_bubbled_item_not_collectible():
		return
	if not _check_task_reserved_item_not_collectible():
		return
	if not _check_reward_chain_unaffected():
		return
	if not _check_save_reload_after_collect():
		return
	print("SMOKE_GAMEPLAY_CASH_OUT_OK")
	get_tree().quit(0)

## Picks a gameplay-chain item id that ISN'T currently reserved by an active
## Hollow Creek task, rather than assuming any specific id is safe - the
## content is data, and which items are mid-task at a fresh new_game() is
## exactly what the task-reserved check (tested separately below) decides.
func _find_freely_collectible_item_id() -> String:
	for chain_id in ["construction", "tool", "food", "medical", "trap", "fuel", "vehicle_parts", "electronics", "clothing"]:
		var chain := ItemDatabase.get_chain(chain_id)
		for item_id in chain.get("item_ids", []):
			var def := ItemDatabase.get_item(String(item_id))
			if def == null or def.sell_value <= 0:
				continue
			if ResidenceManager.is_item_reserved_for_active_task(def.id, BoardState.active_residence_id, 0):
				continue
			return def.id
	return ""

func _check_gameplay_item_collectible() -> bool:
	var item_id := _find_freely_collectible_item_id()
	if item_id == "":
		_fail("could not find any gameplay-chain item that isn't currently task-reserved")
		return false
	var def := ItemDatabase.get_item(item_id)
	var before_coins: int = GameManager.resources.coins
	var item := BoardState.spawn_item(item_id, BoardState.find_empty_cell(), false)
	if item == null:
		_fail("could not spawn %s for the cash-out check" % item_id)
		return false
	var check := BoardState.can_collect_reward(item.instance_id)
	if not bool(check.get("allowed", false)) or String(check.get("resource", "")) != "coins" or int(check.get("amount", 0)) != def.sell_value:
		_fail("%s should be collectible for exactly its sell_value in coins, got %s" % [item_id, check])
		return false
	if not BoardState.collect_reward(item.instance_id):
		_fail("collect_reward should succeed for a collectible gameplay-chain item")
		return false
	if BoardState.items.has(item.instance_id):
		_fail("collected item should be removed from the board")
		return false
	if GameManager.resources.coins != before_coins + def.sell_value:
		_fail("collecting %s should grant exactly its sell_value in coins" % item_id)
		return false
	print("SMOKE_GAMEPLAY_CASH_OUT: gameplay-chain item collectible for its sell_value OK")
	return true

func _check_producer_not_collectible() -> bool:
	var producer_instance := ""
	for instance_id in BoardState.items:
		var def := BoardState.get_item_def(instance_id)
		if def != null and def.is_producer:
			producer_instance = instance_id
			break
	if producer_instance == "":
		_fail("expected at least one producer on the starting board")
		return false
	var check := BoardState.can_collect_reward(producer_instance)
	if bool(check.get("allowed", false)) or String(check.get("reason", "")) != "producer":
		_fail("a producer should never be collectible, got %s" % [check])
		return false
	if BoardState.collect_reward(producer_instance):
		_fail("collect_reward should refuse a producer")
		return false
	print("SMOKE_GAMEPLAY_CASH_OUT: producer stays uncollectible OK")
	return true

func _check_boxed_item_not_collectible() -> bool:
	var boxed_instance := ""
	for instance_id in BoardState.items:
		var bi: BoardItem = BoardState.items[instance_id]
		if bi.is_locked and not BoardState.get_item_def(instance_id).is_producer:
			boxed_instance = instance_id
			break
	if boxed_instance == "":
		_fail("expected at least one box-covered item on the dense starting board")
		return false
	var check := BoardState.can_collect_reward(boxed_instance)
	if bool(check.get("allowed", false)) or String(check.get("reason", "")) != "blocked":
		_fail("a box-covered item should never be collectible, got %s" % [check])
		return false
	print("SMOKE_GAMEPLAY_CASH_OUT: box-covered item stays uncollectible OK")
	return true

func _check_cobwebbed_item_not_collectible() -> bool:
	var cobweb_instance := ""
	for instance_id in BoardState.items:
		var bi: BoardItem = BoardState.items[instance_id]
		if bi.has_cobweb:
			cobweb_instance = instance_id
			break
	if cobweb_instance == "":
		_fail("expected at least one cobwebbed item on the dense starting board")
		return false
	var check := BoardState.can_collect_reward(cobweb_instance)
	if bool(check.get("allowed", false)) or String(check.get("reason", "")) != "blocked":
		_fail("a cobwebbed item should never be collectible, got %s" % [check])
		return false
	print("SMOKE_GAMEPLAY_CASH_OUT: cobwebbed item stays uncollectible OK")
	return true

func _check_bubbled_item_not_collectible() -> bool:
	var item_id := _find_freely_collectible_item_id()
	if item_id == "":
		_fail("could not find any gameplay-chain item that isn't currently task-reserved")
		return false
	var item := BoardState.spawn_item(item_id, BoardState.find_empty_cell(), false)
	if item == null:
		_fail("could not spawn %s for the bubble check" % item_id)
		return false
	var board_item: BoardItem = BoardState.items[item.instance_id]
	board_item.is_in_bubble = true
	var check := BoardState.can_collect_reward(item.instance_id)
	if bool(check.get("allowed", false)) or String(check.get("reason", "")) != "bubbled":
		_fail("a bubbled item should never be collectible, got %s" % [check])
		return false
	board_item.is_in_bubble = false
	if not bool(BoardState.can_collect_reward(item.instance_id).get("allowed", false)):
		_fail("the same item should become collectible again once its bubble clears")
		return false
	BoardState.collect_reward(item.instance_id)
	print("SMOKE_GAMEPLAY_CASH_OUT: bubbled item stays uncollectible until the bubble clears OK")
	return true

func _check_task_reserved_item_not_collectible() -> bool:
	var residence := ResidenceManager.get_residence("hollow_creek_farmhouse")
	var target_item_id := ""
	var required := 0
	for hotspot in residence.hotspots:
		var quest := ResidenceManager.get_active_quest_for_hotspot(hotspot.id, "hollow_creek_farmhouse")
		if quest == null or quest.requirements.is_empty():
			continue
		target_item_id = String(quest.requirements.keys()[0])
		required = int(quest.requirements[target_item_id])
		break
	if target_item_id == "" or required <= 0:
		_fail("expected at least one active Hollow Creek quest with a requirement")
		return false
	var def := ItemDatabase.get_item(target_item_id)
	if def == null or def.sell_value <= 0:
		_fail("%s has no positive sell_value, can't exercise the reserved-item path" % target_item_id)
		return false

	# Top up on-hand count to exactly the requirement - collecting one should
	# now be refused, since that would drop below what the task still needs.
	while BoardState.count_item(target_item_id) < required:
		if BoardState.spawn_item(target_item_id, BoardState.find_empty_cell(), false) == null:
			_fail("could not top up %s to the required count" % target_item_id)
			return false
	var exact_instance := ""
	for instance_id in BoardState.items:
		if BoardState.items[instance_id].item_id == target_item_id and not BoardState.is_item_blocked(instance_id):
			exact_instance = instance_id
			break
	var check := BoardState.can_collect_reward(exact_instance)
	if bool(check.get("allowed", false)) or String(check.get("reason", "")) != "task_reserved":
		_fail("collecting the last needed %s should be refused as task_reserved, got %s" % [target_item_id, check])
		return false

	# One surplus copy above the requirement should be collectible again.
	var surplus := BoardState.spawn_item(target_item_id, BoardState.find_empty_cell(), false)
	if surplus == null:
		_fail("could not spawn a surplus %s" % target_item_id)
		return false
	if not bool(BoardState.can_collect_reward(surplus.instance_id).get("allowed", false)):
		_fail("a surplus copy above the task requirement should be collectible")
		return false
	if not BoardState.consume_item(target_item_id, BoardState.count_item(target_item_id)):
		_fail("cleanup: could not clear %s instances" % target_item_id)
		return false
	print("SMOKE_GAMEPLAY_CASH_OUT: item still needed by an active task stays reserved OK")
	return true

func _check_reward_chain_unaffected() -> bool:
	var reward_item := BoardState.spawn_item("coin_reward_2", BoardState.find_empty_cell(), false)
	if reward_item == null:
		_fail("could not spawn a reward-chain item")
		return false
	var def := ItemDatabase.get_item("coin_reward_2")
	var chain := ItemDatabase.get_chain("coin_reward")
	var expected: int = def.level * int(chain.get("per_level_value", 0))
	var check := BoardState.can_collect_reward(reward_item.instance_id)
	if int(check.get("amount", 0)) != expected:
		_fail("reward-chain cash-out formula should be unchanged by the gameplay-chain addition")
		return false
	BoardState.collect_reward(reward_item.instance_id)
	print("SMOKE_GAMEPLAY_CASH_OUT: reward-chain formula unaffected OK")
	return true

func _check_save_reload_after_collect() -> bool:
	var item_id := _find_freely_collectible_item_id()
	if item_id == "":
		_fail("could not find any gameplay-chain item that isn't currently task-reserved")
		return false
	var item := BoardState.spawn_item(item_id, BoardState.find_empty_cell(), false)
	if item == null:
		_fail("could not spawn %s for the save/reload check" % item_id)
		return false
	var instance_id := item.instance_id
	if not BoardState.collect_reward(instance_id):
		_fail("collect_reward should succeed before the save/reload check")
		return false
	var coins_after_collect: int = GameManager.resources.coins
	var save_data := GameManager.to_save_data()
	GameManager.apply_save_data(save_data)
	if BoardState.items.has(instance_id):
		_fail("a collected item should not reappear after a save/reload round trip")
		return false
	if GameManager.resources.coins != coins_after_collect:
		_fail("coins granted by collecting should survive a save/reload round trip")
		return false
	print("SMOKE_GAMEPLAY_CASH_OUT: collected state survives save/reload OK")
	return true

func _fail(message: String) -> void:
	print("SMOKE_GAMEPLAY_CASH_OUT_FAIL: %s" % message)
	get_tree().quit(1)
