extends Control
## Splash
##
## Final illustrated splash. Live text avoids baked/generated lettering and
## the same optimised environment keeps boot presentation visually continuous
## with the interactive menu.

const HOLD_SECONDS := 1.1
const FADE_SECONDS := 0.4

@onready var _logo: Control = %Logo

func _ready() -> void:
	# Only auto-advance when Splash is actually the tree's active scene -
	# never when something else instantiates it as a child for inspection
	# (e.g. tests/smoke_test.gd), which must not have its own tree
	# replaced out from under it. Same guard scenes/haven/haven.gd uses.
	if get_tree().current_scene != self:
		return

	modulate.a = 0.0
	_logo.pivot_offset = _logo.size * 0.5
	if GameManager.effects_enabled():
		_logo.scale = Vector2(0.965, 0.965)
	var in_tween := create_tween()
	in_tween.set_parallel(true)
	in_tween.tween_property(self, "modulate:a", 1.0, FADE_SECONDS)
	if GameManager.effects_enabled():
		in_tween.tween_property(_logo, "scale", Vector2.ONE, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	in_tween.set_parallel(false)
	in_tween.tween_interval(HOLD_SECONDS)
	in_tween.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	in_tween.tween_callback(func(): SceneRouter.go_to("main_menu", {}, false))

	gui_input.connect(func(event):
		if event is InputEventScreenTouch or (event is InputEventMouseButton and event.pressed):
			in_tween.kill()
			SceneRouter.go_to("main_menu", {}, false)
	)
