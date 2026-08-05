extends CanvasLayer
class_name AppConfirmDialog
## Drop-in replacement for Godot's native ConfirmationDialog, which is a
## Window subclass and does not participate in the project's canvas_items
## viewport stretch (window/stretch/mode="canvas_items" in project.godot).
## On real high-DPI phones this made native ConfirmationDialog popups
## (main menu overwrite prompt, settings reset, item delete confirm) render
## sized for the 720px logical base width without the same stretch
## transform the rest of the UI gets, overflowing past the right/bottom
## edge of the actual screen. This uses plain Control nodes in the same
## Scrim/CenterContainer/PanelContainer pattern already proven correct by
## ItemInfoPanel, so it stretches identically to every other screen.

signal confirmed()
signal canceled()

@export var dialog_title: String = "":
	set(value):
		dialog_title = value
		if is_node_ready(): _refresh_text()
@export var dialog_text: String = "":
	set(value):
		dialog_text = value
		if is_node_ready(): _refresh_text()
@export var ok_button_text: String = "OK":
	set(value):
		ok_button_text = value
		if is_node_ready(): _refresh_text()
@export var cancel_button_text: String = "Cancel":
	set(value):
		cancel_button_text = value
		if is_node_ready(): _refresh_text()

@onready var _scrim: ColorRect = %Scrim
@onready var _title_label: Label = %TitleLabel
@onready var _body_label: Label = %BodyLabel
@onready var _ok_button: Button = %OkButton
@onready var _cancel_button: Button = %CancelButton

func _ready() -> void:
	layer = 95
	visible = false
	$CenterContainer.theme = get_window().theme
	$CenterContainer/Panel.theme_type_variation = "CreamPanel"
	_title_label.add_theme_font_override("font", ThemeFactory.display_font())
	_title_label.add_theme_color_override("font_color", ThemeFactory.CHARCOAL_LIGHT)
	_body_label.add_theme_color_override("font_color", ThemeFactory.CHARCOAL_LIGHT)
	_ok_button.theme_type_variation = "DangerButton"
	_cancel_button.theme_type_variation = "NavButton"
	_scrim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			_on_cancel()
	)
	_ok_button.pressed.connect(_on_confirm)
	_cancel_button.pressed.connect(_on_cancel)
	_refresh_text()

func _refresh_text() -> void:
	if _title_label == null:
		return
	_title_label.text = dialog_title
	_title_label.visible = not dialog_title.is_empty()
	_body_label.text = dialog_text
	_ok_button.text = ok_button_text
	_cancel_button.text = cancel_button_text

## Matches ConfirmationDialog's popup_centered() call signature used
## throughout the project (no arguments - this dialog always fills to its
## content and centers itself via CenterContainer).
func popup_centered() -> void:
	visible = true
	AudioManager.play_sfx("modal_open")

func _on_confirm() -> void:
	visible = false
	AudioManager.play_sfx("confirmation")
	confirmed.emit()

func _on_cancel() -> void:
	visible = false
	AudioManager.play_sfx("modal_close")
	canceled.emit()
