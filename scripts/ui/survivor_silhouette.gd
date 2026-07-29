extends Control
class_name SurvivorSilhouette
## Placeholder character portrait: a simple head-and-shoulders bust
## silhouette in a solid colour. Stands in for the illustrated portraits
## required by ART_ASSET_GUIDE until real art is produced - every survivor
## card uses this same shape so the roster reads consistently in the
## meantime, and swapping in real portraits later touches no gameplay code.

@export var silhouette_color: Color = Color("6b7a56")
@export var locked: bool = false

func _draw() -> void:
	var s := size
	var col := silhouette_color
	if locked:
		col = Color(0.3, 0.3, 0.3)

	# Shoulders (rounded trapezoid).
	var shoulder_top := s.y * 0.62
	var points := PackedVector2Array([
		Vector2(s.x * 0.5, shoulder_top),
		Vector2(s.x * 0.08, s.y),
		Vector2(s.x * 0.92, s.y),
	])
	draw_colored_polygon(points, col)

	# Head.
	draw_circle(Vector2(s.x * 0.5, s.y * 0.34), s.x * 0.24, col)

	if locked:
		# Simple padlock glyph so "locked" reads clearly even at a glance.
		var lock_center := Vector2(s.x * 0.5, s.y * 0.5)
		draw_rect(Rect2(lock_center + Vector2(-10, -2), Vector2(20, 16)), Color("e8dcc5"))
		draw_arc(lock_center + Vector2(0, -6), 9.0, PI, TAU, 16, Color("e8dcc5"), 3.0)
