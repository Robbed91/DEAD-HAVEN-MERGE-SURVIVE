extends Control
## SaintMercyBackground
##
## Original internally-drawn placeholder illustration for Saint Mercy
## Hospital (night, emergency lighting) - same layered/procedural
## technique as the other three residence backgrounds, given a fourth
## distinct palette/time-of-day again: full night rather than any of
## Hollow Creek's day, Redwater's dusk, or Greybridge's flat overcast
## daylight, lit mostly by a sickly green-white emergency glow from a few
## still-working windows rather than any warm light source.

const SKY_TOP := Color("0d1015")
const SKY_BOTTOM := Color("1c2420")
const GROUND := Color("242220")
const GROUND_DARK := Color("171615")
const WALL := Color("8a8f8a")
const WALL_DARK := Color("6b7070")
const ROOF := Color("2a2b28")
const DAMAGE := Color("111110")
const EMERGENCY_GLOW := Color("6fae7a")
const AMBULANCE := Color("cfcac0")

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var s := size

	# Night sky, no gradient warmth anywhere.
	var bands := 10
	for i in bands:
		var t := float(i) / float(bands - 1)
		draw_rect(Rect2(0, s.y * 0.4 * t, s.x, s.y * 0.4 / bands + 1), SKY_TOP.lerp(SKY_BOTTOM, t))

	# Grounds / car park.
	draw_rect(Rect2(0, s.y * 0.4, s.x, s.y * 0.6), GROUND)
	for i in 6:
		var x := s.x * float(i) / 5.0
		draw_line(Vector2(x, s.y * 0.62), Vector2(x, s.y * 0.98), GROUND_DARK, 2.0)

	# Ambulance bay wing (background layer, left side).
	var bay_w := s.x * 0.24
	var bay_x := s.x * 0.05
	draw_rect(Rect2(bay_x, s.y * 0.56, bay_w, s.y * 0.2), WALL_DARK)
	draw_rect(Rect2(bay_x, s.y * 0.53, bay_w, s.y * 0.04), ROOF)

	# Main hospital block (mid-ground, several storeys, mostly dark windows).
	var main_w := s.x * 0.6
	var main_x := s.x * 0.5 - main_w * 0.5
	var wall_top := s.y * 0.26
	var wall_bottom := s.y * 0.76

	draw_rect(Rect2(main_x, wall_top, main_w, wall_bottom - wall_top), WALL)
	draw_rect(Rect2(main_x, wall_top - 8, main_w, 10), ROOF)

	# Window grid - almost all dark, a handful lit sickly green (emergency power).
	var lit_windows := [Vector2i(1, 0), Vector2i(3, 2)]
	for row in 3:
		for col in 5:
			var wx: float = main_x + main_w * (0.07 + col * 0.185)
			var wy: float = wall_top + (wall_bottom - wall_top) * (0.1 + row * 0.28)
			var win_size := Vector2(main_w * 0.1, (wall_bottom - wall_top) * 0.14)
			var lit := Vector2i(col, row) in lit_windows
			draw_rect(Rect2(wx, wy, win_size.x, win_size.y), EMERGENCY_GLOW if lit else DAMAGE)

	# ER entrance doors (damage layer - reception_er hotspot lives here).
	var door_pos := Vector2(main_x + main_w * 0.5 - 30, wall_bottom - 66)
	draw_rect(Rect2(door_pos, Vector2(60, 66)), DAMAGE)
	draw_line(door_pos + Vector2(30, 0), door_pos + Vector2(30, 66), Color("35403a"), 2.0)

	# Ambulance silhouette parked in the bay (foreground detail).
	var amb_pos := Vector2(bay_x + bay_w * 0.2, s.y * 0.68)
	draw_rect(Rect2(amb_pos, Vector2(bay_w * 0.6, s.y * 0.08)), AMBULANCE.darkened(0.6))
	draw_line(amb_pos + Vector2(bay_w * 0.25, s.y * 0.02), amb_pos + Vector2(bay_w * 0.35, s.y * 0.02), Color("b23a2e"), 3.0)

	# Foreground kerb line (closest layer, adds depth).
	for i in 8:
		var x := s.x * float(i) / 7.0
		draw_line(Vector2(x, s.y - 6), Vector2(x + 6, s.y - 24), GROUND_DARK, 3.0)
