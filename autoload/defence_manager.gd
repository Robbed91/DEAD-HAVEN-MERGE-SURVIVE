extends Node
## DefenceManager
##
## A residence's climactic "survive the attack" milestone (spec section
## 15) - generalized in Phase 8 to support more than one residence's
## event (Hollow Creek's "first wave", Redwater's "defend the station")
## through one shared autoload rather than a duplicate manager per
## residence. Event definitions and their choice data are deliberately
## kept as inline data here rather than a data/ file - these are a
## handful of unique, story-critical events, not a repeatable content
## category like items/quests/missions (see DEVELOPMENT_LOG.md Phase 7).
##
## Each event is gated on every hotspot of its residence being COMPLETED
## first. On success: rewards, and whatever chapter/story-flag effects
## that event defines. On failure: never blocks the game - one random
## already-COMPLETED hotspot on that residence reverts to DESTROYED (spec:
## "damaged defences") plus a small coin cost, and the event can simply be
## retried once that hotspot is repaired again.

const SKILL_SUCCESS_BONUS := 0.15

## event_id -> {residence_id, energy_cost, skill_tags, success_coins,
## success_xp, success_chapter (optional), success_flag (optional)}
var events := {
	"hollow_creek_first_wave": {
		"residence_id": "hollow_creek_farmhouse",
		"energy_cost": 20,
		"skill_tags": ["trap", "defence"],
		"success_coins": 100,
		"success_xp": 80,
		"success_chapter": "chapter_4_the_first_wave",
		"success_flag": "redwater_unlocked",
	},
	"redwater_defence": {
		"residence_id": "redwater_service_station",
		"energy_cost": 25,
		"skill_tags": ["trap", "defence"],
		"success_coins": 150,
		"success_xp": 120,
		"success_chapter": "",
		"success_flag": "",
	},
}

## event_id -> Array[Dictionary] of {text, success_chance, success_text,
## failure_text}. Not const - tests deterministically override
## success_chance in memory (same technique Phase 5's
## smoke_test_scavenging.gd uses on ScavengingMission.encounter_choices),
## which GDScript disallows on a true const container.
var event_choices := {
	"hollow_creek_first_wave": [
		{
			"text": "Hold the barricades and fight through it.", "success_chance": 0.55,
			"success_text": "The barricades hold. Exhausted but intact, you watch the last of them wander off past dawn.",
			"failure_text": "A section gives way under the weight. You force it back before anyone's hurt, but the frame is wrecked.",
		},
		{
			"text": "Retreat to the storm cellar and wait it out.", "success_chance": 0.7,
			"success_text": "Quiet and cramped, but safe. By morning the yard is empty again.",
			"failure_text": "The cellar door doesn't hold as well as you'd hoped. You lose ground forcing it shut again.",
		},
		{
			"text": "Use the traps you've set to thin them out first.", "success_chance": 0.6,
			"success_text": "The traps do their job. What's left is manageable, and the barricades hold easy.",
			"failure_text": "Half the traps fail to trigger. It's a rough night, but you make it to morning.",
		},
	],
	"redwater_defence": [
		{
			"text": "Hold the forecourt and defend the pumps.", "success_chance": 0.5,
			"success_text": "The line holds. Whoever - or whatever - was testing the barrier gives up before dawn.",
			"failure_text": "The barrier buckles under the pressure. You fall back and reinforce it from the inside.",
		},
		{
			"text": "Fall back into the garage and barricade the bay doors.", "success_chance": 0.65,
			"success_text": "The bay doors hold better than expected. A rough night, but a quiet one by the end.",
			"failure_text": "Something gets a door partway open before you force it shut again.",
		},
		{
			"text": "Use the drainage tunnel to slip out and draw them off.", "success_chance": 0.6,
			"success_text": "Risky, but it works - you lead them off the property entirely.",
			"failure_text": "It nearly goes wrong in the tunnel. You make it back, but rattled and short on supplies.",
		},
	],
}

var survived_events: Dictionary = {} # event_id -> true

func reset_new_game() -> void:
	survived_events.clear()

func has_survived(event_id: String) -> bool:
	return survived_events.has(event_id)

func all_hotspots_complete(event_id: String) -> bool:
	var event: Dictionary = events.get(event_id, {})
	if event.is_empty():
		return false
	var residence := ResidenceManager.get_residence(String(event.residence_id))
	if residence == null:
		return false
	for hotspot in residence.hotspots:
		if ResidenceManager.get_hotspot_state(hotspot.id) != ResidenceHotspot.State.COMPLETED:
			return false
	return true

func can_attempt(event_id: String) -> bool:
	return events.has(event_id) and all_hotspots_complete(event_id) and not has_survived(event_id)

func launch(event_id: String, survivor_id: String = "") -> Dictionary:
	var event: Dictionary = events.get(event_id, {})
	if event.is_empty():
		return {"success": false, "reason": "unknown_event"}
	if has_survived(event_id):
		return {"success": false, "reason": "already_survived"}
	if not all_hotspots_complete(event_id):
		return {"success": false, "reason": "not_ready"}
	if not GameManager.spend_energy(int(event.energy_cost)):
		return {"success": false, "reason": "no_energy"}
	return {"success": true, "survivor_id": survivor_id}

func resolve_choice(event_id: String, choice_index: int, survivor_id: String = "") -> Dictionary:
	var event: Dictionary = events.get(event_id, {})
	if event.is_empty():
		return {"success": false, "reason": "unknown_event"}
	var choice_list: Array = event_choices.get(event_id, [])
	if choice_index < 0 or choice_index >= choice_list.size():
		return {"success": false, "reason": "invalid_choice"}
	var choice: Dictionary = choice_list[choice_index]
	var chance: float = float(choice.success_chance)
	if _survivor_has_matching_skill(survivor_id, event.skill_tags):
		chance = minf(chance + SKILL_SUCCESS_BONUS, 0.95)
	var succeeded: bool = randf() < chance
	var residence_id: String = String(event.residence_id)

	if succeeded:
		survived_events[event_id] = true
		GameManager.add_coins(int(event.success_coins))
		GameManager.add_xp(int(event.success_xp))
		if not String(event.success_chapter).is_empty():
			GameManager.advance_chapter(String(event.success_chapter))
		if not String(event.success_flag).is_empty():
			GameManager.set_story_flag(String(event.success_flag), true)
		EventBus.defence_resolved.emit(true)
		SaveManager.request_autosave()
		return {"success": true, "outcome_success": true, "text": String(choice.success_text)}

	var reverted_hotspot_id := _revert_random_completed_hotspot(residence_id)
	GameManager.add_coins(-15)
	EventBus.defence_resolved.emit(false)
	SaveManager.request_autosave()
	var text: String = String(choice.failure_text)
	if not reverted_hotspot_id.is_empty():
		var hotspot := ResidenceManager.get_hotspot(residence_id, reverted_hotspot_id)
		if hotspot != null:
			text += " The %s took real damage - it'll need repairing again." % hotspot.display_name
	return {"success": true, "outcome_success": false, "text": text, "reverted_hotspot_id": reverted_hotspot_id}

func _survivor_has_matching_skill(survivor_id: String, tags: Array) -> bool:
	if survivor_id.is_empty():
		return false
	var survivor := CharacterDatabase.get_survivor(survivor_id)
	if survivor == null:
		return false
	for skill in survivor.skills:
		if tags.has(skill):
			return true
	return false

## Picks one random COMPLETED hotspot on the given residence and reverts
## it to DESTROYED, and marks its quest incomplete again so it can be
## re-repaired through the normal task-panel flow. Returns the reverted
## hotspot id, or "" if (unexpectedly) none were completed.
func _revert_random_completed_hotspot(residence_id: String) -> String:
	var residence := ResidenceManager.get_residence(residence_id)
	if residence == null:
		return ""
	var completed_ids: Array[String] = []
	for hotspot in residence.hotspots:
		if ResidenceManager.get_hotspot_state(hotspot.id) == ResidenceHotspot.State.COMPLETED:
			completed_ids.append(hotspot.id)
	if completed_ids.is_empty():
		return ""
	var hotspot_id: String = completed_ids[randi() % completed_ids.size()]
	ResidenceManager.revert_hotspot(hotspot_id, residence_id)
	return hotspot_id

func to_save_data() -> Dictionary:
	return {"survived_events": survived_events.keys()}

func apply_save_data(data: Dictionary) -> void:
	survived_events.clear()
	for event_id in data.get("survived_events", []):
		survived_events[event_id] = true
