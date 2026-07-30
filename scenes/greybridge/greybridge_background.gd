extends Control
## GreybridgeBackground
##
## Original internally-drawn placeholder illustration for Greybridge
## School (cold overcast midday) - same layered/procedural technique as
## haven_background.gd and redwater_background.gd, given a third distinct
## palette/time-of-day (flat grey daylight rather than Hollow Creek's warm
## day or Redwater's dusk) so all three residences read as different
## places at a glance even as procedural placeholders.

const SKY_TOP := Color("6b7278")
const SKY_BOTTOM := Color("9aa2a0")
const GROUND := Color("6e6a5e")
const GROUND_DARK := Color("55524a")
const BRICK := Color("7a5a4a")
const BRICK_DARK := Color("5c4238")
const ROOF := Color("3a3835")
const DAMAGE := Color("201f1c")
const TOWER := Color("8a8f8a")

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var s := size

	# Sky - flat, cold, overcast (no gradient bands - the point is a duller,
	# flatter light than either other residence).
	var bands := 12
	for i in bands:
		var t := float(i) / float(bands - 1)
		draw_rect(Rect2(0, s.y * 0.4 * t, s.x, s.y * 0.4 / bands + 1), SKY_TOP.lerp(SKY_BOTTOM, t))

	# Playground / grounds.
	draw_rect(Rect2(0, s.y * 0.4, s.x, s.y * 0.6), GROUND)
	for i in 8:
		var x := s.x * float(i) / 7.0
		draw_line(Vector2(x, s.y * 0.7), Vector2(x, s.y * 0.98), GROUND_DARK, 2.0)

	# Gymnasium wing (background layer, left side - lower, flat-roofed).
	var gym_w := s.x * 0.26
	var gym_x := s.x * 0.04
	draw_rect(Rect2(gym_x, s.y * 0.52, gym_w, s.y * 0.24), BRICK_DARK)
	draw_rect(Rect2(gym_x, s.y * 0.49, gym_w, s.y * 0.04), ROOF)

	# Main school building (mid-ground, two-storey brick block).
	var main_w := s.x * 0.62
	var main_x := s.x * 0.5 - main_w * 0.5
	var wall_top := s.y * 0.32
	var wall_bottom := s.y * 0.76

	draw_rect(Rect2(main_x, wall_top, main_w, wall_bottom - wall_top), BRICK)
	draw_rect(Rect2(main_x, wall_top - 10, main_w, 12), ROOF)

	# Window rows (damage layer - several hotspots live roughly here).
	for row in 2:
		for col in 5:
			var wx: float = main_x + main_w * (0.08 + col * 0.18)
			var wy: float = wall_top + (wall_bottom - wall_top) * (0.15 + row * 0.32)
			draw_rect(Rect2(wx, wy, main_w * 0.11, (wall_bottom - wall_top) * 0.16), DAMAGE)

	# Main hall double doors (front_door-equivalent hotspot area).
	var door_pos := Vector2(main_x + main_w * 0.5 - 26, wall_bottom - 70)
	draw_rect(Rect2(door_pos, Vector2(52, 70)), DAMAGE)
	draw_line(door_pos + Vector2(26, 0), door_pos + Vector2(26, 70), Color("1a1917"), 2.0)

	# Radio tower on the roof (foreground structure - radio_tower hotspot).
	var tower_base := Vector2(s.x * 0.5, wall_top - 10)
	draw_line(tower_base, tower_base + Vector2(-10, -70), TOWER, 4.0)
	draw_line(tower_base, tower_base + Vector2(10, -70), TOWER, 4.0)
	draw_line(tower_base + Vector2(-6, -42), tower_base + Vector2(6, -42), TOWER, 2.5)
	draw_line(tower_base + Vector2(-3, -70), tower_base + Vector2(3, -70), TOWER, 2.5)
	draw_circle(tower_base + Vector2(0, -74), 3.0, Color("cf6a3f"))

	# Playground fence (closest layer, adds depth).
	var fence_color := GROUND_DARK
	for i in 10:
		var x := s.x * float(i) / 9.0
		draw_line(Vector2(x, s.y - 8), Vector2(x + 8, s.y - 30), fence_color, 3.0)
