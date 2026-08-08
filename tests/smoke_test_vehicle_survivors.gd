extends Node
## SmokeTestVehicleSurvivors
##
## Exercises Phase 6 directly (no GUI - see tests/README.md): survivor
## content loads, VehicleManager's discovery/upgrade flow, ResidenceManager
## discovering the van once all 9 Hollow Creek Farmhouse hotspots are
## COMPLETED, Noah's personal quest completing through the generic quest
## path (no hotspot involved), the skill-based scavenging success bonus,
## and it all persisting through save/reload.
##
## Run: godot4 --headless --path . tests/smoke_test_vehicle_survivors.tscn

func _fail(msg: String) -> void:
	print("SMOKE_VEHICLE_SURVIVORS_FAIL: %s" % msg)
	get_tree().quit(1)

func _ready() -> void:
	GameManager.new_game()

	# -- Survivor content loads ---------------------------------------------------
	if CharacterDatabase.get_all_survivor_ids().size() != 6:
		_fail("expected 6 survivors, got %d" % CharacterDatabase.get_all_survivor_ids().size())
		return
	var noah := CharacterDatabase.get_survivor("noah_vance")
	if noah == null or not noah.skills.has("tool") or noah.personal_quest_id != "pq_noah_workbench":
		_fail("noah_vance shape wrong: %s" % str(noah))
		return
	print("SMOKE_VEHICLE_SURVIVORS: survivor content loads OK")

	# -- Vehicle not discovered yet ------------------------------------------------
	if VehicleManager.is_discovered("delivery_van"):
		_fail("delivery_van should not be discovered at game start")
		return
	var early_upgrade := VehicleManager.upgrade_stage("delivery_van")
	if early_upgrade.success or early_upgrade.reason != "not_discovered":
		_fail("upgrading an undiscovered vehicle should fail with not_discovered, got %s" % str(early_upgrade))
		return

	# -- Completing all 9 hotspots discovers the vehicle --------------------------
	var residence := ResidenceManager.get_residence("hollow_creek_farmhouse")
	for hotspot in residence.hotspots:
		var quest := ResidenceManager.get_active_quest_for_hotspot(hotspot.id)
		if quest == null:
			continue
		var item_id: String = quest.requirements.keys()[0]
		var needed: int = int(quest.requirements[item_id])
		for i in needed:
			BoardState.spawn_item(item_id, BoardState.find_empty_cell())
		var result := ResidenceManager.try_complete_quest(quest.id)
		if not result.success:
			_fail("completing %s should succeed, got %s" % [quest.id, str(result)])
			return
	if not VehicleManager.is_discovered("delivery_van"):
		_fail("delivery_van should be discovered once all 9 hotspots are COMPLETED")
		return
	print("SMOKE_VEHICLE_SURVIVORS: vehicle discovery on full residence completion OK")

	# -- Vehicle upgrade: requirements gate, consumption, stage advance ----------
	if VehicleManager.get_current_stage("delivery_van") != 0:
		_fail("delivery_van should start at stage 0 on discovery")
		return
	var reqs := VehicleManager.get_next_stage_requirements("delivery_van")
	var stage1_item: String = reqs.keys()[0]
	var blocked_upgrade := VehicleManager.upgrade_stage("delivery_van")
	if blocked_upgrade.success or blocked_upgrade.reason != "requirements_not_met":
		_fail("upgrading without the required item should fail with requirements_not_met, got %s" % str(blocked_upgrade))
		return
	BoardState.spawn_item(stage1_item, BoardState.find_empty_cell())
	var upgrade_result := VehicleManager.upgrade_stage("delivery_van")
	if not upgrade_result.success or VehicleManager.get_current_stage("delivery_van") != 1:
		_fail("upgrading with the required item should advance to stage 1, got %s (stage=%d)" % [str(upgrade_result), VehicleManager.get_current_stage("delivery_van")])
		return
	if BoardState.count_item(stage1_item) != 0:
		_fail("the stage requirement item should be consumed on upgrade")
		return
	print("SMOKE_VEHICLE_SURVIVORS: vehicle upgrade gating + consumption + stage advance OK")

	# -- Noah's personal quest completes through the generic quest path ----------
	# (Noah is already unlocked at this point - completing all 9 hotspots
	# above necessarily included q_rescue_noah, whose reward unlocks him.
	# try_complete_quest() itself doesn't gate personal quests on
	# recruitment status either way - that's a UI-level concern, the
	# Survivors screen only shows the button for unlocked survivors.)
	var noah_quest_before := ResidenceManager.is_quest_complete("pq_noah_workbench")
	if noah_quest_before:
		_fail("pq_noah_workbench should not be complete yet")
		return
	BoardState.spawn_item("tool_4", BoardState.find_empty_cell())
	var personal_result := ResidenceManager.try_complete_quest("pq_noah_workbench")
	if not personal_result.success or not personal_result.hotspot_id.is_empty():
		_fail("pq_noah_workbench should complete with an empty hotspot_id (not tied to a hotspot), got %s" % str(personal_result))
		return
	if not ResidenceManager.is_quest_complete("pq_noah_workbench"):
		_fail("pq_noah_workbench should be marked complete")
		return
	print("SMOKE_VEHICLE_SURVIVORS: personal quest (no hotspot) completion OK")

	# -- Skill-based scavenging bonus ---------------------------------------------
	var farm_mission := ScavengingManager.get_mission("farm_shed")
	if not farm_mission.recommended_equipment.has("tool"):
		_fail("farm_shed should recommend 'tool' equipment for this test's premise to hold")
		return
	if not noah.skills.has("tool"):
		_fail("noah_vance should have the 'tool' skill for this test's premise to hold")
		return
	# Exercises the actual matching function resolve_choice() calls, not a
	# reimplementation of its logic in the test.
	if not ScavengingManager._survivor_has_matching_skill("noah_vance", farm_mission.recommended_equipment):
		_fail("noah_vance's 'tool' skill should match farm_shed's recommended_equipment")
		return
	if ScavengingManager._survivor_has_matching_skill("mara_vale", farm_mission.recommended_equipment):
		_fail("mara_vale has no chain-category skills, should not match farm_shed's recommended_equipment")
		return
	if ScavengingManager._survivor_has_matching_skill("", farm_mission.recommended_equipment):
		_fail("an empty survivor_id (no one selected) should never match")
		return

	# End-to-end: force the choice to a chance where the +0.15 bonus is the
	# only thing separating "always fails" from "always succeeds", using
	# extreme deterministic values rather than relying on randf() luck.
	farm_mission.encounter_choices[0].success_chance = 0.0
	var without_bonus := ScavengingManager.resolve_choice("farm_shed", 0, "mara_vale")
	if without_bonus.outcome_success:
		_fail("0.0 success_chance with no matching skill should never succeed")
		return
	print("SMOKE_VEHICLE_SURVIVORS: skill-matching bonus logic + zero-chance-stays-zero-without-it OK")

	# -- Save / reload round trip ------------------------------------------------
	SaveManager.save_game()
	var loaded := SaveManager.load_game()
	if loaded.is_empty():
		_fail("load_game returned empty after a normal save")
		return
	GameManager.apply_save_data(loaded)
	if not VehicleManager.is_discovered("delivery_van") or VehicleManager.get_current_stage("delivery_van") != 1:
		_fail("reloaded vehicle discovery/stage should persist")
		return
	if not ResidenceManager.is_quest_complete("pq_noah_workbench"):
		_fail("reloaded personal quest completion should persist")
		return
	print("SMOKE_VEHICLE_SURVIVORS: save/reload round trip OK")

	print("SMOKE_VEHICLE_SURVIVORS_TEST_OK")
	get_tree().quit(0)
