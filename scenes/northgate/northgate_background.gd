extends Control
## NorthgateBackground
##
## Original internally-drawn placeholder illustration for Northgate
## Prison (early dawn) - same layered/procedural technique as the other
## four residence backgrounds, given a fifth distinct palette/time-of-day:
## cold grey-blue breaking to pale rose at the horizon, rather than
## Hollow Creek's day, Redwater's dusk, Greybridge's flat overcast, or
## Saint Mercy's full night - the last of the roster's "distinct time of
## day per residence" set.

const SKY_TOP := Color("2d3548")
const SKY_BOTTOM := Color("c9958f")
const GROUND := Color("4a4a48")
const GROUND_DARK := Color("34342f")
const CONCRETE := Color("8f8b80")
const CONCRETE_DARK := Color("6b675e")
const DAMAGE := Color("181714")
const TOWER := Color("54524a")
const WIRE := Color("d8d4c8")

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var s := size

	# Dawn sky.
	var bands := 14
	for i in bands:
		var t := float(i) / float(bands - 1)
		draw_rect(Rect2(0, s.y * 0.4 * t, s.x, s.y * 0.4 / bands + 1), SKY_TOP.lerp(SKY_BOTTOM, t))

	# Yard.
	draw_rect(Rect2(0, s.y * 0.4, s.x, s.y * 0.6), GROUND)
	for i in 6:
		var x := s.x * float(i) / 5.0
		draw_line(Vector2(x, s.y * 0.6), Vector2(x, s.y * 0.98), GROUND_DARK, 2.0)

	# Perimeter wall (background layer, spans most of the width).
	draw_rect(Rect2(0, s.y * 0.5, s.x, s.y * 0.14), CONCRETE_DARK)

	# Guard tower (mid-ground, right side, on stilts above the wall).
	var tower_x := s.x * 0.78
	draw_rect(Rect2(tower_x, s.y * 0.22, s.x * 0.16, s.y * 0.2), CONCRETE)
	draw_line(Vector2(tower_x - 4, s.y * 0.64), Vector2(tower_x + 8, s.y * 0.42), TOWER, 3.0)
	draw_line(Vector2(tower_x + s.x * 0.2, s.y * 0.64), Vector2(tower_x + s.x * 0.08, s.y * 0.42), TOWER, 3.0)
	draw_rect(Rect2(tower_x + s.x * 0.03, s.y * 0.26, s.x * 0.1, s.y * 0.06), DAMAGE)

	# Main cell block (mid-ground, left of centre).
	var main_w := s.x * 0.58
	var main_x := s.x * 0.06
	var wall_top := s.y * 0.34
	var wall_bottom := s.y * 0.64

	draw_rect(Rect2(main_x, wall_top, main_w, wall_bottom - wall_top), CONCRETE)
	draw_rect(Rect2(main_x, wall_top - 6, main_w, 8), CONCRETE_DARK)

	# Barred window rows (damage layer - cell_block_a lives roughly here).
	for row in 2:
		for col in 6:
			var wx: float = main_x + main_w * (0.06 + col * 0.155)
			var wy: float = wall_top + (wall_bottom - wall_top) * (0.15 + row * 0.4)
			draw_rect(Rect2(wx, wy, main_w * 0.09, (wall_bottom - wall_top) * 0.2), DAMAGE)
			for bar in 3:
				var bx: float = wx + main_w * 0.09 * float(bar) / 2.0
				draw_line(Vector2(bx, wy), Vector2(bx, wy + (wall_bottom - wall_top) * 0.2), CONCRETE_DARK, 1.5)

	# Sally port gate (foreground structure, centre).
	var gate_pos := Vector2(s.x * 0.5 - 24, wall_bottom - 6)
	draw_rect(Rect2(gate_pos, Vector2(48, 40)), DAMAGE)
	for bar in 4:
		var bx := gate_pos.x + 48.0 * float(bar) / 3.0
		draw_line(Vector2(bx, gate_pos.y), Vector2(bx, gate_pos.y + 40), CONCRETE_DARK, 2.0)

	# Razor wire fence (closest layer, adds depth and menace).
	for i in 9:
		var x := s.x * float(i) / 8.0
		draw_line(Vector2(x, s.y - 4), Vector2(x, s.y - 32), WIRE, 1.5)
		draw_line(Vector2(x - 4, s.y - 26), Vector2(x + 4, s.y - 22), WIRE, 1.0)
		draw_line(Vector2(x - 4, s.y - 22), Vector2(x + 4, s.y - 26), WIRE, 1.0)
