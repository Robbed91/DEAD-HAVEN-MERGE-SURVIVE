extends CanvasLayer
## Toast
##
## Small non-blocking message surfaced via EventBus.show_toast. Used
## throughout early development to give honest feedback on screens/buttons
## whose backing system isn't built yet, instead of leaving them dead.

@onready var _label: Label = %ToastLabel
@onready var _panel: PanelContainer = %ToastPanel

var _tween: Tween

func _ready() -> void:
	layer = 90
	_panel.theme = get_window().theme
	_panel.theme_type_variation = "CharcoalPanel"
	_panel.modulate.a = 0.0
	EventBus.show_toast.connect(_on_show_toast)

func _on_show_toast(text: String) -> void:
	_label.text = text
	if _tween:
		_tween.kill()
	var reduced: bool = GameManager.settings.get("reduced_motion", false)
	var hold := 1.6
	var fade := 0.05 if reduced else 0.22
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, fade)
	_tween.tween_interval(hold)
	_tween.tween_property(_panel, "modulate:a", 0.0, fade)
