extends Control
## WorldMapBackground
##
## Route overlay for the final illustrated regional map. Marker positions
## and destinations remain gameplay-driven in world_map.gd.

const ROUTE_SHADOW := Color(0.04, 0.05, 0.05, 0.82)
const ROUTE := Color(0.84, 0.54, 0.22, 0.92)

func _draw() -> void:
	var s := size
	var route := PackedVector2Array([
		Vector2(s.x * 0.5, s.y * 0.2),
		Vector2(s.x * 0.42, s.y * 0.36),
		Vector2(s.x * 0.6, s.y * 0.5),
		Vector2(s.x * 0.45, s.y * 0.64),
		Vector2(s.x * 0.55, s.y * 0.8),
	])
	draw_polyline(route, ROUTE_SHADOW, 9.0, true)
	draw_polyline(route, ROUTE, 4.0, true)
