extends Node
## DefenceManager
##
## Hollow Creek Farmhouse's residence milestone 10, "Survive the first
## night attack" (spec section 9) - a single, story-critical event rather
## than a repeatable content category, so unlike items/quests/missions its
## choice data is deliberately kept as inline constants here rather than a
## data/ file (see DEVELOPMENT_LOG.md Phase 7 for why that's a considered
## exception, not an inconsistency).
##
## Gated on every one of the residence's 9 repair hotspots being COMPLETED
## first. On success: a big reward, chapter advances straight from
## "Someone Upstairs" to "The First Wave" (spec's own Chapter 4 content is
## exactly this event; there's no distinct Chapter 3 beat yet - see Known
## issues), and the Redwater Service Station map marker flips from locked
## to "coming soon". On failure: never blocks the game - one random
## already-COMPLETED hotspot reverts to DESTROYED (spec: "damaged
## defences") plus a small coin cost, and the event can simply be
## retried once that hotspot is repaired again.

const RESIDENCE_ID := "hollow_creek_farmhouse"
const ENERGY_COST := 20
const SKILL_TAGS := ["trap", "defence"]
const SKILL_SUCCESS_BONUS := 0.15

## Not const: tests deterministically override success_chance in memory
## (same technique Phase 5's smoke_test_scavenging.gd uses on
## ScavengingMission.encounter_choices), which GDScript disallows on a
## true const container.
var choices := [
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
]

var has_survived_first_wave: bool = false

func reset_new_game() -> void:
	has_survived_first_wave = false

func all_hotspots_complete() -> bool:
	var residence := ResidenceManager.get_residence(RESIDENCE_ID)
	if residence == null:
		return false
	for hotspot in residence.hotspots:
		if ResidenceManager.get_hotspot_state(hotspot.id) != ResidenceHotspot.State.COMPLETED:
			return false
	return true

func can_attempt() -> bool:
	return all_hotspots_complete() and not has_survived_first_wave

func launch(survivor_id: String = "") -> Dictionary:
	if has_survived_first_wave:
		return {"success": false, "reason": "already_survived"}
	if not all_hotspots_complete():
		return {"success": false, "reason": "not_ready"}
	if not GameManager.spend_energy(ENERGY_COST):
		return {"success": false, "reason": "no_energy"}
	return {"success": true, "survivor_id": survivor_id}

func resolve_choice(choice_index: int, survivor_id: String = "") -> Dictionary:
	if choice_index < 0 or choice_index >= choices.size():
		return {"success": false, "reason": "invalid_choice"}
	var choice: Dictionary = choices[choice_index]
	var chance: float = float(choice.success_chance)
	if _survivor_has_matching_skill(survivor_id):
		chance = minf(chance + SKILL_SUCCESS_BONUS, 0.95)
	var succeeded: bool = randf() < chance

	if succeeded:
		has_survived_first_wave = true
		GameManager.add_coins(100)
		GameManager.add_xp(80)
		GameManager.advance_chapter("chapter_4_the_first_wave")
		GameManager.set_story_flag("redwater_unlocked", true)
		EventBus.defence_resolved.emit(true)
		SaveManager.request_autosave()
		return {"success": true, "outcome_success": true, "text": String(choice.success_text)}

	var reverted_hotspot_id := _revert_random_completed_hotspot()
	GameManager.add_coins(-15)
	EventBus.defence_resolved.emit(false)
	SaveManager.request_autosave()
	var text: String = String(choice.failure_text)
	if not reverted_hotspot_id.is_empty():
		var hotspot := ResidenceManager.get_hotspot(RESIDENCE_ID, reverted_hotspot_id)
		if hotspot != null:
			text += " The %s took real damage - it'll need repairing again." % hotspot.display_name
	return {"success": true, "outcome_success": false, "text": text, "reverted_hotspot_id": reverted_hotspot_id}

func _survivor_has_matching_skill(survivor_id: String) -> bool:
	if survivor_id.is_empty():
		return false
	var survivor := CharacterDatabase.get_survivor(survivor_id)
	if survivor == null:
		return false
	for skill in survivor.skills:
		if SKILL_TAGS.has(skill):
			return true
	return false

## Picks one random COMPLETED hotspot and reverts it to DESTROYED, and
## marks its quest incomplete again so it can be re-repaired through the
## normal task-panel flow. Returns the reverted hotspot id, or "" if
## (unexpectedly) none were completed.
func _revert_random_completed_hotspot() -> String:
	var residence := ResidenceManager.get_residence(RESIDENCE_ID)
	if residence == null:
		return ""
	var completed_ids: Array[String] = []
	for hotspot in residence.hotspots:
		if ResidenceManager.get_hotspot_state(hotspot.id) == ResidenceHotspot.State.COMPLETED:
			completed_ids.append(hotspot.id)
	if completed_ids.is_empty():
		return ""
	var hotspot_id: String = completed_ids[randi() % completed_ids.size()]
	ResidenceManager.revert_hotspot(hotspot_id)
	return hotspot_id

func to_save_data() -> Dictionary:
	return {"has_survived_first_wave": has_survived_first_wave}

func apply_save_data(data: Dictionary) -> void:
	has_survived_first_wave = data.get("has_survived_first_wave", false)
