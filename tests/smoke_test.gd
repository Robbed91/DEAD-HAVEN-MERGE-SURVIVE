extends Node
## SmokeTest
##
## Headless-runnable smoke test that instantiates every screen in turn as a
## child of this node (deliberately NOT via SceneRouter.go_to, which would
## replace this very scene - screens must tolerate being instantiated this
## way for inspection; see DEVELOPMENT_LOG.md Phase 4 for a real bug this
## caught) and exits with a clear pass/fail line. Not wired up as the
## default main scene - run it directly:
##
##   godot4 --headless --path . tests/smoke_test.tscn

const SCENES := [
	"res://scenes/splash/splash.tscn",
	"res://scenes/haven/haven.tscn",
	"res://scenes/redwater/redwater.tscn",
	"res://scenes/merge_board/merge_board.tscn",
	"res://scenes/world_map/world_map.tscn",
	"res://scenes/survivors/survivors.tscn",
	"res://scenes/settings/settings.tscn",
	"res://scenes/dev_diagnostics/dev_diagnostics.tscn",
	"res://scenes/dialogue/dialogue.tscn",
	"res://scenes/scavenging/scavenging.tscn",
	"res://scenes/vehicle/vehicle.tscn",
	"res://scenes/defence/defence.tscn",
]

var _step_index: int = 0
var _current: Node

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme()
	GameManager.new_game()
	print("SMOKE: new_game ok, level=%d energy=%d" % [GameManager.profile.level, GameManager.resources.energy])
	_next_step()

func _next_step() -> void:
	if _current:
		_current.queue_free()
		_current = null

	if _step_index >= SCENES.size():
		print("SMOKE_TEST_OK")
		get_tree().quit(0)
		return

	var path: String = SCENES[_step_index]
	_step_index += 1
	print("SMOKE: instantiating %s" % path)
	var scene: PackedScene = load(path)
	if scene == null:
		print("SMOKE_TEST_FAIL: could not load %s" % path)
		get_tree().quit(1)
		return
	_current = scene.instantiate()
	add_child(_current)
	await get_tree().create_timer(0.4).timeout
	_next_step()
