extends CanvasLayer
## Global presentation director. It observes existing signals and newly added
## UI nodes; it does not own or mutate gameplay state.

const MotionFXScript = preload("res://scripts/vfx/motion_fx.gd")
const AmbientVFXScript = preload("res://scripts/vfx/ambient_vfx.gd")

var _overlay: Control

func _ready() -> void:
	layer = 90
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	get_tree().node_added.connect(_on_node_added)
	EventBus.level_up.connect(func(level): _show_announcement("LEVEL %d" % level, Color("e8b93d")))
	EventBus.chapter_changed.connect(func(_id): _show_announcement("CHAPTER UNLOCKED", Color("cf6a3f")))
	EventBus.survivor_unlocked.connect(func(_id): _show_announcement("SURVIVOR FOUND", Color("d8c9a8")))
	EventBus.vehicle_discovered.connect(func(_id): _show_announcement("VEHICLE DISCOVERED", Color("7f9cab")))
	EventBus.item_discovered.connect(func(_id): _show_announcement("NEW ITEM", Color("e8b93d"), 0.75))
	EventBus.quest_completed.connect(func(_id): _reward_flash())
	EventBus.scene_changed.connect(func(_key): call_deferred("_scan_scene"))
	EventBus.energy_changed.connect(func(_v, _m): _animate_named("EnergyValue"))
	EventBus.coins_changed.connect(func(_v): _animate_named("CoinsValue"))
	EventBus.haven_tokens_changed.connect(func(_v): _animate_named("TokensValue"))
	call_deferred("_scan_scene")

func _on_node_added(node: Node) -> void:
	if node is Button:
		call_deferred("_bind_button", node)

func _scan_scene() -> void:
	var scene := get_tree().current_scene
	if scene == null: return
	for node in scene.find_children("*", "Button", true, false):
		_bind_button(node)
	# Add atmosphere inside environment art so it remains behind the UI.
	for node in scene.find_children("Background", "Control", true, false):
		if node.get_node_or_null("AmbientVFX") == null:
			var ambience := AmbientVFXScript.new()
			ambience.name = "AmbientVFX"
			ambience.preset = _preset_for_scene(scene.scene_file_path)
			node.add_child(ambience)

func _preset_for_scene(path: String) -> String:
	if "northgate" in path or "vehicle" in path: return "industrial"
	if "saint_mercy" in path: return "fog"
	if "greybridge" in path: return "dust"
	return "storm"

func _bind_button(button: Button) -> void:
	if not is_instance_valid(button) or button.has_meta("motion_fx_bound"): return
	button.set_meta("motion_fx_bound", true)
	button.button_down.connect(func(): MotionFXScript.press(button, true))
	button.button_up.connect(func(): MotionFXScript.press(button, false))
	button.focus_entered.connect(func(): MotionFXScript.pulse(button, Color("e8b93d"), 1))

func _animate_named(node_name: String) -> void:
	var scene := get_tree().current_scene
	if scene == null: return
	var node := scene.find_child(node_name, true, false)
	if node is Control: MotionFXScript.bounce(node, 0.16)

func _reward_flash() -> void:
	if not GameManager.effects_enabled(): return
	var flash := ColorRect.new()
	flash.color = Color(0.91, 0.67, 0.23, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "color:a", 0.13, 0.11)
	tween.tween_property(flash, "color:a", 0.0, 0.32)
	tween.tween_callback(flash.queue_free)

func _show_announcement(message: String, color: Color, hold := 1.15) -> void:
	if not GameManager.effects_enabled(): return
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.position = Vector2(-145, 86)
	panel.size = Vector2(290, 54)
	panel.modulate.a = 0.0
	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", ThemeFactory.display_font())
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	panel.add_child(label)
	_overlay.add_child(panel)
	var tween := panel.create_tween()
	tween.tween_property(panel, "position:y", 108.0, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.18)
	tween.tween_interval(hold)
	tween.tween_property(panel, "modulate:a", 0.0, 0.22)
	tween.tween_callback(panel.queue_free)
