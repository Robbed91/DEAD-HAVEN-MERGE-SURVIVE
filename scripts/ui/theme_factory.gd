extends RefCounted
class_name ThemeFactory
## Builds the game's Theme resource in code so the whole visual identity
## (palette, button/panel styling, touch target sizes, text scale, high
## contrast) lives in one reviewable place instead of scattered .tres files.

# -- Palette (see README "Visual identity" and ART_STYLE_GUIDE.md) --------
# Semantic roles (ART_STYLE_GUIDE.md section 2), each backed by one
# canonical hex value so code and art-generation prompts always agree:
#   Haven charcoal    -> CHARCOAL / CHARCOAL_LIGHT  (panels, nav, framing)
#   Survival olive     -> OLIVE / OLIVE_DARK          (primary actions, safe markers)
#   Rust orange         -> RUST / RUST_LIGHT / RUST_DARK (warnings, construction, highlights)
#   Emergency red       -> WARN_RED                    (danger, injury, horde only)
#   Warm cream          -> CREAM                        (task cards, dialogue, light text)
#   Safe-haven amber    -> SAFE_AMBER                   (completed-residence glow, rewards)
#   Storm blue-grey      -> STORM_BLUEGREY               (exteriors, locked content, night)
const CHARCOAL := Color("1c1b1a")
const CHARCOAL_LIGHT := Color("2a2825")
const OLIVE := Color("6b7a56")
const OLIVE_DARK := Color("4d5940")
const RUST := Color("b5502b")
const RUST_LIGHT := Color("cf6a3f")
const RUST_DARK := Color("8a3c1f")
const CREAM := Color("e8dcc5")
const WARN_RED := Color("b23a2e")
const WOOD := Color("6b4a35")
const METAL := Color("8a8f8a")
const SAFE_AMBER := Color("e2a24a")
const STORM_BLUEGREY := Color("3c4650")

# High-contrast alternates - larger contrast ratio against CHARCOAL/CREAM.
const HC_BG := Color("000000")
const HC_TEXT := Color("ffffff")
const HC_ACCENT := Color("ff8a3d")

const MIN_TOUCH_TARGET := 64.0

static func build_theme(text_scale: float = 1.0, high_contrast: bool = false, colorblind_mode: bool = false) -> Theme:
	var theme := Theme.new()
	var base_font_size := int(round(28 * text_scale))
	var button_font_size := int(round(26 * text_scale))
	var title_font_size := int(round(44 * text_scale))

	var bg := HC_BG if high_contrast else CHARCOAL
	var text_color := HC_TEXT if high_contrast else CREAM
	var accent := HC_ACCENT if high_contrast else RUST
	var inter: Font = load("res://assets/fonts/Inter-VariableFont_opsz_wght.ttf") if ResourceLoader.exists("res://assets/fonts/Inter-VariableFont_opsz_wght.ttf") else null
	if inter != null:
		theme.default_font = inter

	theme.set_default_font_size(base_font_size)

	# -- Label --------------------------------------------------------------
	theme.set_color("font_color", "Label", text_color)
	theme.set_font_size("font_size", "Label", base_font_size)

	# -- Button ---------------------------------------------------------------
	# colorblind_mode never touches hue (unverifiable without a real screen
	# in this environment - see ART_STYLE_GUIDE.md section 2) - instead it
	# adds a shape/outline cue so button state doesn't depend on perceiving
	# a colour difference at all: every button gets a visible outline, and
	# disabled buttons additionally lose their fill instead of just dimming
	# it, so "can't tap this" is legible by silhouette alone.
	var btn_normal: StyleBox = _texture_style("res://assets/ui/hollow_creek/button_olive.png", MIN_TOUCH_TARGET, Color.WHITE)
	var btn_hover: StyleBox = _texture_style("res://assets/ui/hollow_creek/button_olive.png", MIN_TOUCH_TARGET, Color(1.12, 1.08, 1.02, 1.0))
	var btn_pressed: StyleBox = _texture_style("res://assets/ui/hollow_creek/button_olive.png", MIN_TOUCH_TARGET, Color(0.72, 0.72, 0.72, 1.0))
	var btn_disabled: StyleBox = _texture_style("res://assets/ui/hollow_creek/button_disabled.png", MIN_TOUCH_TARGET, Color(0.72, 0.72, 0.72, 0.78))

	if high_contrast or colorblind_mode:
		btn_normal = _panel_style(HC_ACCENT, 12, MIN_TOUCH_TARGET)
		btn_hover = _panel_style(HC_ACCENT.lightened(0.12), 12, MIN_TOUCH_TARGET)
		btn_pressed = _panel_style(HC_ACCENT.darkened(0.18), 12, MIN_TOUCH_TARGET)
		btn_disabled = _panel_style(Color("222222"), 12, MIN_TOUCH_TARGET)
		for style in [btn_normal, btn_hover, btn_pressed, btn_disabled]:
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_color = CREAM

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("hover_pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_stylebox("focus", "Button", _focus_style(SAFE_AMBER if not high_contrast else HC_ACCENT))
	theme.set_color("font_color", "Button", CREAM if high_contrast else CREAM)
	theme.set_color("font_disabled_color", "Button", CREAM.darkened(0.35))
	theme.set_font_size("font_size", "Button", button_font_size)

	# -- Panel / PanelContainer -------------------------------------------------
	var panel_style: StyleBox = _texture_style("res://assets/ui/hollow_creek/panel_iron.png", 0, Color.WHITE) if not high_contrast else _panel_style(Color("111111"), 16, 0)
	theme.set_stylebox("panel", "PanelContainer", panel_style)
	theme.set_stylebox("panel", "Panel", panel_style)
	_register_panel_variation(theme, "CreamPanel", "res://assets/ui/hollow_creek/panel_parchment.png", Color.WHITE)
	_register_panel_variation(theme, "CharcoalPanel", "res://assets/ui/hollow_creek/panel_iron.png", Color.WHITE)
	_register_panel_variation(theme, "StormPanel", "res://assets/ui/hollow_creek/panel_iron.png", Color(0.76, 0.86, 0.96, 1.0))
	_register_panel_variation(theme, "SurvivorCard", "res://assets/ui/hollow_creek/panel_parchment.png", Color(0.96, 0.91, 0.82, 1.0))
	_register_panel_variation(theme, "LockedCard", "res://assets/ui/hollow_creek/panel_iron.png", Color(0.64, 0.7, 0.73, 1.0))
	_register_panel_variation(theme, "DialoguePanel", "res://assets/ui/hollow_creek/panel_parchment.png", Color(0.94, 0.88, 0.77, 1.0))

	_register_button_variation(theme, "OliveButton", "res://assets/ui/hollow_creek/button_olive.png", CREAM)
	_register_button_variation(theme, "RustButton", "res://assets/ui/hollow_creek/button_rust.png", CREAM)
	_register_button_variation(theme, "DangerButton", "res://assets/ui/hollow_creek/button_rust.png", CREAM, Color(0.82, 0.42, 0.36, 1.0))
	_register_button_variation(theme, "NavButton", "res://assets/ui/hollow_creek/panel_iron.png", CREAM.darkened(0.18))
	_register_button_variation(theme, "NavSelectedButton", "res://assets/ui/hollow_creek/button_olive.png", CREAM)
	_register_button_variation(theme, "MapMarkerButton", "res://assets/ui/hollow_creek/button_olive.png", CREAM)
	_register_button_variation(theme, "LockedButton", "res://assets/ui/hollow_creek/button_disabled.png", CREAM.darkened(0.3))
	_register_button_variation(theme, "NotificationButton", "res://assets/ui/hollow_creek/panel_iron.png", SAFE_AMBER)
	_register_button_variation(theme, "LoadingButton", "res://assets/ui/hollow_creek/panel_iron.png", SAFE_AMBER)

	var progress_background := _panel_style(Color("171818"), 8, 18)
	progress_background.border_width_left = 2
	progress_background.border_width_right = 2
	progress_background.border_width_top = 2
	progress_background.border_width_bottom = 2
	progress_background.border_color = Color("5d625c")
	var progress_fill := _panel_style(OLIVE, 7, 18)
	theme.set_stylebox("background", "ProgressBar", progress_background)
	theme.set_stylebox("fill", "ProgressBar", progress_fill)
	theme.set_color("font_color", "ProgressBar", CREAM)
	var toggle_off: Texture2D = load("res://assets/ui/icons/final/toggle_off.svg")
	var toggle_on: Texture2D = load("res://assets/ui/icons/final/toggle_on.svg")
	for control_type in ["CheckButton", "CheckBox"]:
		theme.set_icon("unchecked", control_type, toggle_off)
		theme.set_icon("checked", control_type, toggle_on)
		theme.set_icon("unchecked_disabled", control_type, toggle_off)
		theme.set_icon("checked_disabled", control_type, toggle_on)
	theme.set_icon("arrow", "OptionButton", load("res://assets/ui/icons/final/dropdown_arrow.svg"))

	# -- LineEdit / sliders keep readable against dark backgrounds ------------
	theme.set_color("font_color", "CheckBox", text_color)
	theme.set_color("font_color", "OptionButton", text_color)

	return theme

static func parchment_style() -> StyleBox:
	return _texture_style("res://assets/ui/hollow_creek/panel_parchment.png", 0, Color.WHITE)

static func display_font() -> Font:
	return load("res://assets/fonts/Oswald-VariableFont_wght.ttf") if ResourceLoader.exists("res://assets/fonts/Oswald-VariableFont_wght.ttf") else ThemeDB.fallback_font

static func board_cell_style(state: String = "normal") -> StyleBox:
	var path := "res://assets/ui/merge_board/cell_%s.png" % state
	if not ResourceLoader.exists(path):
		path = "res://assets/ui/merge_board/cell_normal.png"
	return _texture_style(path, 0, Color.WHITE)

static func storage_slot_style() -> StyleBox:
	return _texture_style("res://assets/ui/merge_board/storage_slot.png", 0, Color.WHITE)

static func merge_storage_panel_style() -> StyleBox:
	return _texture_style("res://assets/ui/hollow_creek/panel_wood.png", 0, Color(0.82, 0.78, 0.70, 1.0))

static func compact_button_style(tint: Color = Color.WHITE) -> StyleBox:
	var style := _texture_style("res://assets/ui/hollow_creek/button_rust.png", 0, tint)
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style

static func _register_panel_variation(theme: Theme, variation: String, path: String, tint: Color) -> void:
	theme.set_type_variation(variation, "PanelContainer")
	theme.set_stylebox("panel", variation, _texture_style(path, 0, tint))

static func _register_button_variation(theme: Theme, variation: String, path: String, font_color: Color, tint: Color = Color.WHITE) -> void:
	theme.set_type_variation(variation, "Button")
	theme.set_stylebox("normal", variation, _texture_style(path, MIN_TOUCH_TARGET, tint))
	theme.set_stylebox("hover", variation, _texture_style(path, MIN_TOUCH_TARGET, tint.lightened(0.1)))
	var pressed := _texture_style(path, MIN_TOUCH_TARGET, tint.darkened(0.24))
	theme.set_stylebox("pressed", variation, pressed)
	theme.set_stylebox("hover_pressed", variation, pressed)
	theme.set_stylebox("disabled", variation, _texture_style("res://assets/ui/hollow_creek/button_disabled.png", MIN_TOUCH_TARGET, Color(0.7, 0.7, 0.7, 0.76)))
	theme.set_stylebox("focus", variation, _focus_style(SAFE_AMBER))
	theme.set_color("font_color", variation, font_color)
	theme.set_color("font_hover_color", variation, CREAM)
	theme.set_color("font_pressed_color", variation, CREAM)
	theme.set_color("font_disabled_color", variation, CREAM.darkened(0.42))

static func _focus_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.expand_margin_left = 3
	style.expand_margin_right = 3
	style.expand_margin_top = 3
	style.expand_margin_bottom = 3
	return style

static func _texture_style(path: String, min_height: float, tint: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(path)
	style.set_texture_margin(SIDE_LEFT, 24.0)
	style.set_texture_margin(SIDE_TOP, 24.0)
	style.set_texture_margin(SIDE_RIGHT, 24.0)
	style.set_texture_margin(SIDE_BOTTOM, 24.0)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	style.modulate_color = tint
	if min_height > 0.0:
		style.content_margin_top = maxf(style.content_margin_top, (min_height - 28.0) * 0.5)
		style.content_margin_bottom = style.content_margin_top
	return style

static func _panel_style(color: Color, radius: int, min_height: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	if min_height > 0.0:
		style.content_margin_top = max(style.content_margin_top, (min_height - 28.0) * 0.5)
		style.content_margin_bottom = style.content_margin_top
	return style
