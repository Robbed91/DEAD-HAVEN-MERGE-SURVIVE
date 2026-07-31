extends Node
## SceneRouter
##
## Central place that knows how to get from one screen to another, with a
## short fade transition and a small history stack for "back". Screens
## never call get_tree().change_scene_to_file() directly - they call
## SceneRouter.go_to(key) so navigation stays consistent and testable.

const SCENE_PATHS: Dictionary = {
	"splash": "res://scenes/splash/splash.tscn",
	"main_menu": "res://scenes/main_menu/main_menu.tscn",
	"haven": "res://scenes/haven/haven.tscn",
	"redwater": "res://scenes/redwater/redwater.tscn",
	"greybridge": "res://scenes/greybridge/greybridge.tscn",
	"saint_mercy": "res://scenes/saint_mercy/saint_mercy.tscn",
	"northgate": "res://scenes/northgate/northgate.tscn",
	"dialogue": "res://scenes/dialogue/dialogue.tscn",
	"scavenging": "res://scenes/scavenging/scavenging.tscn",
	"vehicle": "res://scenes/vehicle/vehicle.tscn",
	"defence": "res://scenes/defence/defence.tscn",
	"merge_board": "res://scenes/merge_board/merge_board.tscn",
	"world_map": "res://scenes/world_map/world_map.tscn",
	"survivors": "res://scenes/survivors/survivors.tscn",
	"settings": "res://scenes/settings/settings.tscn",
	"dev_diagnostics": "res://scenes/dev_diagnostics/dev_diagnostics.tscn",
}

const FADE_DURATION := 0.18

var current_scene_key: String = ""
var pending_params: Dictionary = {}
var _history: Array[String] = []

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _is_transitioning: bool = false

func _ready() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.07, 0.065, 0.06, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)

func go_to(key: String, params: Dictionary = {}, push_history: bool = true) -> void:
	if not SCENE_PATHS.has(key):
		push_error("SceneRouter: unknown scene key '%s'" % key)
		return
	if _is_transitioning:
		return
	if push_history and current_scene_key != "":
		_history.append(current_scene_key)
	pending_params = params
	_transition_to(SCENE_PATHS[key], key)

func back(fallback_key: String = "haven") -> void:
	if _history.is_empty():
		go_to(fallback_key, {}, false)
		return
	var previous: String = _history.pop_back()
	go_to(previous, {}, false)

func take_pending_params() -> Dictionary:
	var params := pending_params
	pending_params = {}
	return params

func _transition_to(path: String, key: String) -> void:
	_is_transitioning = true
	var reduced_motion: bool = GameManager.settings.get("reduced_motion", false)
	var duration := 0.0 if reduced_motion else FADE_DURATION

	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, duration)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(path)
		current_scene_key = key
		EventBus.scene_changed.emit(key)
	)
	tween.tween_property(_fade_rect, "color:a", 0.0, duration)
	tween.tween_callback(func(): _is_transitioning = false)
