extends Control
class_name MergeParticle
## One reusable burst particle, pooled by MergeVFX rather than created and
## freed per merge. Its shape is a small procedural primitive (this project
## has no image-generation tool to author dozens of bespoke particle
## sprites), colored and sized per chain so a merge's material reads as
## wood/metal/fabric/etc. instead of one generic look for every chain.

var shape := "crumb"
var color := Color.WHITE

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

## Prepares this pooled particle for one burst use. Does not touch position/
## rotation/scale/modulate - the caller tweens those itself so timing stays
## identical to the previous per-merge implementation.
func prime(new_shape: String, new_color: Color, particle_size: Vector2) -> void:
	shape = new_shape
	color = new_color
	size = particle_size
	pivot_offset = size * 0.5
	visible = true
	rotation = 0.0
	scale = Vector2.ONE
	modulate = Color(color, 1.0)
	queue_redraw()

## Returns this particle to the pool: hidden, no longer drawing, ready for
## the next prime() - never freed, so repeated merges don't churn nodes.
func release() -> void:
	visible = false

func _draw() -> void:
	if not visible:
		return
	var c := color
	var s := size
	var half := s * 0.5
	match shape:
		"shard": # thin rotated splinter - Construction
			draw_rect(Rect2(-half.x, -half.y * 0.3, s.x, s.y * 0.6), c)
		"puff": # soft dust mote - Construction
			draw_circle(Vector2.ZERO, half.x, Color(c, 0.85))
		"fragment": # small angular chip - Tool/Trap
			var pts := PackedVector2Array([
				Vector2(-half.x, -half.y * 0.5), Vector2(half.x * 0.7, -half.y),
				Vector2(half.x, half.y * 0.6), Vector2(-half.x * 0.6, half.y),
			])
			draw_colored_polygon(pts, c)
		"spark": # bright short streak - Tool/Vehicle Parts
			draw_line(Vector2(-half.x, -half.y), Vector2(half.x, half.y), c, 2.0)
			draw_line(Vector2(-half.x, half.y), Vector2(half.x, -half.y), Color(c, 0.5), 1.0)
		"crumb": # small round mote - Food
			draw_circle(Vector2.ZERO, half.x, c)
		"fleck": # tiny leaf/packaging fleck - Food
			var pts := PackedVector2Array([Vector2(0, -half.y), Vector2(half.x, 0), Vector2(0, half.y), Vector2(-half.x, 0)])
			draw_colored_polygon(pts, c)
		"cross": # restrained medical cross - Medical
			draw_rect(Rect2(-s.x * 0.14, -half.y, s.x * 0.28, s.y), c)
			draw_rect(Rect2(-half.x, -s.y * 0.14, s.x, s.y * 0.28), c)
		"glint": # small soft diamond sparkle - Medical/Fuel
			var pts := PackedVector2Array([
				Vector2(0, -half.y), Vector2(half.x * 0.35, -half.y * 0.2), Vector2(half.x, 0),
				Vector2(half.x * 0.35, half.y * 0.2), Vector2(0, half.y), Vector2(-half.x * 0.35, half.y * 0.2),
				Vector2(-half.x, 0), Vector2(-half.x * 0.35, -half.y * 0.2),
			])
			draw_colored_polygon(pts, c)
		"cord": # short curved fibre/cord strand - Trap
			draw_line(Vector2(-half.x, half.y * 0.6), Vector2.ZERO, c, 1.6)
			draw_line(Vector2.ZERO, Vector2(half.x, half.y * 0.6), c, 1.6)
		"droplet": # small teardrop - Fuel
			var pts := PackedVector2Array([
				Vector2(0, -half.y), Vector2(half.x * 0.75, half.y * 0.55),
				Vector2(0, half.y), Vector2(-half.x * 0.75, half.y * 0.55),
			])
			draw_colored_polygon(pts, c)
		"chunk": # heavier metal chunk - Vehicle Parts
			var pts := PackedVector2Array([
				Vector2(-half.x, -half.y * 0.7), Vector2(half.x * 0.8, -half.y),
				Vector2(half.x, half.y * 0.8), Vector2(-half.x * 0.7, half.y),
			])
			draw_colored_polygon(pts, c)
		"ring": # radio pulse ring - Electronics
			draw_arc(Vector2.ZERO, half.x, 0.0, TAU, 16, c, 2.0)
		"zigzag": # small electrical arc - Electronics
			draw_line(Vector2(-half.x, -half.y), Vector2(-half.x * 0.15, 0), c, 1.6)
			draw_line(Vector2(-half.x * 0.15, 0), Vector2(half.x * 0.5, -half.y * 0.4), c, 1.6)
			draw_line(Vector2(half.x * 0.5, -half.y * 0.4), Vector2(half.x, half.y), c, 1.6)
		"fiber": # soft cloth thread - Clothing
			draw_line(Vector2(-half.x, 0), Vector2(0, -half.y * 0.4), c, 1.8)
			draw_line(Vector2(0, -half.y * 0.4), Vector2(half.x, 0), c, 1.8)
		_:
			draw_circle(Vector2.ZERO, half.x, c)
