extends Control
## DevDiagnostics
##
## Hidden developer menu (only reachable via the 5-tap gesture on the main
## menu title, which is itself only wired up when OS.is_debug_build() is
## true - see main_menu.gd). Never present in a release export.
##
## Functions for systems that exist yet (energy, coins, level, save reset)
## are real and connected to GameManager/SaveManager. Functions for systems
## later phases will build (items, residences, survivors, vehicles,
## defence, scavenging) are shown disabled with a tooltip naming the phase,
## rather than faked - see rule 42, "record unfinished elements honestly".

func _ready() -> void:
	if not GameManager.is_debug_enabled():
		SceneRouter.go_to("main_menu", {}, false)
		return

	%BackButton.pressed.connect(func(): SceneRouter.back("main_menu"))
	%AddEnergyButton.pressed.connect(func(): GameManager.add_energy(20))
	%InfiniteEnergyButton.pressed.connect(func(): GameManager.add_energy(GameManager.resources.energy_max))
	%AddCoinsButton.pressed.connect(func(): GameManager.add_coins(500))
	%AddLevelButton.pressed.connect(func(): GameManager.add_xp(GameManager.xp_needed_for_level(GameManager.profile.level)))
	%ResetSaveButton.pressed.connect(func():
		GameManager.reset_progress()
		EventBus.show_toast.emit("Save reset from developer menu.")
	)

	for key in ["AddItemButton", "UnlockResidenceButton", "TriggerDefenceButton", "TriggerScavengeButton", "UnlockVehicleButton", "HealSurvivorsButton"]:
		var btn: Button = get_node("%" + key)
		btn.disabled = true

func _process(_delta: float) -> void:
	%FpsLabel.text = "FPS: %d" % Engine.get_frames_per_second()
	%SceneLabel.text = "Scene: %s" % SceneRouter.current_scene_key
	%StateLabel.text = "Lv %d | XP %d | Energy %d/%d | Coins %d | Tokens %d" % [
		GameManager.profile.level,
		GameManager.profile.xp,
		GameManager.resources.energy,
		GameManager.resources.energy_max,
		GameManager.resources.coins,
		GameManager.resources.haven_tokens,
	]
