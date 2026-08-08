extends Node
## Boot
##
## Entry point (project.godot run/main_scene). Applies the UI theme, then
## routes to the splash screen (scenes/splash/), which shows the logo
## briefly before continuing to the main menu itself. Kept intentionally
## tiny - Boot itself never renders anything.

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(
		GameManager.settings.get("text_scale", 1.0),
		GameManager.settings.get("high_contrast", false),
		GameManager.settings.get("colorblind_mode", false)
	)
	SceneRouter.go_to("splash", {}, false)
