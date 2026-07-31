
extends Node
## Save/reload verification for each major Saint Mercy visual-state threshold.

const RESIDENCE_ID := "saint_mercy_hospital"
const EVENT_ID := "saint_mercy_defence"
const COUNTS := [0, 1, 3, 5, 8, 8]
const NAMES := ["destroyed", "cleared", "temporarily_repaired", "habitable", "defended", "fully_upgraded"]

func _ready() -> void:
	var residence := ResidenceManager.get_residence(RESIDENCE_ID)
	if residence == null or residence.hotspots.size() != 8:
		_fail("residence/hotspot schema changed")
		return
	for state_index in COUNTS.size():
		GameManager.new_game()
		for hotspot_index in residence.hotspots.size():
			var hotspot = residence.hotspots[hotspot_index]
			ResidenceManager.hotspot_states[hotspot.id] = ResidenceHotspot.State.COMPLETED if hotspot_index < COUNTS[state_index] else ResidenceHotspot.State.DESTROYED
		if state_index == 5:
			DefenceManager.survived_events[EVENT_ID] = true
		SaveManager.save_game()
		for hotspot in residence.hotspots:
			ResidenceManager.hotspot_states[hotspot.id] = ResidenceHotspot.State.DESTROYED
		DefenceManager.survived_events.erase(EVENT_ID)
		var loaded := SaveManager.load_game()
		if loaded.is_empty():
			_fail("%s state returned empty save" % NAMES[state_index])
			return
		GameManager.apply_save_data(loaded)
		var restored := 0
		for hotspot in residence.hotspots:
			if ResidenceManager.get_hotspot_state(hotspot.id) == ResidenceHotspot.State.COMPLETED:
				restored += 1
		if restored != COUNTS[state_index] or DefenceManager.has_survived(EVENT_ID) != (state_index == 5):
			_fail("%s state did not round-trip" % NAMES[state_index])
			return
	print("SMOKE_SAINT_MERCY_VISUAL_STATES_OK states=6")
	get_tree().quit(0)

func _fail(message: String) -> void:
	print("SMOKE_SAINT_MERCY_VISUAL_STATES_FAIL: %s" % message)
	get_tree().quit(1)

