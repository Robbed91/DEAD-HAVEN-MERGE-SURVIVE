extends Control
class_name HotspotVisual
## One tappable repair area on a residence screen. Draws its own small
## before/after patch (distinct shape per hotspot, damaged-vs-fixed
## colouring) so the environment visibly changes on completion rather than
## just a label or icon swap - per the placeholder art policy, this is a
## deliberately simple but recognisable stand-in for a real illustrated
## before/after, not a blank rectangle or generic circle.

signal tapped(hotspot_id: String)

const DAMAGED_COLOR := Color("6b4a35")
const DAMAGED_ACCENT := Color("2a2825")
const FIXED_COLOR := Color("6b7a56")
const FIXED_ACCENT := Color("e8dcc5")

@export var hotspot_id: String = ""
@export var residence_id: String = "hollow_creek_farmhouse"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	EventBus.hotspot_state_changed.connect(func(id, _state):
		if id == hotspot_id:
			queue_redraw()
	)

func is_completed() -> bool:
	return ResidenceManager.get_hotspot_state(hotspot_id) == ResidenceHotspot.State.COMPLETED

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		tapped.emit(hotspot_id)

func _draw() -> void:
	var s: Vector2 = size
	var fixed := is_completed()
	var base := FIXED_COLOR if fixed else DAMAGED_COLOR
	var accent := FIXED_ACCENT if fixed else DAMAGED_ACCENT

	# Soft backing panel so the patch reads clearly against the background art.
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.08, 0.07, 0.06, 0.55 if not fixed else 0.35), true)
	draw_rect(Rect2(Vector2.ZERO, s), base, false, 2.0)

	match hotspot_id:
		"front_door":
			draw_rect(Rect2(s.x * 0.28, s.y * 0.15, s.x * 0.44, s.y * 0.75), base)
			draw_circle(Vector2(s.x * 0.6, s.y * 0.52), s.x * 0.03, accent)
			if not fixed:
				draw_line(Vector2(s.x * 0.28, s.y * 0.2), Vector2(s.x * 0.72, s.y * 0.85), accent, 3.0)
		"kitchen_window":
			draw_rect(Rect2(s.x * 0.2, s.y * 0.2, s.x * 0.6, s.y * 0.6), base, false, 3.0)
			draw_line(Vector2(s.x * 0.5, s.y * 0.2), Vector2(s.x * 0.5, s.y * 0.8), base, 2.0)
			draw_line(Vector2(s.x * 0.2, s.y * 0.5), Vector2(s.x * 0.8, s.y * 0.5), base, 2.0)
			if not fixed:
				draw_line(Vector2(s.x * 0.22, s.y * 0.22), Vector2(s.x * 0.78, s.y * 0.78), accent, 2.5)
		"living_room":
			draw_rect(Rect2(s.x * 0.15, s.y * 0.5, s.x * 0.7, s.y * 0.3), base)
			draw_rect(Rect2(s.x * 0.15, s.y * 0.35, s.x * 0.15, s.y * 0.25), base)
			draw_rect(Rect2(s.x * 0.7, s.y * 0.35, s.x * 0.15, s.y * 0.25), base)
		"fireplace":
			var pts := PackedVector2Array([
				Vector2(s.x * 0.3, s.y * 0.85), Vector2(s.x * 0.3, s.y * 0.35), Vector2(s.x * 0.5, s.y * 0.15),
				Vector2(s.x * 0.7, s.y * 0.35), Vector2(s.x * 0.7, s.y * 0.85),
			])
			draw_polyline(pts, base, 3.0)
			if fixed:
				var flame := PackedVector2Array([
					Vector2(s.x * 0.5, s.y * 0.5), Vector2(s.x * 0.42, s.y * 0.75), Vector2(s.x * 0.58, s.y * 0.75),
				])
				draw_colored_polygon(flame, Color("cf6a3f"))
		"pantry":
			for i in 3:
				draw_rect(Rect2(s.x * 0.2, s.y * (0.25 + i * 0.22), s.x * 0.6, s.y * 0.14), base)
		"upstairs_bedroom":
			draw_rect(Rect2(s.x * 0.15, s.y * 0.55, s.x * 0.7, s.y * 0.25), base)
			draw_rect(Rect2(s.x * 0.15, s.y * 0.4, s.x * 0.22, s.y * 0.2), accent)
		"barn":
			var pts := PackedVector2Array([
				Vector2(s.x * 0.15, s.y * 0.85), Vector2(s.x * 0.15, s.y * 0.4), Vector2(s.x * 0.5, s.y * 0.15),
				Vector2(s.x * 0.85, s.y * 0.4), Vector2(s.x * 0.85, s.y * 0.85),
			])
			draw_colored_polygon(pts, base)
		"rear_escape":
			for i in 4:
				draw_rect(Rect2(s.x * (0.12 + i * 0.2), s.y * 0.45, s.x * 0.1, s.y * 0.4), base)
			if fixed:
				draw_line(Vector2(s.x * 0.15, s.y * 0.65), Vector2(s.x * 0.85, s.y * 0.65), accent, 3.0)
		"perimeter_traps":
			for i in 4:
				var pts := PackedVector2Array([
					Vector2(s.x * (0.15 + i * 0.2), s.y * 0.85), Vector2(s.x * (0.22 + i * 0.2), s.y * 0.4),
					Vector2(s.x * (0.29 + i * 0.2), s.y * 0.85),
				])
				draw_colored_polygon(pts, base)
		_:
			draw_circle(s * 0.5, s.x * 0.3, base)

	if fixed:
		var badge_center := Vector2(s.x * 0.86, s.y * 0.14)
		draw_circle(badge_center, s.x * 0.09, Color("6b7a56"))
		draw_line(badge_center + Vector2(-4, 0), badge_center + Vector2(-1, 3), Color("e8dcc5"), 2.0)
		draw_line(badge_center + Vector2(-1, 3), badge_center + Vector2(5, -4), Color("e8dcc5"), 2.0)

## Brief dust/hammer flash played when this hotspot's quest completes -
## MergeBoard's burst effect reused here for the "construction happening"
## feedback the spec asks for (spec: hammering, dust, sparks).
func play_repair_burst() -> void:
	var reduced: bool = GameManager.settings.get("reduced_motion", false)
	if reduced:
		return
	var burst := Control.new()
	burst.size = size
	burst.global_position = global_position
	burst.pivot_offset = size * 0.5
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.draw.connect(func():
		for i in 6:
			var angle: float = TAU * i / 6.0
			var p := size * 0.5 + Vector2(cos(angle), sin(angle)) * size.x * 0.15
			burst.draw_circle(p, 3.0, Color("cfcac0"))
	)
	get_parent().add_child(burst)
	var tween := burst.create_tween()
	tween.tween_property(burst, "scale", Vector2(2.2, 2.2), 0.45).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(burst, "modulate:a", 0.0, 0.45)
	tween.tween_callback(burst.queue_free)
