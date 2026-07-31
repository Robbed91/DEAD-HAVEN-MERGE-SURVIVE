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
const HOLLOW_RING := preload("res://assets/ui/hollow_creek/hotspot_ring.png")
const HOLLOW_REPAIRED := preload("res://assets/ui/hollow_creek/hotspot_repaired.png")

const HOLLOW_ITEM_LEVELS := {
	"front_door": 2,
	"kitchen_window": 3,
	"living_room": 3,
	"fireplace": 2,
	"pantry": 2,
	"upstairs_bedroom": 4,
	"barn": 5,
	"rear_escape": 4,
	"perimeter_traps": 6,
}

@export var hotspot_id: String = ""
@export var residence_id: String = "hollow_creek_farmhouse"

var _pulse_time := 0.0
var _hollow_back: TextureRect
var _hollow_item: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	EventBus.hotspot_state_changed.connect(func(id, _state):
		if id == hotspot_id:
			_refresh_hollow_visual()
			queue_redraw()
	)
	set_process(residence_id == "hollow_creek_farmhouse")
	if residence_id == "hollow_creek_farmhouse":
		_build_hollow_visual()
		_refresh_hollow_visual()

func _build_hollow_visual() -> void:
	_hollow_back = TextureRect.new()
	_hollow_back.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hollow_back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hollow_back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hollow_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hollow_back)
	_hollow_item = TextureRect.new()
	_hollow_item.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hollow_item.offset_left = 10.0
	_hollow_item.offset_top = 10.0
	_hollow_item.offset_right = -10.0
	_hollow_item.offset_bottom = -10.0
	_hollow_item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hollow_item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hollow_item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hollow_item)

func _refresh_hollow_visual() -> void:
	if _hollow_back == null:
		return
	var fixed := is_completed()
	_hollow_back.texture = HOLLOW_REPAIRED if fixed else HOLLOW_RING
	_hollow_back.modulate = Color(1, 1, 1, 0.82 if fixed else 0.78)
	_hollow_back.pivot_offset = size * 0.5
	_hollow_back.scale = Vector2.ONE * (0.64 if fixed else 1.0)
	_hollow_item.visible = fixed
	if fixed:
		var level: int = int(HOLLOW_ITEM_LEVELS.get(hotspot_id, 2))
		_hollow_item.texture = load("res://assets/items/construction/level_%d.png" % level)
		_hollow_item.pivot_offset = (size - Vector2(20, 20)) * 0.5
		_hollow_item.scale = Vector2.ONE * 0.64

func _process(delta: float) -> void:
	_pulse_time += delta
	if _hollow_back != null and not is_completed():
		var pulse := 1.0 + sin(_pulse_time * 2.4) * 0.055
		_hollow_back.pivot_offset = size * 0.5
		_hollow_back.scale = Vector2.ONE * pulse

func is_completed() -> bool:
	return ResidenceManager.get_hotspot_state(hotspot_id) == ResidenceHotspot.State.COMPLETED

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		tapped.emit(hotspot_id)

func _draw() -> void:
	var s: Vector2 = size
	var fixed := is_completed()
	if residence_id == "hollow_creek_farmhouse":
		return
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
		"fuel_pumps":
			for i in 2:
				draw_rect(Rect2(s.x * (0.22 + i * 0.36), s.y * 0.3, s.x * 0.22, s.y * 0.55), base)
				if fixed:
					draw_rect(Rect2(s.x * (0.28 + i * 0.36), s.y * 0.4, s.x * 0.1, s.y * 0.12), accent)
		"service_bay":
			draw_rect(Rect2(s.x * 0.12, s.y * 0.2, s.x * 0.76, s.y * 0.6), base, false, 3.0)
			for i in 4:
				draw_line(Vector2(s.x * 0.12, s.y * (0.32 + i * 0.12)), Vector2(s.x * 0.88, s.y * (0.32 + i * 0.12)), base, 2.0)
		"convenience_store":
			for i in 3:
				draw_rect(Rect2(s.x * (0.15 + i * 0.24), s.y * 0.25, s.x * 0.18, s.y * 0.55), base)
		"cashier_office":
			draw_rect(Rect2(s.x * 0.2, s.y * 0.2, s.x * 0.6, s.y * 0.5), base, false, 3.0)
			draw_line(Vector2(s.x * 0.5, s.y * 0.2), Vector2(s.x * 0.5, s.y * 0.7), base, 2.0)
			if not fixed:
				draw_line(Vector2(s.x * 0.22, s.y * 0.22), Vector2(s.x * 0.78, s.y * 0.68), accent, 2.5)
		"generator_room":
			draw_rect(Rect2(s.x * 0.28, s.y * 0.2, s.x * 0.44, s.y * 0.6), base)
			for i in 3:
				draw_line(Vector2(s.x * 0.34, s.y * (0.32 + i * 0.14)), Vector2(s.x * 0.66, s.y * (0.32 + i * 0.14)), accent, 2.0)
		"perimeter_fence":
			for i in 5:
				draw_line(Vector2(s.x * (0.1 + i * 0.18), s.y * 0.85), Vector2(s.x * (0.1 + i * 0.18), s.y * 0.3), base, 3.0)
			draw_line(Vector2(s.x * 0.1, s.y * 0.45), Vector2(s.x * 0.82, s.y * 0.45), base, 2.0)
			draw_line(Vector2(s.x * 0.1, s.y * 0.65), Vector2(s.x * 0.82, s.y * 0.65), base, 2.0)
		"drainage_tunnel":
			draw_arc(Vector2(s.x * 0.5, s.y * 0.7), s.x * 0.32, PI, TAU, 20, base, 4.0)
			if fixed:
				draw_circle(Vector2(s.x * 0.5, s.y * 0.68), s.x * 0.12, accent)
		"garage_workshop":
			draw_rect(Rect2(s.x * 0.18, s.y * 0.55, s.x * 0.64, s.y * 0.16), base)
			var pts2 := PackedVector2Array([
				Vector2(s.x * 0.42, s.y * 0.55), Vector2(s.x * 0.5, s.y * 0.2), Vector2(s.x * 0.58, s.y * 0.55),
			])
			draw_polyline(pts2, base, 3.0)
		"main_hall":
			draw_rect(Rect2(s.x * 0.12, s.y * 0.2, s.x * 0.76, s.y * 0.65), base, false, 3.0)
			draw_line(Vector2(s.x * 0.5, s.y * 0.2), Vector2(s.x * 0.5, s.y * 0.85), base, 3.0)
			if not fixed:
				draw_line(Vector2(s.x * 0.14, s.y * 0.24), Vector2(s.x * 0.86, s.y * 0.8), accent, 2.5)
		"gymnasium":
			draw_rect(Rect2(s.x * 0.3, s.y * 0.18, s.x * 0.06, s.y * 0.5), base)
			draw_arc(Vector2(s.x * 0.6, s.y * 0.5), s.x * 0.16, 0, TAU, 20, base, 3.0)
			if fixed:
				draw_circle(Vector2(s.x * 0.6, s.y * 0.5), s.x * 0.04, accent)
		"library":
			for i in 5:
				var bx: float = s.x * (0.18 + i * 0.14)
				draw_rect(Rect2(bx, s.y * (0.85 - (0.1 + 0.06 * (i % 3))), s.x * 0.08, s.y * (0.1 + 0.06 * (i % 3))), base)
		"cafeteria":
			draw_rect(Rect2(s.x * 0.2, s.y * 0.42, s.x * 0.6, s.y * 0.1), base)
			draw_rect(Rect2(s.x * 0.24, s.y * 0.58, s.x * 0.52, s.y * 0.06), base)
			draw_rect(Rect2(s.x * 0.24, s.y * 0.7, s.x * 0.52, s.y * 0.06), base)
		"boiler_room":
			draw_rect(Rect2(s.x * 0.32, s.y * 0.25, s.x * 0.36, s.y * 0.55), base, false, 3.0)
			for i in 3:
				draw_line(Vector2(s.x * 0.32, s.y * (0.38 + i * 0.14)), Vector2(s.x * 0.16, s.y * (0.38 + i * 0.14)), accent if not fixed else base, 2.5)
		"admin_office":
			draw_rect(Rect2(s.x * 0.2, s.y * 0.5, s.x * 0.6, s.y * 0.12), base)
			draw_rect(Rect2(s.x * 0.66, s.y * 0.25, s.x * 0.14, s.y * 0.37), base)
		"playground_fence":
			for i in 6:
				var fx: float = s.x * (0.06 + i * 0.15)
				draw_line(Vector2(fx, s.y * 0.85), Vector2(fx + s.x * 0.075, s.y * 0.35), base, 2.0)
				draw_line(Vector2(fx + s.x * 0.075, s.y * 0.85), Vector2(fx, s.y * 0.35), base, 2.0)
		"radio_tower":
			var tpts := PackedVector2Array([
				Vector2(s.x * 0.42, s.y * 0.9), Vector2(s.x * 0.5, s.y * 0.12), Vector2(s.x * 0.58, s.y * 0.9),
			])
			draw_polyline(tpts, base, 3.0)
			draw_line(Vector2(s.x * 0.44, s.y * 0.55), Vector2(s.x * 0.56, s.y * 0.55), base, 2.5)
			draw_line(Vector2(s.x * 0.46, s.y * 0.72), Vector2(s.x * 0.54, s.y * 0.72), base, 2.5)
			if fixed:
				draw_circle(Vector2(s.x * 0.5, s.y * 0.12), s.x * 0.03, accent)
		"reception_er":
			draw_rect(Rect2(s.x * 0.16, s.y * 0.22, s.x * 0.68, s.y * 0.6), base, false, 3.0)
			draw_line(Vector2(s.x * 0.5, s.y * 0.22), Vector2(s.x * 0.5, s.y * 0.82), base, 3.0)
			draw_line(Vector2(s.x * 0.36, s.y * 0.42), Vector2(s.x * 0.64, s.y * 0.42), accent, 4.0)
			draw_line(Vector2(s.x * 0.5, s.y * 0.3), Vector2(s.x * 0.5, s.y * 0.54), accent, 4.0)
		"pharmacy":
			for i in 3:
				for j in 3:
					var bx: float = s.x * (0.22 + j * 0.2)
					var by: float = s.y * (0.3 + i * 0.18)
					draw_rect(Rect2(bx, by, s.x * 0.1, s.y * 0.12), base)
		"patient_ward":
			draw_rect(Rect2(s.x * 0.2, s.y * 0.5, s.x * 0.6, s.y * 0.28), base)
			draw_rect(Rect2(s.x * 0.2, s.y * 0.36, s.x * 0.14, s.y * 0.18), accent)
		"surgical_suite":
			draw_rect(Rect2(s.x * 0.3, s.y * 0.55, s.x * 0.4, s.y * 0.16), base)
			draw_arc(Vector2(s.x * 0.5, s.y * 0.3), s.x * 0.14, 0, TAU, 20, base, 3.0)
			for i in 6:
				var angle: float = TAU * i / 6.0
				draw_line(Vector2(s.x * 0.5, s.y * 0.3), Vector2(s.x * 0.5, s.y * 0.3) + Vector2(cos(angle), sin(angle)) * s.x * 0.06, base, 2.0)
		"power_room":
			draw_rect(Rect2(s.x * 0.32, s.y * 0.22, s.x * 0.36, s.y * 0.58), base, false, 3.0)
			var bolt := PackedVector2Array([
				Vector2(s.x * 0.54, s.y * 0.32), Vector2(s.x * 0.44, s.y * 0.54), Vector2(s.x * 0.5, s.y * 0.54),
				Vector2(s.x * 0.46, s.y * 0.72),
			])
			draw_polyline(bolt, accent, 2.5)
		"ambulance_bay":
			draw_rect(Rect2(s.x * 0.16, s.y * 0.4, s.x * 0.68, s.y * 0.36), base)
			draw_line(Vector2(s.x * 0.42, s.y * 0.5), Vector2(s.x * 0.58, s.y * 0.5), accent, 4.0)
			draw_line(Vector2(s.x * 0.5, s.y * 0.42), Vector2(s.x * 0.5, s.y * 0.58), accent, 4.0)
			if fixed:
				draw_circle(Vector2(s.x * 0.26, s.y * 0.78), s.x * 0.05, base)
				draw_circle(Vector2(s.x * 0.74, s.y * 0.78), s.x * 0.05, base)
		"records_office":
			for i in 3:
				draw_rect(Rect2(s.x * 0.28, s.y * (0.28 + i * 0.2), s.x * 0.44, s.y * 0.14), base)
		"isolation_ward":
			draw_rect(Rect2(s.x * 0.22, s.y * 0.2, s.x * 0.56, s.y * 0.64), base, false, 3.0)
			draw_circle(Vector2(s.x * 0.5, s.y * 0.42), s.x * 0.1, base if not fixed else accent)
			if not fixed:
				draw_line(Vector2(s.x * 0.42, s.y * 0.34), Vector2(s.x * 0.58, s.y * 0.5), Color("1a1917"), 2.0)
		"sally_port":
			draw_rect(Rect2(s.x * 0.14, s.y * 0.18, s.x * 0.72, s.y * 0.68), base, false, 3.0)
			for i in 5:
				var gx: float = s.x * (0.22 + i * 0.14)
				draw_line(Vector2(gx, s.y * 0.22), Vector2(gx, s.y * 0.82), base, 3.0)
		"guard_tower":
			draw_rect(Rect2(s.x * 0.38, s.y * 0.1, s.x * 0.24, s.y * 0.3), base)
			draw_line(Vector2(s.x * 0.32, s.y * 0.9), Vector2(s.x * 0.4, s.y * 0.4), base, 3.0)
			draw_line(Vector2(s.x * 0.68, s.y * 0.9), Vector2(s.x * 0.6, s.y * 0.4), base, 3.0)
			if fixed:
				draw_rect(Rect2(s.x * 0.44, s.y * 0.18, s.x * 0.12, s.y * 0.1), accent)
		"armory":
			draw_rect(Rect2(s.x * 0.2, s.y * 0.22, s.x * 0.6, s.y * 0.56), base, false, 3.0)
			for i in 3:
				draw_line(Vector2(s.x * 0.28, s.y * (0.36 + i * 0.14)), Vector2(s.x * 0.72, s.y * (0.36 + i * 0.14)), base, 2.0)
		"mess_hall":
			draw_rect(Rect2(s.x * 0.16, s.y * 0.46, s.x * 0.68, s.y * 0.1), base)
			draw_rect(Rect2(s.x * 0.2, s.y * 0.6, s.x * 0.6, s.y * 0.06), base)
		"cell_block_a":
			draw_rect(Rect2(s.x * 0.2, s.y * 0.2, s.x * 0.6, s.y * 0.62), base, false, 3.0)
			for i in 5:
				var cx: float = s.x * (0.28 + i * 0.1)
				draw_line(Vector2(cx, s.y * 0.24), Vector2(cx, s.y * 0.78), base, 2.0)
		"control_room":
			draw_rect(Rect2(s.x * 0.24, s.y * 0.3, s.x * 0.52, s.y * 0.4), base, false, 3.0)
			for i in 3:
				for j in 2:
					draw_rect(Rect2(s.x * (0.3 + i * 0.16), s.y * (0.38 + j * 0.16), s.x * 0.08, s.y * 0.08), accent if fixed else base)
		"transport_bay":
			draw_rect(Rect2(s.x * 0.14, s.y * 0.42, s.x * 0.72, s.y * 0.3), base)
			draw_rect(Rect2(s.x * 0.6, s.y * 0.3, s.x * 0.24, s.y * 0.18), base)
			if fixed:
				draw_circle(Vector2(s.x * 0.28, s.y * 0.76), s.x * 0.05, accent)
				draw_circle(Vector2(s.x * 0.72, s.y * 0.76), s.x * 0.05, accent)
		"warden_office":
			draw_rect(Rect2(s.x * 0.22, s.y * 0.52, s.x * 0.56, s.y * 0.14), base)
			draw_rect(Rect2(s.x * 0.32, s.y * 0.18, s.x * 0.36, s.y * 0.3), base, false, 3.0)
			for i in 4:
				var bx: float = s.x * (0.38 + i * 0.08)
				draw_line(Vector2(bx, s.y * 0.2), Vector2(bx, s.y * 0.46), base, 2.0)
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
	if not GameManager.effects_enabled():
		return
	# Focus -> materials arrive -> work pulse -> installed overlay -> inspect.
	# The gameplay state has already completed before this presentation starts.
	pivot_offset = size * 0.5
	var base_scale := scale
	var focus := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	focus.tween_property(self, "scale", base_scale * 1.14, 0.16)
	focus.tween_property(self, "rotation", -0.035, 0.08)
	focus.tween_property(self, "rotation", 0.045, 0.10)
	focus.tween_property(self, "rotation", 0.0, 0.08)
	focus.tween_property(self, "scale", base_scale, 0.18).set_trans(Tween.TRANS_BACK)
	var burst := TextureRect.new()
	burst.size = size
	burst.global_position = global_position
	burst.pivot_offset = size * 0.5
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.texture = HOLLOW_RING
	burst.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	burst.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	get_parent().add_child(burst)
	var tween := burst.create_tween()
	burst.scale = Vector2(0.25, 0.25)
	tween.tween_property(burst, "scale", Vector2(0.72, 0.72), 0.12).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(0.10)
	tween.tween_property(burst, "scale", Vector2(2.2, 2.2), 0.45).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(burst, "modulate:a", 0.0, 0.45)
	tween.tween_callback(burst.queue_free)
