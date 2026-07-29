extends Control
## MainMenu

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _overwrite_dialog: ConfirmationDialog = %OverwriteDialog
@onready var _title_label: Label = %TitleLabel

var _title_tap_count: int = 0
var _title_tap_reset_timer: Timer

func _ready() -> void:
	_continue_button.disabled = not SaveManager.has_save()
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	%SettingsButton.pressed.connect(func(): SceneRouter.go_to("settings"))
	%QuitButton.pressed.connect(func(): get_tree().quit())
	_overwrite_dialog.confirmed.connect(_start_new_game)

	# Hidden developer-menu entry point: five quick taps on the title.
	# Only wired up in debug builds - it does not exist in a release export.
	if GameManager.is_debug_enabled():
		_title_tap_reset_timer = Timer.new()
		_title_tap_reset_timer.wait_time = 1.5
		_title_tap_reset_timer.one_shot = true
		_title_tap_reset_timer.timeout.connect(func(): _title_tap_count = 0)
		add_child(_title_tap_reset_timer)
		_title_label.gui_input.connect(_on_title_gui_input)
		_title_label.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_title_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_title_tap_count += 1
		_title_tap_reset_timer.start()
		if _title_tap_count >= 5:
			_title_tap_count = 0
			SceneRouter.go_to("dev_diagnostics")

func _on_new_game_pressed() -> void:
	if SaveManager.has_save():
		_overwrite_dialog.popup_centered()
	else:
		_start_new_game()

func _start_new_game() -> void:
	GameManager.new_game()
	SceneRouter.go_to("haven")

func _on_continue_pressed() -> void:
	if GameManager.continue_game():
		SceneRouter.go_to("haven")
	else:
		EventBus.show_toast.emit("No save could be loaded - starting a new game instead.")
		_start_new_game()
