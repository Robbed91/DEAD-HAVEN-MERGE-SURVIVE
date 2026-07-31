extends Node2D
class_name LayeredCharacterRig
## Presentation-only character rig. Gameplay owns state; this node translates
## those states into artwork and animation without changing any character data.

@export var character_id := "mara_vale"
@export var hollow := false
@export var display_height := 176.0
@export var auto_play := "idle_breathing"

var _art := Sprite2D.new()
var _skeleton := Skeleton2D.new()
var _player := AnimationPlayer.new()
var _current_state := ""

const SURVIVOR_STATES := [
	"idle_breathing", "blink", "look_around", "speaking", "walking",
	"running", "carrying", "hammering", "sawing", "searching",
	"using_radio", "treating_injury", "entering_vehicle", "celebration",
	"fear", "injured_idle", "defensive_action",
]
const HOLLOW_STATES := [
	"idle_sway", "slow_walk", "detect_target", "attack_barricade",
	"hit_reaction", "trap_reaction", "collapse", "distant_wandering",
]
const LAYERS := ["torso", "leg_left", "leg_right", "foot_left", "foot_right", "arm_left", "arm_right", "head"]

func _ready() -> void:
	_build_visual()
	_build_animation_library()
	play_state(auto_play if not hollow else "idle_sway")

func _build_visual() -> void:
	_art.name = "FinalArtwork"
	_art.centered = true
	add_child(_art)
	_skeleton.name = "LayeredSkeleton"
	add_child(_skeleton)
	# Separated production layers remain addressable children beside the
	# Skeleton2D scaffold. The clean composite is rendered at runtime to avoid
	# matte seams at phone scale; the layers are ready for per-bone refinement.
	for layer_name in LAYERS:
		var layer_root := Node2D.new()
		layer_root.name = layer_name.to_pascal_case()
		_skeleton.add_child(layer_root)
		var layer := Sprite2D.new()
		layer.name = "Artwork"
		layer.texture = load(_layer_path(layer_name))
		layer.visible = false
		layer_root.add_child(layer)
	add_child(_player)
	_player.name = "AnimationPlayer"
	_set_pose("neutral")

func _base_dir() -> String:
	return "res://assets/art/enemies/drifter_hollow" if hollow else "res://assets/art/characters/%s/poses" % character_id

func _layer_path(layer_name: String) -> String:
	var base := "res://assets/art/enemies/drifter_hollow/rig" if hollow else "res://assets/art/characters/%s/rig" % character_id
	return "%s/%s.png" % [base, layer_name]

func _set_pose(pose_name: String) -> void:
	var path := "%s/%s.png" % [_base_dir(), pose_name]
	if not ResourceLoader.exists(path):
		path = "%s/neutral.png" % _base_dir()
	_art.texture = load(path)
	if _art.texture:
		var texture_height := float(_art.texture.get_height())
		_art.scale = Vector2.ONE * (display_height / texture_height)

func play_state(state_name: String) -> void:
	var available: Array = HOLLOW_STATES if hollow else SURVIVOR_STATES
	if not state_name in available:
		state_name = "idle_sway" if hollow else "idle_breathing"
	_current_state = state_name
	_set_pose(_pose_for_state(state_name))
	_player.play(state_name)

func _pose_for_state(state_name: String) -> String:
	if hollow and ResourceLoader.exists("%s/%s.png" % [_base_dir(), state_name]):
		return state_name
	if state_name in ["walking", "running", "carrying", "searching"]:
		return "scavenging"
	if state_name in ["hammering", "sawing", "celebration"]:
		return "residence"
	if state_name == "injured_idle":
		return "front_three_quarter"
	return "neutral"

func _build_animation_library() -> void:
	var library := AnimationLibrary.new()
	var states: Array = HOLLOW_STATES if hollow else SURVIVOR_STATES
	for state_name in states:
		library.add_animation(state_name, _make_animation(state_name))
	_player.add_animation_library("", library)

func _make_animation(state_name: String) -> Animation:
	var animation := Animation.new()
	animation.length = 1.0
	animation.loop_mode = Animation.LOOP_LINEAR
	var position_keys := [Vector2.ZERO, Vector2(0, -2), Vector2.ZERO]
	var rotation_keys := [0.0, 0.012, 0.0]
	var scale_keys := [Vector2.ONE, Vector2(1.006, 0.994), Vector2.ONE]
	if state_name in ["walking", "slow_walk", "distant_wandering"]:
		animation.length = 0.72
		position_keys = [Vector2(-2, 0), Vector2(2, -3), Vector2(-2, 0)]
		rotation_keys = [-0.025, 0.025, -0.025]
	elif state_name == "running":
		animation.length = 0.48
		position_keys = [Vector2(-3, 0), Vector2(3, -5), Vector2(-3, 0)]
		rotation_keys = [-0.05, 0.05, -0.05]
	elif state_name in ["hammering", "sawing", "attack_barricade", "defensive_action"]:
		animation.length = 0.56
		rotation_keys = [-0.035, 0.07, -0.035]
		position_keys = [Vector2.ZERO, Vector2(1, 2), Vector2.ZERO]
	elif state_name in ["hit_reaction", "trap_reaction", "fear"]:
		animation.length = 0.42
		animation.loop_mode = Animation.LOOP_NONE
		position_keys = [Vector2.ZERO, Vector2(-7, -2), Vector2.ZERO]
		rotation_keys = [0.0, -0.1, 0.0]
	elif state_name == "collapse":
		animation.length = 0.85
		animation.loop_mode = Animation.LOOP_NONE
		position_keys = [Vector2.ZERO, Vector2(5, 22), Vector2(8, 34)]
		rotation_keys = [0.0, 0.24, 0.46]
	elif state_name == "celebration":
		animation.length = 0.65
		position_keys = [Vector2.ZERO, Vector2(0, -8), Vector2.ZERO]
	var times := [0.0, animation.length * 0.5, animation.length]
	_add_track(animation, "FinalArtwork:position", times, position_keys)
	_add_track(animation, "FinalArtwork:rotation", times, rotation_keys)
	_add_track(animation, "FinalArtwork:scale", times, scale_keys.map(func(v: Vector2): return v * _art.scale))
	return animation

func _add_track(animation: Animation, path: String, times: Array, values: Array) -> void:
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath(path))
	animation.value_track_set_update_mode(track, Animation.UPDATE_CONTINUOUS)
	for index in times.size():
		animation.track_insert_key(track, times[index], values[index])
