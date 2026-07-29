extends Control
## WorldMapBackground
##
## Original placeholder regional map: a dusty cream paper tone with a
## hand-drawn-style route line connecting residence markers. Real
## illustrated terrain, weather overlays and faction territories are
## Phase 8 content.

const PAPER := Color("e8dcc5")
const PAPER_SHADE := Color("d8c9a2")
const ROUTE := Color("6b4a35")

func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), PAPER)
	for i in 40:
		var rx := fmod(float(i) * 137.0, s.x)
		var ry := fmod(float(i) * 251.0, s.y)
		draw_circle(Vector2(rx, ry), 1.5, PAPER_SHADE)

	var route := PackedVector2Array([
		Vector2(s.x * 0.5, s.y * 0.2),
		Vector2(s.x * 0.42, s.y * 0.36),
		Vector2(s.x * 0.6, s.y * 0.5),
		Vector2(s.x * 0.45, s.y * 0.64),
		Vector2(s.x * 0.55, s.y * 0.8),
	])
	draw_polyline(route, ROUTE, 4.0, true)
