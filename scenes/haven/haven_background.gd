extends Control
## HavenBackground
##
## Original internally-drawn placeholder illustration for Hollow Creek
## Farmhouse (day exterior). Layered like real production art (sky, distant
## barn, house structure, damage/debris, foreground grass) even though each
## layer is procedural here - swapping in painted layers later needs no
## script changes beyond this one file (see ART_ASSET_GUIDE, added later).

const SKY_TOP := Color("6b8a92")
const SKY_BOTTOM := Color("c7b98f")
const FIELD := Color("6b7a56")
const FIELD_DARK := Color("4d5940")
const HOUSE_WALL := Color("cfc3a6")
const HOUSE_ROOF := Color("6b4a35")
const DAMAGE := Color("2a2825")
const BARN := Color("8a3c1f")

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var s := size

	# Sky.
	var bands := 16
	for i in bands:
		var t := float(i) / float(bands - 1)
		draw_rect(Rect2(0, s.y * 0.42 * t, s.x, s.y * 0.42 / bands + 1), SKY_TOP.lerp(SKY_BOTTOM, t))

	# Field.
	draw_rect(Rect2(0, s.y * 0.42, s.x, s.y * 0.58), FIELD)
	var row_spacing := 26
	var y := int(s.y * 0.46)
	while y < s.y:
		draw_line(Vector2(0, y), Vector2(s.x, y), FIELD_DARK, 2.0)
		y += row_spacing

	# Distant barn silhouette (background layer, left side).
	var barn_w := s.x * 0.24
	var barn_x := s.x * 0.06
	var barn_top := s.y * 0.5
	var barn_points := PackedVector2Array([
		Vector2(barn_x, s.y * 0.62),
		Vector2(barn_x, barn_top + 14),
		Vector2(barn_x + barn_w * 0.5, barn_top),
		Vector2(barn_x + barn_w, barn_top + 14),
		Vector2(barn_x + barn_w, s.y * 0.62),
	])
	draw_colored_polygon(barn_points, BARN.darkened(0.35))

	# Farmhouse structure (main mid-ground layer).
	var house_w := s.x * 0.72
	var house_x := s.x * 0.5 - house_w * 0.5
	var wall_top := s.y * 0.44
	var wall_bottom := s.y * 0.72
	var roof_peak := Vector2(s.x * 0.5, s.y * 0.30)

	draw_colored_polygon(PackedVector2Array([
		Vector2(house_x, wall_bottom),
		Vector2(house_x, wall_top),
		roof_peak,
		Vector2(house_x + house_w, wall_top),
		Vector2(house_x + house_w, wall_bottom),
	]), HOUSE_ROOF)

	draw_rect(Rect2(house_x + 6, wall_top + 4, house_w - 12, wall_bottom - wall_top - 4), HOUSE_WALL)

	# Broken kitchen window (damage layer - a hotspot lives roughly here).
	var win_pos := Vector2(house_x + house_w * 0.68, wall_top + (wall_bottom - wall_top) * 0.3)
	draw_rect(Rect2(win_pos, Vector2(70, 60)), DAMAGE)
	draw_line(win_pos, win_pos + Vector2(70, 60), Color("1a1917"), 3.0)
	draw_line(win_pos + Vector2(70, 0), win_pos + Vector2(0, 60), Color("1a1917"), 3.0)

	# Front door, boarded (damage layer - front door hotspot lives here).
	var door_pos := Vector2(house_x + house_w * 0.5 - 30, wall_bottom - 96)
	draw_rect(Rect2(door_pos, Vector2(60, 96)), DAMAGE)
	for i in 3:
		var by := door_pos.y + 96.0 * (float(i) + 0.5) / 3.0
		draw_line(Vector2(door_pos.x - 4, by), Vector2(door_pos.x + 64, by), Color("8f4a26"), 6.0)

	# Foreground grass tufts (closest layer, adds depth).
	var tuft_color := FIELD_DARK
	for i in 12:
		var x := s.x * float(i) / 11.0
		draw_line(Vector2(x, s.y - 10), Vector2(x + 6, s.y - 34), tuft_color, 4.0)
