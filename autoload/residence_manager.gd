extends Node
## ResidenceManager
##
## Owns residence/hotspot/quest state. Content (ResidenceDefinition,
## ResidenceHotspot, QuestDefinition) loads once from data/residences/ and
## data/quests/ and is never mutated; only the two Dictionaries below
## (which hotspot is COMPLETED, which quest ids are done) are runtime state
## and get persisted.
##
## Phase 3 uses a simple two-state hotspot model: DESTROYED (default) or
## COMPLETED, flipped when that hotspot's one linked quest completes.
## ResidenceHotspot.State also defines PARTIALLY_CLEARED/UNDER_REPAIR/
## UPGRADED for hotspots with multiple sequential tasks - unused until a
## hotspot actually has more than one required_task_ids entry.

const RESIDENCES_DIR := "res://data/residences/"
const QUESTS_DIR := "res://data/quests/"

var _residences: Dictionary = {} # id -> ResidenceDefinition
var _quests: Dictionary = {} # id -> QuestDefinition

var hotspot_states: Dictionary = {} # hotspot_id -> ResidenceHotspot.State (int)
var completed_quest_ids: Dictionary = {} # quest_id -> true

func _ready() -> void:
	_load_dir(RESIDENCES_DIR, _residences)
	_load_dir(QUESTS_DIR, _quests)

func _load_dir(path: String, into: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("ResidenceManager: could not open %s" % path)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res: Resource = load(path + file_name)
			if res == null:
				push_error("ResidenceManager: failed to load %s" % file_name)
			else:
				into[res.id] = res
		file_name = dir.get_next()
	dir.list_dir_end()

func reset_new_game() -> void:
	hotspot_states.clear()
	completed_quest_ids.clear()

func get_residence(id: String) -> ResidenceDefinition:
	return _residences.get(id)

func get_quest(id: String) -> QuestDefinition:
	return _quests.get(id)

func get_hotspot(residence_id: String, hotspot_id: String) -> ResidenceHotspot:
	var res := get_residence(residence_id)
	if res == null:
		return null
	for h in res.hotspots:
		if h.id == hotspot_id:
			return h
	return null

func get_hotspot_state(hotspot_id: String) -> int:
	return hotspot_states.get(hotspot_id, ResidenceHotspot.State.DESTROYED)

func is_quest_complete(quest_id: String) -> bool:
	return completed_quest_ids.has(quest_id)

## First not-yet-complete quest tied to hotspot_id, or null once every
## task on that hotspot is done.
func get_active_quest_for_hotspot(hotspot_id: String, residence_id: String = "hollow_creek_farmhouse") -> QuestDefinition:
	var hotspot := get_hotspot(residence_id, hotspot_id)
	if hotspot == null:
		return null
	for quest_id in hotspot.required_task_ids:
		if not is_quest_complete(quest_id):
			return get_quest(quest_id)
	return null

func requirements_met(quest_id: String) -> bool:
	var quest := get_quest(quest_id)
	if quest == null:
		return false
	for item_id in quest.requirements:
		if BoardState.count_item(item_id) < int(quest.requirements[item_id]):
			return false
	return true

## Verifies requirements, consumes items, grants rewards (including the
## "unlock_survivor" and "set_story_flag" special-case reward keys),
## advances the linked hotspot, and persists. Returns a result dict rather
## than throwing, matching BoardState's tap_producer()/try_merge() pattern.
func try_complete_quest(quest_id: String) -> Dictionary:
	if is_quest_complete(quest_id):
		return {"success": false, "reason": "already_complete"}
	var quest := get_quest(quest_id)
	if quest == null:
		return {"success": false, "reason": "unknown_quest"}
	if not requirements_met(quest_id):
		return {"success": false, "reason": "requirements_not_met"}

	for item_id in quest.requirements:
		BoardState.consume_item(item_id, int(quest.requirements[item_id]))

	completed_quest_ids[quest_id] = true

	if quest.rewards.has("coins"):
		GameManager.add_coins(int(quest.rewards.coins))
	if quest.rewards.has("xp"):
		GameManager.add_xp(int(quest.rewards.xp))
	if quest.rewards.has("energy"):
		GameManager.add_energy(int(quest.rewards.energy))
	if quest.rewards.has("unlock_survivor"):
		GameManager.unlock_survivor(String(quest.rewards.unlock_survivor))
	if quest.rewards.has("set_story_flag"):
		GameManager.set_story_flag(String(quest.rewards.set_story_flag), true)

	if not quest.residence_hotspot_id.is_empty():
		hotspot_states[quest.residence_hotspot_id] = ResidenceHotspot.State.COMPLETED
		EventBus.hotspot_state_changed.emit(quest.residence_hotspot_id, ResidenceHotspot.State.COMPLETED)

	# Chapter 1 (spec: "The Open Door") ends once the front door is secured
	# and the merge board is in use; Chapter 2 ("Someone Upstairs") opens
	# with the noises that lead to finding Noah. Chapter 4 ("The First
	# Wave") is set by DefenceManager on a successful Hollow Creek defence.
	# Chapter 5 ("The Station") opens once Lena is found at Redwater. There
	# is no chapter_3 beat yet - see DEVELOPMENT_LOG.md Known issues.
	if quest_id == "q_secure_front_door":
		GameManager.advance_chapter("chapter_2_someone_upstairs")
	if quest_id == "q_rescue_lena":
		GameManager.advance_chapter("chapter_5_the_station")

	_maybe_discover_vehicle()

	EventBus.quest_completed.emit(quest_id)
	SaveManager.request_autosave()
	return {"success": true, "hotspot_id": quest.residence_hotspot_id}

## The delivery van (spec: found while following Chapter 5's radio signal)
## is simplified here to "discovered once every Hollow Creek Farmhouse
## hotspot is repaired" - a concrete, earned milestone that doesn't need
## Chapter 5's still-unbuilt story beat to exist first. See
## DEVELOPMENT_LOG.md Phase 6 Known issues.
func _maybe_discover_vehicle() -> void:
	if VehicleManager.is_discovered("delivery_van"):
		return
	var residence := get_residence("hollow_creek_farmhouse")
	if residence == null:
		return
	for hotspot in residence.hotspots:
		if get_hotspot_state(hotspot.id) != ResidenceHotspot.State.COMPLETED:
			return
	VehicleManager.discover_vehicle("delivery_van")
	EventBus.show_toast.emit("You found an old delivery van behind the barn.")

## Sends a hotspot back to DESTROYED and un-marks its quest(s) as
## complete, so it can be repaired again through the normal task-panel
## flow. Used by DefenceManager on a failed defence ("damaged defences" -
## spec section 15's failure consequences) - never called for any other
## reason, since normal play only ever advances a hotspot forward.
func revert_hotspot(hotspot_id: String, residence_id: String = "hollow_creek_farmhouse") -> void:
	var hotspot := get_hotspot(residence_id, hotspot_id)
	if hotspot == null:
		return
	hotspot_states[hotspot_id] = ResidenceHotspot.State.DESTROYED
	for quest_id in hotspot.required_task_ids:
		completed_quest_ids.erase(quest_id)
	EventBus.hotspot_state_changed.emit(hotspot_id, ResidenceHotspot.State.DESTROYED)

func to_save_data() -> Dictionary:
	return {
		"hotspot_states": hotspot_states.duplicate(),
		"completed_quest_ids": completed_quest_ids.keys(),
	}

func apply_save_data(data: Dictionary) -> void:
	hotspot_states.clear()
	completed_quest_ids.clear()
	for hotspot_id in data.get("hotspot_states", {}):
		hotspot_states[hotspot_id] = int(data["hotspot_states"][hotspot_id])
	for quest_id in data.get("completed_quest_ids", []):
		completed_quest_ids[quest_id] = true
