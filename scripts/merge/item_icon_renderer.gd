extends RefCounted
class_name ItemIconRenderer
## Draws a placeholder icon for any ItemDefinition directly in-engine, per
## the placeholder art policy (ART_ASSET_GUIDE.md): a readable, consistent,
## category-specific silhouette rather than a blank rectangle. One reusable
## renderer instead of 101 bespoke drawings - swapping in real art later
## means pointing icon_path at a real texture and skipping this call, no
## gameplay code changes required.

const RARITY_COLORS := {
	ItemDefinition.Rarity.COMMON: Color("9aa39a"),
	ItemDefinition.Rarity.UNCOMMON: Color("6b7a56"),
	ItemDefinition.Rarity.RARE: Color("cf6a3f"),
	ItemDefinition.Rarity.STORY: Color("e8b93d"),
}

## Draws into `control` (any Control - assumes _draw() is calling this)
## filling its full `size`. board_item may be null (e.g. info-panel preview
## of a definition the player hasn't picked up an instance of yet).
static func draw(control: Control, def: ItemDefinition, board_item: BoardItem = null) -> void:
	var s: Vector2 = control.size
	var rarity_color: Color = RARITY_COLORS.get(def.rarity, RARITY_COLORS[ItemDefinition.Rarity.COMMON])

	_draw_background(control, s, rarity_color, def.is_producer)
	_draw_silhouette(control, s, def.chain_id)

	if def.is_producer:
		_draw_producer_ring(control, s, rarity_color)
		if board_item != null:
			if board_item.charge_count == 0:
				_draw_exhausted_overlay(control, s)
			elif board_item.is_on_cooldown():
				_draw_cooldown_overlay(control, s, board_item, def)
	else:
		_draw_level_badge(control, s, def.level)

	if board_item != null:
		if board_item.is_locked:
			_draw_lock_overlay(control, s)
		if board_item.has_cobweb:
			_draw_cobweb_overlay(control, s)
		if board_item.is_in_bubble:
			_draw_bubble_overlay(control, s)

static func _draw_background(control: Control, s: Vector2, rarity_color: Color, is_producer: bool) -> void:
	var bg_color := rarity_color.darkened(0.55)
	bg_color.a = 0.9
	control.draw_rect(Rect2(Vector2.ZERO, s), bg_color, true)
	var border_width := 3.0 if is_producer else 2.0
	control.draw_rect(Rect2(Vector2.ZERO, s), rarity_color, false, border_width)

static func _draw_level_badge(control: Control, s: Vector2, level: int) -> void:
	var r := s.x * 0.16
	var center := Vector2(s.x - r - 2.0, s.y - r - 2.0)
	control.draw_circle(center, r, Color("1c1b1a"))
	control.draw_circle(center, r, Color("e8dcc5"), false, 1.5)
	var font := ThemeDB.fallback_font
	var text := str(level)
	var font_size := int(r * 1.1)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	control.draw_string(font, center - text_size * 0.5 + Vector2(0, text_size.y * 0.35), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color("e8dcc5"))

static func _draw_producer_ring(control: Control, s: Vector2, rarity_color: Color) -> void:
	control.draw_arc(s * 0.5, minf(s.x, s.y) * 0.46, 0, TAU, 32, rarity_color.lightened(0.2), 3.0)

static func _draw_cooldown_overlay(control: Control, s: Vector2, board_item: BoardItem, def: ItemDefinition) -> void:
	var remaining: float = maxf(0.0, board_item.cooldown_end_unix - Time.get_unix_time_from_system())
	var fraction: float = clampf(remaining / maxf(def.producer_cooldown_seconds, 0.01), 0.0, 1.0)
	if fraction <= 0.0:
		return
	var points := PackedVector2Array([s * 0.5])
	var start := -PI * 0.5
	var end := start + TAU * fraction
	var steps := 24
	for i in steps + 1:
		var t: float = start + (end - start) * (float(i) / steps)
		points.append(s * 0.5 + Vector2(cos(t), sin(t)) * minf(s.x, s.y) * 0.48)
	control.draw_colored_polygon(points, Color(0, 0, 0, 0.55))

static func _draw_exhausted_overlay(control: Control, s: Vector2) -> void:
	control.draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.55), true)
	control.draw_line(Vector2(4, 4), s - Vector2(4, 4), Color("b23a2e"), 3.0)
	control.draw_line(Vector2(4, s.y - 4), Vector2(s.x - 4, 4), Color("b23a2e"), 3.0)

static func _draw_lock_overlay(control: Control, s: Vector2) -> void:
	var c := Vector2(s.x - 14, 14)
	control.draw_rect(Rect2(c + Vector2(-8, -2), Vector2(16, 13)), Color("e8dcc5"))
	control.draw_arc(c + Vector2(0, -4), 7.0, PI, TAU, 12, Color("e8dcc5"), 2.5)

static func _draw_cobweb_overlay(control: Control, s: Vector2) -> void:
	var c := Vector2.ZERO
	var col := Color(0.85, 0.85, 0.85, 0.7)
	for i in 4:
		var t: float = (PI * 0.5) * (float(i) / 3.0)
		control.draw_line(c, c + Vector2(cos(t), sin(t)) * s.x * 0.35, col, 1.5)
	control.draw_arc(c, s.x * 0.18, 0, PI * 0.5, 8, col, 1.5)
	control.draw_arc(c, s.x * 0.3, 0, PI * 0.5, 8, col, 1.5)

static func _draw_bubble_overlay(control: Control, s: Vector2) -> void:
	control.draw_arc(s * 0.5, minf(s.x, s.y) * 0.54, 0, TAU, 24, Color(0.6, 0.8, 1.0, 0.5), 2.0)

## Category silhouette per chain. Kept intentionally simple/geometric -
## readable at small board-cell size, distinct between chains, not a
## generic circle/rectangle. See ART_ASSET_GUIDE.md for the final-art brief
## these are standing in for.
static func _draw_silhouette(control: Control, s: Vector2, chain_id: String) -> void:
	var c := s * 0.5
	var col := Color("e8dcc5")
	match chain_id:
		"construction":
			for i in 3:
				var y: float = s.y * (0.38 + i * 0.14)
				control.draw_rect(Rect2(Vector2(s.x * 0.22, y), Vector2(s.x * 0.56, s.y * 0.08)), col)
		"tool":
			control.draw_rect(Rect2(Vector2(c.x - s.x * 0.06, s.y * 0.28), Vector2(s.x * 0.12, s.y * 0.4)), col)
			control.draw_rect(Rect2(Vector2(s.x * 0.24, s.y * 0.22), Vector2(s.x * 0.52, s.y * 0.16)), col)
		"food":
			control.draw_rect(Rect2(Vector2(s.x * 0.28, s.y * 0.32), Vector2(s.x * 0.44, s.y * 0.4)), col)
			control.draw_rect(Rect2(Vector2(s.x * 0.34, s.y * 0.24), Vector2(s.x * 0.32, s.y * 0.1)), col)
		"medical":
			control.draw_rect(Rect2(Vector2(c.x - s.x * 0.07, s.y * 0.26), Vector2(s.x * 0.14, s.y * 0.46)), col)
			control.draw_rect(Rect2(Vector2(s.x * 0.26, c.y - s.y * 0.07), Vector2(s.x * 0.48, s.y * 0.14)), col)
		"trap":
			var pts := PackedVector2Array([
				Vector2(s.x * 0.2, s.y * 0.7), Vector2(s.x * 0.36, s.y * 0.4), Vector2(s.x * 0.5, s.y * 0.68),
				Vector2(s.x * 0.64, s.y * 0.36), Vector2(s.x * 0.8, s.y * 0.7),
			])
			for i in pts.size() - 1:
				control.draw_line(pts[i], pts[i + 1], col, 2.5)
		"fuel":
			var pts := PackedVector2Array([
				Vector2(c.x, s.y * 0.2), Vector2(s.x * 0.72, s.y * 0.55), Vector2(s.x * 0.62, s.y * 0.8),
				Vector2(s.x * 0.38, s.y * 0.8), Vector2(s.x * 0.28, s.y * 0.55),
			])
			control.draw_colored_polygon(pts, col)
		"vehicle_parts":
			control.draw_arc(c, s.x * 0.22, 0, TAU, 16, col, 4.0)
			control.draw_circle(c, s.x * 0.07, Color("1c1b1a"))
		"electronics":
			control.draw_rect(Rect2(Vector2(s.x * 0.24, s.y * 0.24), Vector2(s.x * 0.52, s.y * 0.52)), col, false, 2.0)
			control.draw_line(Vector2(c.x, s.y * 0.24), Vector2(c.x, s.y * 0.1), col, 2.0)
			control.draw_line(Vector2(c.x, s.y * 0.76), Vector2(c.x, s.y * 0.9), col, 2.0)
			control.draw_circle(c, s.x * 0.06, Color("1c1b1a"))
		"clothing":
			var pts := PackedVector2Array([
				Vector2(s.x * 0.32, s.y * 0.24), Vector2(s.x * 0.5, s.y * 0.34), Vector2(s.x * 0.68, s.y * 0.24),
				Vector2(s.x * 0.8, s.y * 0.4), Vector2(s.x * 0.68, s.y * 0.48), Vector2(s.x * 0.68, s.y * 0.78),
				Vector2(s.x * 0.32, s.y * 0.78), Vector2(s.x * 0.32, s.y * 0.48), Vector2(s.x * 0.2, s.y * 0.4),
			])
			control.draw_colored_polygon(pts, col)
		"energy_reward":
			var pts := PackedVector2Array([
				Vector2(s.x * 0.55, s.y * 0.18), Vector2(s.x * 0.32, s.y * 0.56), Vector2(s.x * 0.48, s.y * 0.56),
				Vector2(s.x * 0.4, s.y * 0.84), Vector2(s.x * 0.68, s.y * 0.42), Vector2(s.x * 0.52, s.y * 0.42),
			])
			control.draw_colored_polygon(pts, Color("e8b93d"))
		"coin_reward":
			control.draw_circle(c, s.x * 0.26, Color("e8b93d"))
			control.draw_circle(c, s.x * 0.26, Color("8a6a1a"), false, 2.0)
		"xp_reward":
			_draw_star(control, c, s.x * 0.28, Color("6fa8dc"))
		"token_reward":
			var pts := PackedVector2Array()
			for i in 6:
				var t: float = TAU * i / 6.0 - PI / 6.0
				pts.append(c + Vector2(cos(t), sin(t)) * s.x * 0.27)
			control.draw_colored_polygon(pts, Color("cf6a3f"))
		_:
			control.draw_circle(c, s.x * 0.25, col)

## Small standalone swatch (background + category silhouette, no level/
## producer badges) for contexts that represent a whole chain rather than
## one item instance - e.g. the merge board's chain-highlight legend.
static func draw_chain_swatch(control: Control, chain_id: String, rarity: ItemDefinition.Rarity = ItemDefinition.Rarity.UNCOMMON) -> void:
	var s: Vector2 = control.size
	var rarity_color: Color = RARITY_COLORS.get(rarity, RARITY_COLORS[ItemDefinition.Rarity.UNCOMMON])
	_draw_background(control, s, rarity_color, false)
	_draw_silhouette(control, s, chain_id)

static func _draw_star(control: Control, center: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var t: float = TAU * i / 10.0 - PI * 0.5
		var radius := r if i % 2 == 0 else r * 0.45
		pts.append(center + Vector2(cos(t), sin(t)) * radius)
	control.draw_colored_polygon(pts, col)
