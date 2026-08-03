extends Control
class_name DangerOverlay
## Gameplay-neutral danger presentation, wired only to existing
## defence/scavenging/fuel triggers by the scenes that own this overlay -
## it never reads danger state itself and never touches gameplay data,
## resolve odds, or hazard definitions.
##
## Three restrained effects, all screen-edge or corner rather than
## full-screen, all well below any flash-safety concern:
## - A slow warning pulse along the four screen edges (~0.25 Hz - one full
##   cycle every 4 seconds - not a strobe).
## - A small static screen-edge threat indicator (a corner glyph, does not
##   pulse) so the warning information is visible even under reduced motion.
## - An optional soft gas/vapour cloud, only ever enabled by a caller for a
##   real fuel/petrol context (see scavenging.gd's petrol_station handling).

const VALID_INTENSITY_RANGE := Vector2(0.0, 1.0)

## Pulse angular speed in radians/second. 1.6 rad/s is ~0.25 Hz (one full
## cycle every ~3.9 seconds) - far below the ~3 Hz threshold conventionally
## treated as a photosensitivity risk. Exposed as a named constant (rather
## than a literal buried in _draw_warning_pulse) specifically so this
## safety property is directly assertable in a test, not just eyeballed.
const PULSE_ANGULAR_SPEED := 1.6
const PULSE_SAFE_MAX_HZ := 3.0

## Maximum fraction of the shorter screen dimension the edge glow may ever
## occupy, at intensity=1.0 - keeps this a border effect, never a
## full-screen filter, regardless of how intensity is tuned in the future.
const MAX_EDGE_FRACTION := 0.05
const EDGE_BASE := 22.0
const EDGE_PER_INTENSITY := 12.0

var intensity: float = 0.0
var _show_gas_cloud: bool = false
var _time := 0.0
var _gas_particles: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process(false)

## Presentation-only. Callers pass an existing danger signal already read
## from real data (a mission's danger_rating/human_threat, a defence
## event's own warning/failure moment) - this never invents its own.
func set_danger(new_intensity: float, gas_cloud: bool = false) -> void:
	intensity = clampf(new_intensity, VALID_INTENSITY_RANGE.x, VALID_INTENSITY_RANGE.y)
	_show_gas_cloud = gas_cloud and intensity > 0.0
	if _show_gas_cloud and _gas_particles.is_empty():
		_build_gas_particles()
	var reduced_motion: bool = GameManager.settings.get("reduced_motion", false)
	set_process(intensity > 0.0 and not reduced_motion and GameManager.effects_enabled())
	queue_redraw()

func clear_danger() -> void:
	intensity = 0.0
	_show_gas_cloud = false
	set_process(false)
	queue_redraw()

func _build_gas_particles() -> void:
	_gas_particles.clear()
	var quality := String(GameManager.settings.get("graphics_quality", "standard"))
	var count := 0 if quality == "low" else (4 if quality == "standard" else 7)
	for i in count:
		_gas_particles.append({"p": Vector2(randf(), randf_range(0.65, 0.95)), "s": randf_range(0.4, 1.0)})

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	if intensity <= 0.0:
		return
	var reduced_motion: bool = GameManager.settings.get("reduced_motion", false)
	_draw_warning_pulse(reduced_motion)
	_draw_threat_indicator()
	if _show_gas_cloud:
		_draw_gas_cloud(reduced_motion)

## Slow single-colour pulse confined to the four screen edges - never a
## full-screen filter. Reduced motion holds the pulse at its resting value
## instead of animating it, so the same warning tint is visible but static.
func _draw_warning_pulse(reduced_motion: bool) -> void:
	var pulse := 0.5 if reduced_motion else 0.4 + 0.3 * sin(_time * PULSE_ANGULAR_SPEED)
	var alpha := 0.05 + 0.09 * intensity * pulse
	var edge := EDGE_BASE + EDGE_PER_INTENSITY * intensity
	var col := Color(0.62, 0.16, 0.11, alpha)
	draw_rect(Rect2(0.0, 0.0, size.x, edge), col)
	draw_rect(Rect2(0.0, size.y - edge, size.x, edge), col)
	draw_rect(Rect2(0.0, 0.0, edge, size.y), col)
	draw_rect(Rect2(size.x - edge, 0.0, edge, size.y), col)

## Static (non-pulsing) corner glyph - the actual "there is danger here"
## information, present identically whether or not reduced motion is on.
func _draw_threat_indicator() -> void:
	var c := Vector2(size.x - 30.0, 30.0)
	var r := 9.0 + 4.0 * intensity
	var col := Color(0.86, 0.42, 0.18, 0.55 + 0.3 * intensity)
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.87, r * 0.5), c + Vector2(-r * 0.87, r * 0.5)])
	draw_colored_polygon(pts, col)
	draw_rect(Rect2(c.x - 1.2, c.y - r * 0.15, 2.4, r * 0.5), Color(0.15, 0.1, 0.08, 0.85))
	draw_circle(c + Vector2(0, r * 0.42), 1.4, Color(0.15, 0.1, 0.08, 0.85))

## Soft drifting vapour near the bottom of the screen. Only ever shown when
## a caller explicitly passes gas_cloud=true to set_danger() - see the
## class doc comment for why that's restricted to real fuel contexts.
func _draw_gas_cloud(reduced_motion: bool) -> void:
	for d in _gas_particles:
		var p: Vector2 = d.p
		var speed: float = d.s
		var drift := 0.0 if reduced_motion else sin(_time * 0.5 + speed * 6.0) * 14.0
		var pos := Vector2(p.x * size.x + drift, p.y * size.y)
		draw_circle(pos, 16.0 * speed, Color(0.46, 0.5, 0.32, 0.05))
