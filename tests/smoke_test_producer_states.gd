extends Node
## Verifies every producer resolves its authored producer_<state>.png for
## normal/selected/active/low-charge/empty/recharge, that a locked producer
## stays interaction-blocked regardless of which visual state is showing, and
## that presentation-only state changes never mutate real gameplay data.

const STATES := ["selected", "active", "low_charge", "empty", "recharge"]

func _ready() -> void:
	GameManager.new_game()
	var producer_ids := BoardState.PRODUCER_UNLOCK_RULES.keys()
	if producer_ids.size() != 9:
		_fail("expected 9 producer definitions, found %d" % producer_ids.size())
		return

	for producer_id in producer_ids:
		var def := ItemDatabase.get_item(producer_id)
		if def == null or not def.is_producer:
			_fail("%s is not a valid producer definition" % producer_id)
			return
		if not _check_normal_state(producer_id, def):
			return
		if not _check_selected_state(producer_id, def):
			return
		if not _check_active_state(producer_id, def):
			return
		if not _check_low_charge_state(producer_id, def):
			return
		if not _check_empty_state(producer_id, def):
			return
		if not _check_recharge_state(producer_id, def):
			return
		if not _check_locked_stays_blocked(producer_id, def):
			return
		if not _check_visual_state_is_presentation_only(producer_id, def):
			return

	print("SMOKE_PRODUCER_STATES_OK producers=9 states=%d" % STATES.size())
	get_tree().quit(0)

func _make_view(instance_id: String, board_item: BoardItem) -> ItemView:
	BoardState.items[instance_id] = board_item
	var view := ItemView.new()
	view.instance_id = instance_id
	return view

func _expected_path(def: ItemDefinition, state: String) -> String:
	return "res://assets/items/%s/producer_%s.png" % [def.chain_id, state]

func _check_normal_state(producer_id: String, def: ItemDefinition) -> bool:
	var instance_id := "test_%s_normal" % producer_id
	var board_item := BoardItem.new()
	board_item.instance_id = instance_id
	board_item.item_id = producer_id
	board_item.charge_count = -1
	var view := _make_view(instance_id, board_item)
	var resolved := view._resolve_producer_state_path(def, board_item)
	view.free()
	BoardState.items.erase(instance_id)
	if resolved != "":
		_fail("%s idle state unexpectedly resolved a state texture: %s" % [producer_id, resolved])
		return false
	if not ResourceLoader.exists(def.icon_path):
		_fail("%s normal icon_path missing: %s" % [producer_id, def.icon_path])
		return false
	return true

func _check_selected_state(producer_id: String, def: ItemDefinition) -> bool:
	var instance_id := "test_%s_selected" % producer_id
	var board_item := BoardItem.new()
	board_item.instance_id = instance_id
	board_item.item_id = producer_id
	board_item.charge_count = -1
	var view := _make_view(instance_id, board_item)
	view.set_selected_visual(true)
	var ok := _assert_state_path(producer_id, def, "selected", view._resolve_producer_state_path(def, board_item))
	view.free()
	BoardState.items.erase(instance_id)
	return ok

func _check_active_state(producer_id: String, def: ItemDefinition) -> bool:
	var instance_id := "test_%s_active" % producer_id
	var board_item := BoardItem.new()
	board_item.instance_id = instance_id
	board_item.item_id = producer_id
	board_item.charge_count = -1
	var view := _make_view(instance_id, board_item)
	view.play_producer_visual_state("active", 0.0)
	var ok := _assert_state_path(producer_id, def, "active", view._resolve_producer_state_path(def, board_item))
	view.free()
	BoardState.items.erase(instance_id)
	return ok

func _check_low_charge_state(producer_id: String, def: ItemDefinition) -> bool:
	var instance_id := "test_%s_low_charge" % producer_id
	var board_item := BoardItem.new()
	board_item.instance_id = instance_id
	board_item.item_id = producer_id
	# Force a finite-charge scenario regardless of this producer's real
	# producer_charges, so the resolver itself is proven correct even for
	# chains that are currently unlimited-charge in live data.
	board_item.charge_count = 1
	var view := _make_view(instance_id, board_item)
	var forced_def := def.duplicate()
	forced_def.producer_charges = 4
	var ok := _assert_state_path(producer_id, def, "low_charge", view._resolve_producer_state_path(forced_def, board_item))
	view.free()
	BoardState.items.erase(instance_id)
	return ok

func _check_empty_state(producer_id: String, def: ItemDefinition) -> bool:
	var instance_id := "test_%s_empty" % producer_id
	var board_item := BoardItem.new()
	board_item.instance_id = instance_id
	board_item.item_id = producer_id
	board_item.charge_count = 0
	var view := _make_view(instance_id, board_item)
	var ok := _assert_state_path(producer_id, def, "empty", view._resolve_producer_state_path(def, board_item))
	view.free()
	BoardState.items.erase(instance_id)
	return ok

func _check_recharge_state(producer_id: String, def: ItemDefinition) -> bool:
	var instance_id := "test_%s_recharge" % producer_id
	var board_item := BoardItem.new()
	board_item.instance_id = instance_id
	board_item.item_id = producer_id
	board_item.charge_count = -1
	board_item.cooldown_end_unix = Time.get_unix_time_from_system() + 60.0
	var view := _make_view(instance_id, board_item)
	var ok := _assert_state_path(producer_id, def, "recharge", view._resolve_producer_state_path(def, board_item))
	view.free()
	BoardState.items.erase(instance_id)
	return ok

func _assert_state_path(producer_id: String, def: ItemDefinition, state: String, resolved: String) -> bool:
	var expected := _expected_path(def, state)
	if not ResourceLoader.exists(expected):
		_fail("%s missing authored art for state '%s': %s" % [producer_id, state, expected])
		return false
	if resolved != expected:
		_fail("%s state '%s' resolved '%s', expected '%s'" % [producer_id, state, resolved, expected])
		return false
	return true

func _check_locked_stays_blocked(producer_id: String, def: ItemDefinition) -> bool:
	var instance_id := "test_%s_locked" % producer_id
	var board_item := BoardItem.new()
	board_item.instance_id = instance_id
	board_item.item_id = producer_id
	board_item.charge_count = -1
	board_item.is_locked = true
	BoardState.items[instance_id] = board_item
	var view := ItemView.new()
	view.instance_id = instance_id
	view.set_selected_visual(true)
	view.play_producer_visual_state("active", 0.0)
	var blocked := BoardState.is_item_blocked(instance_id)
	var drag_data: Variant = view._get_drag_data(Vector2.ZERO)
	view.free()
	BoardState.items.erase(instance_id)
	if not blocked:
		_fail("%s stayed unblocked while is_locked=true" % producer_id)
		return false
	if drag_data != null:
		_fail("%s allowed a drag while locked, regardless of selected/active visual state" % producer_id)
		return false
	return true

func _check_visual_state_is_presentation_only(producer_id: String, def: ItemDefinition) -> bool:
	var instance_id := "test_%s_presentation" % producer_id
	var board_item := BoardItem.new()
	board_item.instance_id = instance_id
	board_item.item_id = producer_id
	board_item.charge_count = -1
	board_item.cooldown_end_unix = 0.0
	board_item.is_locked = false
	var before_charge := board_item.charge_count
	var before_cooldown := board_item.cooldown_end_unix
	var before_locked := board_item.is_locked
	var view := _make_view(instance_id, board_item)
	view.set_selected_visual(true)
	view.play_producer_visual_state("active", 0.0)
	view.play_producer_visual_state("empty", 0.0)
	var ok := true
	if board_item.charge_count != before_charge or board_item.cooldown_end_unix != before_cooldown or board_item.is_locked != before_locked:
		_fail("%s visual state calls mutated gameplay data" % producer_id)
		ok = false
	view.free()
	BoardState.items.erase(instance_id)
	return ok

func _fail(message: String) -> void:
	print("SMOKE_PRODUCER_STATES_FAIL: %s" % message)
	get_tree().quit(1)
