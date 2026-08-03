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
	"res://scenes/greybridge/greybridge.tscn",
	"res://scenes/saint_mercy/saint_mercy.tscn",
	"res://scenes/northgate/northgate.tscn",
	"res://scenes/world_map/world_map.tscn",
	"res://scenes/survivors/survivors.tscn",
	"res://scenes/settings/settings.tscn",
	"res://scenes/dev_diagnostics/dev_diagnostics.tscn",
	"res://scenes/dialogue/dialogue.tscn",
	"res://scenes/scavenging/scavenging.tscn",
	"res://scenes/vehicle/vehicle.tscn",
	"res://scenes/defence/defence.tscn",
]

const RESIDENCE_SCENES := {
	"res://scenes/haven/haven.tscn": "hollow_creek_farmhouse",
	"res://scenes/redwater/redwater.tscn": "redwater_service_station",
	"res://scenes/greybridge/greybridge.tscn": "greybridge_school",
	"res://scenes/saint_mercy/saint_mercy.tscn": "saint_mercy_hospital",
	"res://scenes/northgate/northgate.tscn": "northgate_prison",
}

var _step_index: int = 0
var _current: Node

func _ready() -> void:
	get_window().theme = ThemeFactory.build_theme()
	GameManager.new_game()
	print("SMOKE: new_game ok, level=%d energy=%d" % [GameManager.profile.level, GameManager.resources.energy])
	if SceneRouter.SCENE_PATHS.has("merge_board"):
		print("SMOKE_TEST_FAIL: merge_board remains a navigable destination")
		get_tree().quit(1)
		return
	for residence_id in BoardState.RESIDENCE_IDS:
		if not SceneRouter.SCENE_PATHS.has(SceneRouter.residence_scene_key(residence_id)):
			print("SMOKE_TEST_FAIL: residence home route missing for %s" % residence_id)
			get_tree().quit(1)
			return
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
	await get_tree().process_frame
	if RESIDENCE_SCENES.has(path):
		var expected_residence_id: String = RESIDENCE_SCENES[path]
		var panel := _current.get_node_or_null("Layout/Scene/BoardPanel") as MergeBoard
		var hotspots := _current.get_node_or_null("Layout/Scene/Hotspots") as Control
		if panel == null or panel.get_node_or_null("Layout/BoardMargin/BoardGrid") == null:
			print("SMOKE_TEST_FAIL: residence lacks embedded board panel: %s" % path)
			get_tree().quit(1)
			return
		var scene_area := _current.get_node("Layout/Scene") as Control
		var grid := panel.get_node("Layout/BoardMargin/BoardGrid") as GridContainer
		var panel_rect := panel.get_global_rect()
		var grid_rect := grid.get_global_rect()
		if grid.get_child_count() != BoardState.COLUMNS * BoardState.ROWS:
			print("SMOKE_TEST_FAIL: embedded board is not 7x9: %s" % path)
			get_tree().quit(1)
			return
		if panel.position.y < scene_area.size.y * 0.2 or grid_rect.end.y > panel_rect.end.y + 1.0:
			print("SMOKE_TEST_FAIL: embedded board leaves no residence band or clips vertically: %s" % path)
			get_tree().quit(1)
			return
		if BoardState.active_residence_id != expected_residence_id:
			print("SMOKE_TEST_FAIL: residence activated wrong board: %s" % path)
			get_tree().quit(1)
			return
		if hotspots == null or hotspots.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			print("SMOKE_TEST_FAIL: hotspot layer does not pass empty-area input to board: %s" % path)
			get_tree().quit(1)
			return
		if expected_residence_id == "hollow_creek_farmhouse":
			var task_panel := _current.get_node("TaskPanel") as TaskPanel
			task_panel.show_for_hotspot("front_door", expected_residence_id)
			task_panel.call("_on_find_pressed")
			if panel.get_highlighted_chain_id() != "construction":
				print("SMOKE_TEST_FAIL: Find on Board did not highlight embedded board")
				get_tree().quit(1)
				return
	await get_tree().create_timer(0.4).timeout
	_next_step()
