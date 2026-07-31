extends Node
## ScavengingManager
##
## Owns scavenging mission content and the two-step choice-driven flow
## (spec section 10): launch_mission() spends energy to send a survivor
## out, resolve_choice() rolls the chosen encounter option against its
## success_chance and grants loot. Failure is never game-blocking - at
## most a small coin/energy/morale cost, never a lost item or survivor.

const MISSIONS_DIR := "res://data/scavenging/"

var _missions: Dictionary = {} # id -> ScavengingMission
var completed_mission_ids: Dictionary = {} # mission_id -> times completed (flavor/stats only)

func _ready() -> void:
	var dir := DirAccess.open(MISSIONS_DIR)
	if dir == null:
		push_error("ScavengingManager: could not open %s" % MISSIONS_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var mission: ScavengingMission = load(MISSIONS_DIR + file_name)
			if mission == null:
				push_error("ScavengingManager: failed to load %s" % file_name)
			else:
				_missions[mission.id] = mission
		file_name = dir.get_next()
	dir.list_dir_end()

func get_mission(id: String) -> ScavengingMission:
	return _missions.get(id)

func get_all_mission_ids() -> Array:
	return _missions.keys()

## ScavengingMission.story_condition previously existed on the schema but
## was never read anywhere (see DEVELOPMENT_LOG.md Phase 13) - every
## mission was always available regardless of its value. A non-empty
## story_condition is a GameManager story-flag key that must be true for
## this mission to be launchable or shown on the World Map; empty means
## always available (every Phase 5 location).
func is_available(mission_id: String) -> bool:
	var mission := get_mission(mission_id)
	if mission == null:
		return false
	if mission.story_condition.is_empty():
		return true
	return GameManager.get_story_flag(mission.story_condition, false)

## Spends the mission's energy cost. Does not resolve an outcome - that is
## a separate step (resolve_choice) so the UI can show the encounter's
## choices before anything is committed.
func launch_mission(mission_id: String) -> Dictionary:
	var mission := get_mission(mission_id)
	if mission == null:
		return {"success": false, "reason": "unknown_mission"}
	if not is_available(mission_id):
		return {"success": false, "reason": "not_available"}
	if not GameManager.spend_energy(mission.energy_cost):
		return {"success": false, "reason": "no_energy"}
	return {"success": true}

const SKILL_SUCCESS_BONUS := 0.15

## Rolls choice_index's success_chance (boosted if the sent survivor has a
## skill matching one of the mission's recommended_equipment tags - Phase
## 6 closing the Phase 5 "no skill effects" known issue), grants the
## mission's base loot_table plus the choice's success_loot (on success)
## or applies its failure_penalty (on failure), and returns display text
## for the UI.
func resolve_choice(mission_id: String, choice_index: int, survivor_id: String = "") -> Dictionary:
	var mission := get_mission(mission_id)
	if mission == null or choice_index < 0 or choice_index >= mission.encounter_choices.size():
		return {"success": false, "reason": "invalid_choice"}
	var choice: Dictionary = mission.encounter_choices[choice_index]
	var chance: float = float(choice.get("success_chance", 0.5))
	if _survivor_has_matching_skill(survivor_id, mission.recommended_equipment):
		chance = minf(chance + SKILL_SUCCESS_BONUS, 0.95)
	var succeeded: bool = randf() < chance

	_grant_rewards(mission.loot_table)
	var outcome_text: String
	if succeeded:
		_grant_rewards(choice.get("success_loot", {}))
		outcome_text = String(choice.get("success_text", "You made it back safely."))
	else:
		_apply_penalty(choice.get("failure_penalty", {}))
		outcome_text = String(choice.get("failure_text", "It didn't go as planned, but you made it back."))

	completed_mission_ids[mission_id] = int(completed_mission_ids.get(mission_id, 0)) + 1
	SaveManager.request_autosave()
	EventBus.mission_completed.emit(mission_id, succeeded)
	return {"success": true, "outcome_success": succeeded, "text": outcome_text}

func _survivor_has_matching_skill(survivor_id: String, tags: PackedStringArray) -> bool:
	if survivor_id.is_empty():
		return false
	var survivor := CharacterDatabase.get_survivor(survivor_id)
	if survivor == null:
		return false
	for skill in survivor.skills:
		if tags.has(skill):
			return true
	return false

func _grant_rewards(rewards: Dictionary) -> void:
	for key in rewards:
		var amount: int = int(rewards[key])
		if amount == 0:
			continue
		match String(key):
			"coins": GameManager.add_coins(amount)
			"energy": GameManager.add_energy(amount)
			"xp": GameManager.add_xp(amount)
			"haven_tokens": GameManager.add_haven_tokens(amount)
			"food": GameManager.add_food(amount)
			"medicine": GameManager.add_medicine(amount)
			"fuel": GameManager.add_fuel(amount)
			_:
				if ItemDatabase.has_item(String(key)):
					for i in amount:
						BoardState.spawn_item(String(key), BoardState.find_empty_cell())

## Failure is deliberately mild - a small resource cost, never a removed
## board item or lost survivor (spec: "Failure should not permanently end
## the game", written for defence events but applied here on the same
## principle).
func _apply_penalty(penalty: Dictionary) -> void:
	for key in penalty:
		var amount: int = int(penalty[key])
		if amount == 0:
			continue
		match String(key):
			"coins": GameManager.add_coins(-amount)
			"energy": GameManager.add_energy(-amount)
			"morale": GameManager.add_morale(-amount)

func to_save_data() -> Dictionary:
	return {"completed_mission_ids": completed_mission_ids.duplicate()}

func apply_save_data(data: Dictionary) -> void:
	completed_mission_ids.clear()
	for id in data.get("completed_mission_ids", {}):
		completed_mission_ids[id] = int(data["completed_mission_ids"][id])
