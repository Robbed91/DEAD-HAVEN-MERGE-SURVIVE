extends Control
## Polished state-driven route overlay for the illustrated regional map.
## Story flags decide how many route segments are revealed; this layer never
## writes progression or changes a destination.

const ROUTE_ANCHORS := [
	Vector2(0.50, 0.20),
	Vector2(0.42, 0.36),
	Vector2(0.60, 0.50),
	Vector2(0.45, 0.64),
	Vector2(0.55, 0.80),
]
const CURVE_OFFSETS := [
	Vector2(-0.055, 0.010),
	Vector2(0.045, -0.012),
	Vector2(-0.050, 0.012),
	Vector2(0.050, -0.008),
]
const ROUTE_SHADOW := Color(0.035, 0.042, 0.043, 0.78)
const ROUTE_LOCKED := Color(0.31, 0.34, 0.34, 0.55)
const ROUTE_DISCOVERED := Color(0.79, 0.46, 0.18, 0.94)
const ROUTE_EDGE := Color(0.96, 0.72, 0.35, 0.72)

var unlocked_segments := 0
var reveal_progress := 1.0
var pulse_time := 0.0
var animate_effects := true

func _ready() -> void:
	set_process(animate_effects)
	resized.connect(queue_redraw)

func set_unlocked_segments(value: int, animate: bool = true) -> void:
	unlocked_segments = clampi(value, 0, ROUTE_ANCHORS.size() - 1)
	animate_effects = animate
	set_process(animate_effects and is_visible_in_tree())
	reveal_progress = 0.0 if animate_effects and unlocked_segments > 0 else 1.0
	if reveal_progress < 1.0:
		var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "reveal_progress", 1.0, 0.85)
		tween.tween_callback(queue_redraw)
	queue_redraw()

func get_route_anchor(stage: int, area_size: Vector2 = Vector2.ZERO) -> Vector2:
	var drawing_size := size if area_size == Vector2.ZERO else area_size
	var index := clampi(stage, 0, ROUTE_ANCHORS.size() - 1)
	return ROUTE_ANCHORS[index] * drawing_size

func sample_route_segment(segment: int, t: float, area_size: Vector2 = Vector2.ZERO) -> Vector2:
	var drawing_size := size if area_size == Vector2.ZERO else area_size
	var index := clampi(segment, 0, ROUTE_ANCHORS.size() - 2)
	var start: Vector2 = ROUTE_ANCHORS[index] * drawing_size
	var finish: Vector2 = ROUTE_ANCHORS[index + 1] * drawing_size
	var control: Vector2 = (start + finish) * 0.5 + CURVE_OFFSETS[index] * drawing_size
	var amount := clampf(t, 0.0, 1.0)
	var inverse := 1.0 - amount
	return inverse * inverse * start + 2.0 * inverse * amount * control + amount * amount * finish

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	pulse_time = fmod(pulse_time + delta, TAU)
	queue_redraw()

func _segment_points(segment: int, completion: float = 1.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := maxi(2, ceili(18.0 * completion))
	for step in range(steps + 1):
		points.append(sample_route_segment(segment, completion * float(step) / float(steps)))
	return points

func _draw() -> void:
	for segment in range(ROUTE_ANCHORS.size() - 1):
		var route := _segment_points(segment)
		draw_polyline(route, ROUTE_SHADOW, 4.0, true)
		for point_index in range(0, route.size() - 1, 2):
			draw_line(route[point_index], route[point_index + 1], ROUTE_LOCKED, 1.35, true)

	for segment in range(unlocked_segments):
		var completion := reveal_progress if segment == unlocked_segments - 1 else 1.0
		var route := _segment_points(segment, completion)
		draw_polyline(route, ROUTE_SHADOW, 6.5, true)
		draw_polyline(route, ROUTE_DISCOVERED, 3.25, true)
		draw_polyline(route, ROUTE_EDGE, 0.85, true)

	for stage in range(ROUTE_ANCHORS.size()):
		var centre := get_route_anchor(stage)
		var discovered := stage <= unlocked_segments
		draw_circle(centre, 6.5, ROUTE_SHADOW)
		draw_circle(centre, 3.5, ROUTE_DISCOVERED if discovered else ROUTE_LOCKED)

	if animate_effects and unlocked_segments > 0:
		var frontier := sample_route_segment(unlocked_segments - 1, reveal_progress)
		var pulse := 8.0 + sin(pulse_time * 2.2) * 2.0
		draw_arc(frontier, pulse, 0.0, TAU, 24, Color(1.0, 0.72, 0.30, 0.42), 2.0, true)
