extends Control
## Settings
##
## Every control here reads its initial value from GameManager.settings and
## writes back through GameManager.update_setting(), which persists via
## SaveManager and fires EventBus.settings_changed for anything else
## listening (e.g. AudioManager, ThemeFactory consumers).

@onready var _reset_dialog: ConfirmationDialog = %ResetDialog

func _ready() -> void:
	var s: Dictionary = GameManager.settings

	_bind_slider(%MasterSlider, "master_volume", s.master_volume)
	_bind_slider(%MusicSlider, "music_volume", s.music_volume)
	_bind_slider(%AmbienceSlider, "ambience_volume", s.get("ambience_volume", 0.75))
	_bind_slider(%SfxSlider, "sfx_volume", s.sfx_volume)
	_bind_slider(%UiSlider, "ui_volume", s.get("ui_volume", 0.9))
	_bind_slider(%CharactersSlider, "characters_volume", s.get("characters_volume", 0.85))
	_bind_slider(%ThreatsSlider, "threats_volume", s.get("threats_volume", 0.9))
	_bind_slider(%TextScaleSlider, "text_scale", s.text_scale)

	_bind_toggle(%VibrationToggle, "vibration", s.vibration)
	_bind_toggle(%ReducedMotionToggle, "reduced_motion", s.reduced_motion)
	_bind_toggle(%HighContrastToggle, "high_contrast", s.high_contrast)
	_bind_toggle(%ColorblindToggle, "colorblind_mode", s.colorblind_mode)
	_bind_toggle(%SubtitlesToggle, "subtitles", s.subtitles)
	_bind_graphics_quality(%GraphicsQualityOption, s.graphics_quality)

	%BackButton.pressed.connect(func(): SceneRouter.back("main_menu"))
	%ResetProgressButton.pressed.connect(func(): _reset_dialog.popup_centered())
	_reset_dialog.confirmed.connect(_on_reset_confirmed)

	%ReplayTutorialButton.pressed.connect(func():
		EventBus.show_toast.emit("The guided tutorial arrives in a later development phase.")
	)

func _bind_slider(slider: HSlider, key: String, initial: float) -> void:
	slider.value = initial
	slider.value_changed.connect(func(v): GameManager.update_setting(key, v))

func _bind_toggle(toggle: CheckButton, key: String, initial: bool) -> void:
	toggle.button_pressed = initial
	toggle.toggled.connect(func(v): GameManager.update_setting(key, v))

const _GRAPHICS_QUALITY_VALUES := ["low", "standard", "high"]

func _bind_graphics_quality(option: OptionButton, initial: String) -> void:
	var index: int = _GRAPHICS_QUALITY_VALUES.find(initial)
	option.selected = index if index >= 0 else 1
	option.item_selected.connect(func(i: int): GameManager.update_setting("graphics_quality", _GRAPHICS_QUALITY_VALUES[i]))

func _on_reset_confirmed() -> void:
	GameManager.reset_progress()
	EventBus.show_toast.emit("Progress reset. A fresh game has been started.")
	SceneRouter.go_to("haven", {}, false)
