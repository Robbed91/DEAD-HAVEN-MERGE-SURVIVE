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

static func build_theme(text_scale: float = 1.0, high_contrast: bool = false) -> Theme:
	var theme := Theme.new()
	var base_font_size := int(round(28 * text_scale))
	var button_font_size := int(round(26 * text_scale))
	var title_font_size := int(round(44 * text_scale))

	var bg := HC_BG if high_contrast else CHARCOAL
	var text_color := HC_TEXT if high_contrast else CREAM
	var accent := HC_ACCENT if high_contrast else RUST

	theme.set_default_font_size(base_font_size)

	# -- Label --------------------------------------------------------------
	theme.set_color("font_color", "Label", text_color)
	theme.set_font_size("font_size", "Label", base_font_size)

	# -- Button ---------------------------------------------------------------
	var btn_normal := _panel_style(accent, 12, MIN_TOUCH_TARGET)
	var btn_hover := _panel_style(accent.lightened(0.12), 12, MIN_TOUCH_TARGET)
	var btn_pressed := _panel_style(accent.darkened(0.18), 12, MIN_TOUCH_TARGET)
	var btn_disabled := _panel_style(OLIVE_DARK, 12, MIN_TOUCH_TARGET)
	btn_disabled.bg_color.a = 0.5

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_color("font_color", "Button", CREAM if high_contrast else CREAM)
	theme.set_color("font_disabled_color", "Button", CREAM.darkened(0.35))
	theme.set_font_size("font_size", "Button", button_font_size)

	# -- Panel / PanelContainer -------------------------------------------------
	var panel_style := _panel_style(bg.lightened(0.04) if not high_contrast else Color("111111"), 16, 0)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = OLIVE if not high_contrast else HC_ACCENT
	theme.set_stylebox("panel", "PanelContainer", panel_style)
	theme.set_stylebox("panel", "Panel", panel_style)

	# -- LineEdit / sliders keep readable against dark backgrounds ------------
	theme.set_color("font_color", "CheckBox", text_color)
	theme.set_color("font_color", "OptionButton", text_color)

	return theme

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
