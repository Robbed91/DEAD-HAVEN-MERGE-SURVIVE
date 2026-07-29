extends PanelContainer
## BottomNav
##
## Persistent bottom navigation: Haven / Merge / Map / Survivors / Inventory.
## Instanced on every main screen with `active_tab` set to that screen's key
## so the current tab renders highlighted. Inventory has no screen yet, so
## its button surfaces an honest "coming later" toast instead of doing
## nothing or silently failing.

@export var active_tab: String = "haven"

@onready var _buttons: Dictionary = {
	"haven": %HavenButton,
	"merge_board": %MergeButton,
	"world_map": %MapButton,
	"survivors": %SurvivorsButton,
	"inventory": %InventoryButton,
}

func _ready() -> void:
	%HavenButton.pressed.connect(func(): _navigate("haven"))
	%MergeButton.pressed.connect(func(): _navigate("merge_board"))
	%MapButton.pressed.connect(func(): _navigate("world_map"))
	%SurvivorsButton.pressed.connect(func(): _navigate("survivors"))
	%InventoryButton.pressed.connect(func(): EventBus.show_toast.emit("Inventory arrives in a later development phase."))
	_highlight_active()

func _navigate(key: String) -> void:
	if key == active_tab:
		return
	SceneRouter.go_to(key)

func _highlight_active() -> void:
	for key in _buttons.keys():
		var btn: Button = _buttons[key]
		btn.button_pressed = (key == active_tab)
