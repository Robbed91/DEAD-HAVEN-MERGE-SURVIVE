extends Control
## Survivors
##
## Phase 1 roster placeholder. Shows the cast named in the design spec so
## the screen is real and readable, without the full SurvivorDefinition-
## backed trust/skills/relationship system that Phase 6 builds.

const ROSTER := [
	{"name": "Mara Vale", "role": "You", "color": Color("6b7a56"), "locked": false},
	{"name": "Noah Vance", "role": "Carpenter", "color": Color("8a3c1f"), "locked": true},
	{"name": "Lena Ortiz", "role": "Mechanic", "color": Color("4d5940"), "locked": true},
	{"name": "Dr Imogen Shaw", "role": "Physician", "color": Color("6b4a35"), "locked": true},
	{"name": "Riley Chen", "role": "Radio Technician", "color": Color("8a8f8a"), "locked": true},
	{"name": "Caleb Rusk", "role": "Security", "color": Color("b5502b"), "locked": true},
]

func _ready() -> void:
	var grid: GridContainer = %RosterGrid
	for entry in ROSTER:
		grid.add_child(_build_card(entry))

func _build_card(entry: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 190)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	var portrait := SurvivorSilhouette.new()
	portrait.custom_minimum_size = Vector2(96, 96)
	portrait.silhouette_color = entry.color
	portrait.locked = entry.locked
	vbox.add_child(portrait)

	var name_label := Label.new()
	name_label.text = entry.name if not entry.locked else "???"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var role_label := Label.new()
	role_label.text = entry.role if not entry.locked else "Not yet found"
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.modulate.a = 0.65
	role_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(role_label)

	return card
