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

func _draw() -> void:
	var s: Vector2 = size
	var progress: float = float(stage) / float(MAX_STAGE)
	var body_color: Color = Color("6b4a35").lerp(Color("6b7a56"), progress)

	# Body.
	draw_rect(Rect2(s.x * 0.08, s.y * 0.35, s.x * 0.84, s.y * 0.32), body_color)
	draw_rect(Rect2(s.x * 0.08, s.y * 0.2, s.x * 0.4, s.y * 0.18), body_color)

	# Wheels (stage 2+: replaced, drawn solid; before: flat/cracked).
	var wheel_color: Color = Color("2a2825") if stage >= 2 else Color("4a2020")
	draw_circle(Vector2(s.x * 0.22, s.y * 0.7), s.x * 0.07, wheel_color)
	draw_circle(Vector2(s.x * 0.78, s.y * 0.7), s.x * 0.07, wheel_color)

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

	# Front ram (stage 6+).
	if stage >= 6:
		draw_rect(Rect2(s.x * 0.04, s.y * 0.45, s.x * 0.06, s.y * 0.14), Color("8a8f8a"))

	# Roof storage (stage 7+).
	if stage >= 7:
		draw_rect(Rect2(s.x * 0.15, s.y * 0.15, s.x * 0.3, s.y * 0.06), Color("6b4a35"))

	# Long-range antenna (stage 8, fully upgraded).
	if stage >= 8:
		draw_line(Vector2(s.x * 0.85, s.y * 0.2), Vector2(s.x * 0.92, s.y * 0.05), Color("e8dcc5"), 2.0)
