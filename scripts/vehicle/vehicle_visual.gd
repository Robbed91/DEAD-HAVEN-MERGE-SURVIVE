extends Control
class_name VehicleVisual
## Procedural delivery-van silhouette that visibly changes across all 9
## upgrade stages: the body colour shifts from rust/damaged toward clean
## olive as stage/8 increases, and each stage lights up one more concrete
## detail (wheels, fuel cap, storage rack, window tint, front ram, roof
## box, antenna) rather than nothing visibly changing between stages.

@export var stage: int = 0:
	set(value):
		stage = value
		queue_redraw()
const MAX_STAGE := 8
var _motion_time := 0.0
var _engine_running := false
var _door_open := false
var _upgrade_flash := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	if not is_visible_in_tree() or not GameManager.effects_enabled():
		return
	_motion_time += delta
	_upgrade_flash = maxf(0.0, _upgrade_flash - delta * 1.8)
	queue_redraw()

func play_upgrade_sequence() -> void:
	if not GameManager.effects_enabled():
		_engine_running = stage >= 1
		return
	_upgrade_flash = 1.0
	_engine_running = stage >= 1
	_door_open = true
	var tween := create_tween()
	tween.tween_interval(0.28)
	tween.tween_callback(func(): _door_open = false; queue_redraw())
	tween.tween_interval(0.12)
	tween.tween_callback(func(): _engine_running = true; queue_redraw())

func _draw() -> void:
	var s: Vector2 = size
	var progress: float = float(stage) / float(MAX_STAGE)
	var body_color: Color = Color("6b4a35").lerp(Color("6b7a56"), progress)
	var suspension := sin(_motion_time * 9.0) * 1.4 if _engine_running else 0.0
	draw_set_transform(Vector2(0, suspension))

	# Body.
	draw_rect(Rect2(s.x * 0.08, s.y * 0.35, s.x * 0.84, s.y * 0.32), body_color)
	draw_rect(Rect2(s.x * 0.08, s.y * 0.2, s.x * 0.4, s.y * 0.18), body_color)

	# Wheels (stage 2+: replaced, drawn solid; before: flat/cracked).
	var wheel_color: Color = Color("2a2825") if stage >= 2 else Color("4a2020")
	draw_circle(Vector2(s.x * 0.22, s.y * 0.7), s.x * 0.07, wheel_color)
	draw_circle(Vector2(s.x * 0.78, s.y * 0.7), s.x * 0.07, wheel_color)
	if _engine_running:
		var wheel_angle := _motion_time * 5.0
		for wheel_x in [s.x * 0.22, s.x * 0.78]:
			draw_line(Vector2(wheel_x, s.y * 0.7), Vector2(wheel_x, s.y * 0.7) + Vector2.from_angle(wheel_angle) * s.x * 0.05, Color("8a8f8a"), 2.0)
		for i in 5:
			var dust_x := fmod(_motion_time * (28.0 + i * 4.0) + i * 11.0, 78.0)
			draw_circle(Vector2(s.x * 0.82 + dust_x, s.y * 0.74 + sin(i) * 4.0), 3.0 + i * 0.8, Color(0.48, 0.40, 0.30, 0.10))

	# Engine highlight (stage 1+).
	if stage >= 1:
		draw_rect(Rect2(s.x * 0.1, s.y * 0.38, s.x * 0.1, s.y * 0.1), Color("e8b93d"))

	# Fuel cap glow (stage 3+).
	if stage >= 3:
		draw_circle(Vector2(s.x * 0.5, s.y * 0.4), s.x * 0.02, Color("cf6a3f"))

	# Storage rack (stage 4+).
	if stage >= 4:
		draw_rect(Rect2(s.x * 0.55, s.y * 0.35, s.x * 0.3, s.y * 0.04), Color("8a8f8a"))

	# Window tint (stage 5+).
	var window_color: Color = Color("6fa8dc").darkened(0.2) if stage >= 5 else Color("1c1b1a")
	draw_rect(Rect2(s.x * 0.12, s.y * 0.22, s.x * 0.14, s.y * 0.1), window_color)
	# Door movement and headlights are presentation states driven by upgrades.
	if _door_open:
		draw_rect(Rect2(s.x * 0.36, s.y * 0.28, s.x * 0.18, s.y * 0.3), body_color.darkened(0.18), false, 4.0)
	if _engine_running:
		var headlight_alpha := 0.55 + sin(_motion_time * 4.0) * 0.08
		draw_circle(Vector2(s.x * 0.09, s.y * 0.48), s.x * 0.025, Color(1.0, 0.78, 0.32, headlight_alpha))
		for i in 3:
			var drift := fmod(_motion_time * (16.0 + i * 5.0), 34.0)
			draw_circle(Vector2(s.x * 0.94 + drift, s.y * (0.55 - i * 0.04)), 3.5 + i, Color(0.5, 0.52, 0.5, 0.15))

	# Front ram (stage 6+).
	if stage >= 6:
		draw_rect(Rect2(s.x * 0.04, s.y * 0.45, s.x * 0.06, s.y * 0.14), Color("8a8f8a"))

	# Roof storage (stage 7+).
	if stage >= 7:
		draw_rect(Rect2(s.x * 0.15, s.y * 0.15, s.x * 0.3, s.y * 0.06), Color("6b4a35"))

	# Long-range antenna (stage 8, fully upgraded).
	if stage >= 8:
		draw_line(Vector2(s.x * 0.85, s.y * 0.2), Vector2(s.x * 0.92, s.y * 0.05), Color("e8dcc5"), 2.0)
	if _upgrade_flash > 0.0:
		draw_circle(s * Vector2(0.5, 0.43), s.x * (0.34 + (1.0 - _upgrade_flash) * 0.12), Color(0.91, 0.73, 0.24, _upgrade_flash * 0.16), false, 5.0)
	draw_set_transform(Vector2.ZERO)
