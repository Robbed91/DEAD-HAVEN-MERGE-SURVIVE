extends Node
## Focused Android launcher/adaptive/themed icon contract test.
## Kept outside the smoke_test*.tscn set so the authoritative suite remains 33 scenes.

const MAIN := "res://assets/branding/android/launcher_main.png"
const FOREGROUND := "res://assets/branding/android/adaptive_foreground.png"
const BACKGROUND := "res://assets/branding/android/adaptive_background.png"
const MONOCHROME := "res://assets/branding/android/adaptive_monochrome.png"
const SAFE_MIN := 84
const SAFE_MAX := 347

var _failures: Array[String] = []

func _ready() -> void:
	var main := _load_image(MAIN)
	var foreground := _load_image(FOREGROUND)
	var background := _load_image(BACKGROUND)
	var monochrome := _load_image(MONOCHROME)

	if main != null:
		_check(main.get_width() >= 192 and main.get_height() >= 192, "main icon must be at least 192x192")
		_check(_is_fully_opaque(main), "main icon must be fully opaque")
	if foreground != null:
		_check(foreground.get_size() == Vector2i(432, 432), "adaptive foreground must be 432x432")
		_check(_has_transparent_corners(foreground), "adaptive foreground corners must be transparent")
		_check(_alpha_bounds_inside_safe_square(foreground), "adaptive foreground exceeds the centered 264px safe square")
	if background != null:
		_check(background.get_size() == Vector2i(432, 432), "adaptive background must be 432x432")
		_check(_is_fully_opaque(background), "adaptive background must be fully opaque")
	if monochrome != null:
		_check(monochrome.get_size() == Vector2i(432, 432), "adaptive monochrome icon must be 432x432")
		_check(_has_transparent_corners(monochrome), "adaptive monochrome corners must be transparent")
		_check(_is_white_alpha_mask(monochrome), "adaptive monochrome must be a white alpha mask")

	_check_configuration()

	if _failures.is_empty():
		print("ANDROID_LAUNCHER_ASSET_TEST_OK main=512 adaptive=432 safe_square=264 fallback=0")
		get_tree().quit(0)
	else:
		for failure in _failures:
			push_error("ANDROID_LAUNCHER_ASSET_TEST: %s" % failure)
		get_tree().quit(1)

func _load_image(path: String) -> Image:
	var texture := load(path) as Texture2D
	if texture == null:
		_check(false, "failed to load imported texture %s" % path)
		return null
	return texture.get_image()

func _is_fully_opaque(image: Image) -> bool:
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 0.999:
				return false
	return true

func _has_transparent_corners(image: Image) -> bool:
	var max_x := image.get_width() - 1
	var max_y := image.get_height() - 1
	return (
		image.get_pixel(0, 0).a <= 0.01
		and image.get_pixel(max_x, 0).a <= 0.01
		and image.get_pixel(0, max_y).a <= 0.01
		and image.get_pixel(max_x, max_y).a <= 0.01
	)

func _alpha_bounds_inside_safe_square(image: Image) -> bool:
	var found := false
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.05:
				found = true
				if x < SAFE_MIN or x > SAFE_MAX or y < SAFE_MIN or y > SAFE_MAX:
					return false
	return found

func _is_white_alpha_mask(image: Image) -> bool:
	var found := false
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.01:
				found = true
				if pixel.r < 0.99 or pixel.g < 0.99 or pixel.b < 0.99:
					return false
	return found

func _check_configuration() -> void:
	var project := ConfigFile.new()
	_check(project.load("res://project.godot") == OK, "project.godot could not be parsed")
	_check(project.get_value("application", "config/icon", "") == MAIN, "project icon is not the final launcher main asset")

	var presets := ConfigFile.new()
	_check(presets.load("res://export_presets.cfg") == OK, "export_presets.cfg could not be parsed")
	var section := "preset.0.options"
	_check(presets.get_value(section, "launcher_icons/main_192x192", "") == MAIN, "Android main launcher reference is wrong")
	_check(presets.get_value(section, "launcher_icons/adaptive_foreground_432x432", "") == FOREGROUND, "Android adaptive foreground reference is wrong")
	_check(presets.get_value(section, "launcher_icons/adaptive_background_432x432", "") == BACKGROUND, "Android adaptive background reference is wrong")
	_check(presets.get_value(section, "launcher_icons/adaptive_monochrome_432x432", "") == MONOCHROME, "Android adaptive monochrome reference is wrong")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
