extends Control
## MainMenuBackground
##
## Original, internally-drawn placeholder scene (no external image assets):
## a cool night sky, a distant treeline, and the silhouette of a boarded
## farmhouse doorway with warm light spilling through the gaps - the same
## motif as the app icon, established here as the game's visual identity.
## Replace with painted art later; nothing else needs to change to do so.

const SKY_TOP := Color("1a1e22")
const SKY_BOTTOM := Color("100f0e")
const TREELINE := Color("14130f")
const HOUSE := Color("201d1a")
const WOOD_BOARD := Color("8f4a26")
const GLOW := Color(0.96, 0.82, 0.55, 0.5)
const GROUND := Color("0e0d0b")

var _glow_phase: float = 0.0

func _ready() -> void:
	set_process(not GameManager.settings.get("reduced_motion", false))

func _process(delta: float) -> void:
	_glow_phase += delta * 0.6
	queue_redraw()

func _draw() -> void:
	var s := size
	# Sky gradient (drawn as stacked bands - no shader dependency).
	var bands := 24
	for i in bands:
		var t := float(i) / float(bands - 1)
		draw_rect(Rect2(0, s.y * t * 0.6, s.x, s.y * 0.6 / bands + 1), SKY_TOP.lerp(SKY_BOTTOM, t))
	draw_rect(Rect2(0, s.y * 0.6, s.x, s.y * 0.4), SKY_BOTTOM)

	# Distant treeline silhouette.
	var tree_y := s.y * 0.62
	var points := PackedVector2Array()
	points.append(Vector2(0, s.y * 0.7))
	var segments := 10
	for i in segments + 1:
		var x := s.x * float(i) / float(segments)
		var jitter := sin(float(i) * 1.7) * 18.0
		points.append(Vector2(x, tree_y + jitter))
	points.append(Vector2(s.x, s.y * 0.7))
	draw_colored_polygon(points, TREELINE)

	# Ground.
	draw_rect(Rect2(0, s.y * 0.7, s.x, s.y * 0.3), GROUND)

	# Warm glow behind the doorway (pulses gently unless reduced motion).
	var pulse := 1.0 if GameManager.settings.get("reduced_motion", false) else (0.85 + 0.15 * sin(_glow_phase))
	var house_center_x := s.x * 0.5
	var glow_center := Vector2(house_center_x, s.y * 0.66)
	draw_circle(glow_center, s.x * 0.42 * pulse, GLOW)

	# Farmhouse silhouette (simple roofline + walls).
	var house_w := s.x * 0.62
	var house_left := house_center_x - house_w * 0.5
	var roof_peak := Vector2(house_center_x, s.y * 0.42)
	var wall_top := s.y * 0.56
	var wall_bottom := s.y * 0.78
	var house_points := PackedVector2Array([
		Vector2(house_left, wall_bottom),
		Vector2(house_left, wall_top),
		roof_peak,
		Vector2(house_left + house_w, wall_top),
		Vector2(house_left + house_w, wall_bottom),
	])
	draw_colored_polygon(house_points, HOUSE)

	# Boarded doorway.
	var door_w := s.x * 0.14
	var door_h := s.y * 0.16
	var door_pos := Vector2(house_center_x - door_w * 0.5, wall_bottom - door_h)
	draw_rect(Rect2(door_pos, Vector2(door_w, door_h)), Color("0c0b0a"))
	var board_count := 4
	for i in board_count:
		var by := door_pos.y + door_h * (float(i) + 0.5) / float(board_count)
		draw_line(door_pos + Vector2(-2, by - door_pos.y), door_pos + Vector2(door_w + 2, by - door_pos.y), WOOD_BOARD, 5.0)
