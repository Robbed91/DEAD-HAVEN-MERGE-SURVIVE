extends Control
## Splash
##
## The actual splash screen (spec: "Required visual screens" #1) - shows
## the stacked logo (assets/branding/logo/logo_stacked_dark.svg) on the
## Haven charcoal background for a brief beat, then routes to the main
## menu. Boot previously routed straight to main_menu with a comment
## saying a real splash screen "belongs here" when one existed; this is
## that screen, now that a real logo asset exists to show on it.

const HOLD_SECONDS := 1.1
const FADE_SECONDS := 0.4

@onready var _logo: TextureRect = %Logo

func _ready() -> void:
	# Only auto-advance when Splash is actually the tree's active scene -
	# never when something else instantiates it as a child for inspection
	# (e.g. tests/smoke_test.gd), which must not have its own tree
	# replaced out from under it. Same guard scenes/haven/haven.gd uses.
	if get_tree().current_scene != self:
		return

	modulate.a = 0.0
	var in_tween := create_tween()
	in_tween.tween_property(self, "modulate:a", 1.0, FADE_SECONDS)
	in_tween.tween_interval(HOLD_SECONDS)
	in_tween.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	in_tween.tween_callback(func(): SceneRouter.go_to("main_menu", {}, false))

	gui_input.connect(func(event):
		if event is InputEventScreenTouch or (event is InputEventMouseButton and event.pressed):
			in_tween.kill()
			SceneRouter.go_to("main_menu", {}, false)
	)
