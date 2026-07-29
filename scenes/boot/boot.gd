extends Node
## Boot
##
## Entry point (project.godot run/main_scene). Applies the UI theme, then
## routes straight to the main menu. Kept intentionally tiny; if a real
## splash/logo screen is wanted later it belongs here, before the route.

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme(
		GameManager.settings.get("text_scale", 1.0),
		GameManager.settings.get("high_contrast", false)
	)
	SceneRouter.go_to("main_menu", {}, false)
