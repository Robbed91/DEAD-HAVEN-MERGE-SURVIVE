extends Control
## Survivors
##
## Phase 1 roster placeholder. Shows the cast named in the design spec so
## the screen is real and readable, without the full SurvivorDefinition-
## backed trust/skills/relationship system that Phase 6 builds.

## "id" matches GameManager.unlock_survivor()'s survivor_id (currently only
## Noah, unlocked by completing the q_rescue_noah residence task in Phase
## 3) - every other survivor is still a Phase-1-style always-locked
## placeholder until Phase 6 builds real recruitment for them.
const ROSTER := [
	{"id": "mara_vale", "name": "Mara Vale", "role": "You", "color": Color("6b7a56"), "always_unlocked": true},
	{"id": "noah_vance", "name": "Noah Vance", "role": "Carpenter", "color": Color("8a3c1f"), "always_unlocked": false},
	{"id": "lena_ortiz", "name": "Lena Ortiz", "role": "Mechanic", "color": Color("4d5940"), "always_unlocked": false},
	{"id": "imogen_shaw", "name": "Dr Imogen Shaw", "role": "Physician", "color": Color("6b4a35"), "always_unlocked": false},
	{"id": "riley_chen", "name": "Riley Chen", "role": "Radio Technician", "color": Color("8a8f8a"), "always_unlocked": false},
	{"id": "caleb_rusk", "name": "Caleb Rusk", "role": "Security", "color": Color("b5502b"), "always_unlocked": false},
]

func _ready() -> void:
	var grid: GridContainer = %RosterGrid
	for entry in ROSTER:
		var locked: bool = not entry.always_unlocked and not GameManager.is_survivor_unlocked(entry.id)
		grid.add_child(_build_card(entry, locked))

func _build_card(entry: Dictionary, locked: bool) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 190)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	var portrait := SurvivorSilhouette.new()
	portrait.custom_minimum_size = Vector2(96, 96)
	portrait.silhouette_color = entry.color
	portrait.locked = locked
	vbox.add_child(portrait)

	var name_label := Label.new()
	name_label.text = entry.name if not locked else "???"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var role_label := Label.new()
	role_label.text = entry.role if not locked else "Not yet found"
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.modulate.a = 0.65
	role_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(role_label)

	return card
