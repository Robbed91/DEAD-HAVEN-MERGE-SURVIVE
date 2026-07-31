extends RefCounted
class_name MotionFX
## Shared, presentation-only tween recipes. Every entry point is safe when
## motion is reduced or the target is off-screen, and never changes gameplay.

static func allowed(node: CanvasItem) -> bool:
	return is_instance_valid(node) and node.is_inside_tree() and node.is_visible_in_tree() and GameManager.effects_enabled()

static func stop(node: CanvasItem) -> void:
	if node.has_meta("motion_fx_tween"):
		var old: Tween = node.get_meta("motion_fx_tween")
		if old != null and old.is_valid():
			old.kill()
		node.remove_meta("motion_fx_tween")

static func press(node: Control, down: bool) -> void:
	stop(node)
	if not allowed(node):
		node.scale = Vector2.ONE
		return
	node.pivot_offset = node.size * 0.5
	var tween := node.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	node.set_meta("motion_fx_tween", tween)
	tween.tween_property(node, "scale", Vector2.ONE * (0.955 if down else 1.035), 0.07)
	if not down:
		tween.tween_property(node, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK)

static func reveal(node: Control, direction := Vector2(0, 18), duration := 0.22) -> void:
	stop(node)
	if not allowed(node):
		node.modulate.a = 1.0
		return
	var destination := node.position
	node.position = destination + direction
	node.modulate.a = 0.0
	var tween := node.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	node.set_meta("motion_fx_tween", tween)
	tween.tween_property(node, "position", destination, duration)
	tween.tween_property(node, "modulate:a", 1.0, duration * 0.8)

static func bounce(node: Control, strength := 0.12) -> void:
	stop(node)
	if not allowed(node): return
	node.pivot_offset = node.size * 0.5
	var tween := node.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	node.set_meta("motion_fx_tween", tween)
	tween.tween_property(node, "scale", Vector2.ONE * (1.0 + strength), 0.12)
	tween.tween_property(node, "scale", Vector2.ONE, 0.15)

static func shake(node: Control, distance := 7.0) -> void:
	stop(node)
	if not allowed(node): return
	var origin := node.position
	var tween := node.create_tween()
	node.set_meta("motion_fx_tween", tween)
	for offset in [distance, -distance, distance * 0.65, -distance * 0.65]:
		tween.tween_property(node, "position", origin + Vector2(offset, 0), 0.045)
	tween.tween_property(node, "position", origin, 0.05)

static func pulse(node: Control, color := Color("e8b93d"), loops := 2) -> void:
	stop(node)
	if not allowed(node): return
	var base := node.modulate
	var tween := node.create_tween().set_loops(loops)
	node.set_meta("motion_fx_tween", tween)
	tween.tween_property(node, "modulate", color, 0.16)
	tween.tween_property(node, "modulate", base, 0.22)
