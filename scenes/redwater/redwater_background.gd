extends Control
## RedwaterBackground
##
## Original internally-drawn placeholder illustration for Redwater Service
## Station (dusk exterior) - same layered/procedural technique as
## scenes/haven/haven_background.gd, deliberately given a different palette
## and time of day so the two residences read as distinct places rather
## than reskins of one background. Swapping in painted layers later needs
## no script changes beyond this one file (see ART_ASSET_GUIDE).

const SKY_TOP := Color("2c2440")
const SKY_BOTTOM := Color("c96a3e")
const ASPHALT := Color("3a3733")
const ASPHALT_LINE := Color("cbb96a")
const CANOPY := Color("7a2f2f")
const CANOPY_DARK := Color("541f1f")
const STORE_WALL := Color("b9a37c")
const GARAGE_WALL := Color("8f8577")
const DAMAGE := Color("1c1a18")
const PUMP := Color("4a5a52")

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var s := size

	# Sky (dusk gradient - the attack in Chapter 4 was spotted here at last light).
	var bands := 16
	for i in bands:
		var t := float(i) / float(bands - 1)
		draw_rect(Rect2(0, s.y * 0.4 * t, s.x, s.y * 0.4 / bands + 1), SKY_TOP.lerp(SKY_BOTTOM, t))

	# Asphalt forecourt.
	draw_rect(Rect2(0, s.y * 0.4, s.x, s.y * 0.6), ASPHALT)
	var lane_x := s.x * 0.5 - 4
	draw_line(Vector2(lane_x, s.y * 0.44), Vector2(lane_x, s.y), ASPHALT_LINE, 4.0)

	# Store building (mid-ground, right of centre).
	var store_w := s.x * 0.34
	var store_x := s.x * 0.42
	var store_top := s.y * 0.3
	var store_bottom := s.y * 0.58
	draw_rect(Rect2(store_x, store_top, store_w, store_bottom - store_top), STORE_WALL)
	draw_rect(Rect2(store_x, store_top - 10, store_w, 14), CANOPY_DARK)

	# Cashier office window (damage layer - cashier_office hotspot lives here).
	var office_pos := Vector2(store_x + store_w * 0.58, store_top + 10)
	draw_rect(Rect2(office_pos, Vector2(54, 44)), DAMAGE)
	draw_line(office_pos, office_pos + Vector2(54, 44), Color("111010"), 3.0)
	draw_line(office_pos + Vector2(54, 0), office_pos + Vector2(0, 44), Color("111010"), 3.0)

	# Garage bay (mid-ground, left of the store).
	var garage_w := s.x * 0.3
	var garage_x := s.x * 0.06
	var garage_top := s.y * 0.4
	var garage_bottom := s.y * 0.72
	draw_rect(Rect2(garage_x, garage_top, garage_w, garage_bottom - garage_top), GARAGE_WALL)
	draw_rect(Rect2(garage_x + garage_w * 0.15, garage_top + garage_w * 0.25, garage_w * 0.7, garage_bottom - garage_top - garage_w * 0.25 - 8), DAMAGE)

	# Fuel canopy over the pumps (foreground structure, left-of-centre).
	var canopy_w := s.x * 0.4
	var canopy_x := s.x * 0.16
	var canopy_y := s.y * 0.5
	draw_rect(Rect2(canopy_x, canopy_y - 14, canopy_w, 16), CANOPY)
	for i in 4:
		var post_x := canopy_x + canopy_w * float(i) / 3.0
		draw_line(Vector2(post_x, canopy_y), Vector2(post_x, s.y * 0.86), CANOPY_DARK, 6.0)

	# Fuel pumps beneath the canopy (fuel_pumps hotspot lives here).
	for i in 2:
		var pump_x := canopy_x + canopy_w * (0.3 + 0.4 * float(i))
		draw_rect(Rect2(pump_x - 12, canopy_y + 20, 24, 60), PUMP)

	# Foreground asphalt cracks (closest layer, adds depth).
	var crack_color := ASPHALT.darkened(0.3)
	for i in 10:
		var x := s.x * float(i) / 9.0
		draw_line(Vector2(x, s.y - 6), Vector2(x + 10, s.y - 26), crack_color, 3.0)
