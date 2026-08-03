extends Control
class_name MergeBoard
const MotionFXScript = preload("res://scripts/vfx/motion_fx.gd")
const MergeParticleScript = preload("res://scripts/vfx/merge_particle.gd")
## MergeBoard
##
## Phase 2: the real, playable merge board - grid drag-and-drop, merge
## rules, producers, energy, storage transfer, tap-for-info/long-press
## detail panels, and the chain-highlight legend (this phase's honest stand
## -in for "task highlighting", since real residence tasks don't exist
## until Phase 3 - see DEVELOPMENT_LOG.md).

const COLUMNS := BoardState.COLUMNS
const ROWS := BoardState.ROWS

@export var embedded: bool = false

@onready var _grid: GridContainer = %BoardGrid
@onready var _legend: HBoxContainer = %ChainLegend
@onready var _storage_button: Button = %StorageButton
@onready var _storage_panel: StoragePanel = %StoragePanel
@onready var _info_panel: ItemInfoPanel = %ItemInfoPanel
@onready var _discovery_banner: DiscoveryBanner = %DiscoveryBanner
@onready var _burst_layer: Control = %BurstLayer

var _cells: Dictionary = {} # Vector2i -> BoardCell
var _highlighted_chain_id: String = ""
var _selected_instance_id: String = ""
var _interaction_busy := false

## Pooled merge-burst particles - sized for one burst's worth (max 12 at
## level >= 5) with headroom; reused via prime()/release() instead of
## instantiated and freed per merge. _on_drop_attempted() already refuses a
## new merge while one is animating (_interaction_busy), so one burst's
## capacity is all any single MergeBoard instance ever needs at once.
const PARTICLE_POOL_SIZE := 16
var _particle_pool: Array[MergeParticle] = []
var _glow_pool: Array[TextureRect] = []

func _ready() -> void:
	$Layout/HeaderRow/Header.add_theme_font_override("font", ThemeFactory.display_font())
	_storage_button.add_theme_font_size_override("font_size", 18)
	_storage_button.add_theme_stylebox_override("normal", ThemeFactory.compact_button_style())
	_storage_button.add_theme_stylebox_override("pressed", ThemeFactory.compact_button_style(Color(0.72, 0.72, 0.72, 1)))
	_build_grid()
	_build_legend()
	_build_vfx_pools()
	_storage_button.pressed.connect(func():
		if _storage_panel.visible:
			_storage_panel.hide_panel()
		else:
			_storage_panel.show_panel()
	)
	_storage_panel.item_tapped.connect(func(id): _info_panel.show_for(id, false))
	_storage_panel.item_long_pressed.connect(func(id): _info_panel.show_for(id, true))
	_info_panel.changed.connect(_on_state_changed)
	EventBus.producer_unlocked.connect(func(_producer_item_id): refresh_board())
	refresh_board()

	if not embedded:
		var params := SceneRouter.take_pending_params()
		if params.has("highlight_chain_id") and not String(params.highlight_chain_id).is_empty():
			highlight_chain(String(params.highlight_chain_id))

func _build_grid() -> void:
	_grid.columns = COLUMNS
	for cell in _grid.get_children():
		cell.queue_free()
	_cells.clear()
	for y in ROWS:
		for x in COLUMNS:
			var pos := Vector2i(x, y)
			var cell := BoardCell.new()
			cell.setup(pos, embedded)
			if embedded:
				cell.custom_minimum_size = Vector2(68, 68)
			cell.drop_attempted.connect(_on_drop_attempted)
			_grid.add_child(cell)
			_cells[pos] = cell

func _build_legend() -> void:
	for child in _legend.get_children():
		child.queue_free()
	for chain_id in ItemDatabase.get_all_chain_ids():
		if ItemDatabase.is_reward_chain(chain_id):
			continue
		var icon := ChainLegendIcon.new()
		icon.chain_id = chain_id
		icon.tapped.connect(_on_legend_tapped)
		_legend.add_child(icon)

func _on_legend_tapped(chain_id: String) -> void:
	_highlighted_chain_id = "" if _highlighted_chain_id == chain_id else chain_id
	_refresh_legend_selection()
	_apply_highlight()

func highlight_chain(chain_id: String) -> void:
	_highlighted_chain_id = chain_id if chain_id in ItemDatabase.get_all_chain_ids() else ""
	_refresh_legend_selection()
	_apply_highlight()

func get_highlighted_chain_id() -> String:
	return _highlighted_chain_id

func _refresh_legend_selection() -> void:
	for icon in _legend.get_children():
		icon.set_selected(icon.chain_id == _highlighted_chain_id)

func _apply_highlight() -> void:
	for pos in _cells:
		var cell: BoardCell = _cells[pos]
		if cell.item_view == null:
			continue
		if _highlighted_chain_id.is_empty():
			cell.item_view.modulate.a = 1.0
			continue
		var def := cell.item_view.get_def()
		cell.item_view.modulate.a = 1.0 if (def != null and def.chain_id == _highlighted_chain_id) else 0.3

# -- Board refresh -------------------------------------------------------

func refresh_board() -> void:
	for pos in _cells:
		var cell: BoardCell = _cells[pos]
		var view := cell.refresh()
		if view != null:
			_connect_item_view(view)
			view.set_selected_visual(view.instance_id == _selected_instance_id)
	_apply_highlight()
	if _storage_panel.visible:
		_storage_panel.refresh()

func _connect_item_view(view: ItemView) -> void:
	view.tapped.connect(_on_item_tapped)
	view.double_tapped.connect(_on_item_double_tapped)
	view.long_pressed.connect(_on_item_long_pressed)

func _on_state_changed() -> void:
	refresh_board()

# -- Interaction -----------------------------------------------------------

func _on_item_tapped(instance_id: String) -> void:
	_selected_instance_id = instance_id
	_apply_selection()
	_info_panel.show_for(instance_id, false)

func _apply_selection() -> void:
	for pos in _cells:
		var cell: BoardCell = _cells[pos]
		if cell.item_view != null:
			cell.item_view.set_selected_visual(cell.item_view.instance_id == _selected_instance_id)

func _on_item_long_pressed(instance_id: String) -> void:
	_info_panel.show_for(instance_id, true)

func _on_item_double_tapped(instance_id: String) -> void:
	if _interaction_busy:
		return
	var def := BoardState.get_item_def(instance_id)
	if def == null:
		return
	if not def.is_producer:
		_info_panel.show_for(instance_id, false)
		return
	var result := BoardState.tap_producer(instance_id)
	if result.success:
		refresh_board()
		_play_producer_activation(instance_id)
		_play_pop_at_instance(result.spawned_instance_id)
		AudioManager.play_sfx("producer_activate")
	else:
		_play_producer_failure(instance_id, result.reason)
		_toast_for_producer_failure(result.reason, String(result.get("unlock_label", "")))

func _on_drop_attempted(dragged_id: String, cell: BoardCell) -> void:
	if _interaction_busy:
		return
	var target_pos := cell.grid_pos
	if BoardState.is_cell_free(target_pos):
		if BoardState.move_to_cell(dragged_id, target_pos):
			refresh_board()
			_play_pop_at_instance(dragged_id)
			AudioManager.play_sfx("item_drop")
			return

	var occupant_id: String = BoardState.grid.get(target_pos, "")
	var source_view := _find_item_view(dragged_id)
	var target_view := cell.item_view
	var result := BoardState.try_merge(dragged_id, occupant_id)
	if result.success:
		_interaction_busy = true
		AudioManager.play_sfx("merge_pull")
		await _play_merge_pull(source_view, target_view)
		refresh_board()
		var result_def := ItemDatabase.get_item(result.resulting_item_id)
		var level := result_def.level if result_def != null else 1
		_play_merge_reward(target_pos, level, result_def.chain_id if result_def != null else "")
		_play_result_expansion(result.resulting_instance_id)
		AudioManager.play_sfx("merge_high" if level >= 5 else _merge_audio_key(result_def.chain_id if result_def != null else ""))
		if result.is_discovery:
			_discovery_banner.show_item(result.resulting_item_id)
			AudioManager.play_sfx("discovery")
		_interaction_busy = false
	else:
		_play_invalid_shake(cell)
		if result.reason == "max_level" and cell.item_view != null:
			MotionFXScript.pulse(cell.item_view, Color("e8b93d"), 2)
		AudioManager.play_sfx("merge_invalid")
		_toast_for_merge_failure(result.reason)

# -- Feedback / animation --------------------------------------------------

func _effects_disabled() -> bool:
	return not GameManager.effects_enabled()

func _play_pop_at_instance(instance_id: String) -> void:
	var bi: BoardItem = BoardState.items.get(instance_id)
	if bi == null or not bi.is_on_board():
		return
	var cell: BoardCell = _cells.get(bi.grid_position)
	if cell == null or cell.item_view == null:
		return
	if _effects_disabled():
		return
	var view := cell.item_view
	view.scale = Vector2(0.5, 0.5)
	view.pivot_offset = view.size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(view, "scale", Vector2(1.15, 1.15), 0.16)
	tween.tween_property(view, "scale", Vector2.ONE, 0.1)

func _find_item_view(instance_id: String) -> ItemView:
	for node in find_children("*", "ItemView", true, false):
		if node is ItemView and node.instance_id == instance_id:
			return node
	return null

func _play_merge_pull(source: ItemView, target: ItemView) -> void:
	if _effects_disabled() or source == null or target == null:
		await get_tree().process_frame
		return
	source.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	source.pivot_offset = source.size * 0.5
	target.pivot_offset = target.size * 0.5
	var destination := target.global_position
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(source, "global_position", destination, 0.16)
	tween.parallel().tween_property(source, "scale", Vector2(0.72, 0.72), 0.16)
	tween.parallel().tween_property(target, "scale", Vector2(0.72, 0.72), 0.16)
	tween.tween_property(source, "scale", Vector2(0.34, 0.34), 0.07)
	tween.parallel().tween_property(target, "scale", Vector2(0.34, 0.34), 0.07)
	await tween.finished

func _play_result_expansion(instance_id: String) -> void:
	var bi: BoardItem = BoardState.items.get(instance_id)
	if bi == null or not bi.is_on_board():
		return
	var cell: BoardCell = _cells.get(bi.grid_position)
	if cell == null or cell.item_view == null or _effects_disabled():
		return
	var view := cell.item_view
	view.pivot_offset = view.size * 0.5
	view.scale = Vector2(0.28, 0.28)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(view, "scale", Vector2(1.20, 1.20), 0.19)
	tween.tween_property(view, "scale", Vector2(0.94, 0.94), 0.08).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(view, "scale", Vector2.ONE, 0.08)

## Preallocates the pooled glow/particle nodes once, as children of
## _burst_layer, hidden until a burst primes and shows them. Never freed -
## repeated merges reuse the same nodes instead of churning new ones.
func _build_vfx_pools() -> void:
	for i in 2: # one for a normal burst, one spare so a fast repeat merge never waits
		var glow := TextureRect.new()
		glow.texture = load("res://assets/ui/merge_board/reward_glow.png")
		glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.visible = false
		_burst_layer.add_child(glow)
		_glow_pool.append(glow)
	for i in PARTICLE_POOL_SIZE:
		var particle := MergeParticleScript.new()
		_burst_layer.add_child(particle)
		_particle_pool.append(particle)

func _acquire_glow() -> TextureRect:
	for glow in _glow_pool:
		if not glow.visible:
			return glow
	return _glow_pool[0] # pool exhausted (shouldn't happen) - reuse the oldest rather than grow unbounded

func _acquire_particle() -> MergeParticle:
	for particle in _particle_pool:
		if not particle.visible:
			return particle
	return null # pool exhausted - burst_plan() never asks for more than PARTICLE_POOL_SIZE, so this just quietly draws fewer

## Reduced motion always gets a short fade/glow (never skipped entirely,
## unlike the old blanket _effects_disabled() gate) but no flying
## particles. Low graphics quality keeps the full sequence but with fewer
## particles (see MergeVFX.burst_plan). There is no separate "fully off"
## case distinct from those two settings for a one-shot burst like this.
func _play_merge_reward(grid_pos: Vector2i, level: int, chain_id: String) -> void:
	var reduced_motion: bool = GameManager.settings.get("reduced_motion", false)
	var quality := String(GameManager.settings.get("graphics_quality", "standard"))
	var cell: BoardCell = _cells.get(grid_pos)
	if cell == null:
		return
	var center := cell.global_position + cell.size * 0.5

	var glow := _acquire_glow()
	glow.size = cell.size * (1.9 if level >= 5 else 1.45)
	glow.global_position = center - glow.size * 0.5
	glow.pivot_offset = glow.size * 0.5
	glow.scale = Vector2(0.45, 0.45)
	glow.modulate.a = 1.0
	glow.visible = true
	var glow_duration := 0.18 if reduced_motion else 0.40
	var glow_tween := create_tween()
	glow_tween.tween_property(glow, "scale", Vector2(1.1 if reduced_motion else 1.35, 1.1 if reduced_motion else 1.35), glow_duration * 0.85).set_trans(Tween.TRANS_CUBIC)
	glow_tween.parallel().tween_property(glow, "modulate:a", 0.0, glow_duration)
	glow_tween.tween_callback(func(): glow.visible = false)

	if reduced_motion:
		return # reduced motion: short fade/glow only, no flying particles

	var plan := MergeVFX.burst_plan(chain_id, level, quality)
	var particles: Array = plan.particles
	var count: int = particles.size()
	for i in count:
		var particle := _acquire_particle()
		if particle == null:
			break
		var spec: Dictionary = particles[i]
		particle.prime(String(spec.shape), spec.color, spec.particle_size)
		particle.global_position = center - particle.size * 0.5
		var angle := TAU * float(i) / float(count) + randf_range(-0.14, 0.14)
		var distance := randf_range(30.0, 54.0) * (1.25 if level >= 5 else 1.0)
		var particle_tween := create_tween().set_parallel(true)
		particle_tween.tween_property(particle, "global_position", particle.global_position + Vector2.from_angle(angle) * distance, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		particle_tween.tween_property(particle, "rotation", randf_range(-2.4, 2.4), 0.42)
		particle_tween.tween_property(particle, "modulate:a", 0.0, 0.42).set_delay(0.12)
		particle_tween.chain().tween_callback(particle.release)

func _play_producer_activation(instance_id: String) -> void:
	var view := _find_item_view(instance_id)
	if view == null:
		return
	view.play_producer_visual_state("active", 0.42)
	if _effects_disabled():
		return
	view.pivot_offset = view.size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(view, "scale", Vector2(1.14, 1.14), 0.12)
	tween.tween_property(view, "scale", Vector2.ONE, 0.16)

func _play_producer_failure(instance_id: String, reason: String) -> void:
	var view := _find_item_view(instance_id)
	if view == null:
		return
	if reason == "exhausted":
		view.play_producer_visual_state("empty", 0.46)
		AudioManager.play_sfx("producer_empty")
	elif reason == "cooldown":
		view.play_producer_visual_state("recharge", 0.46)
		AudioManager.play_sfx("producer_recharge")
	var cell: BoardCell = view.get_parent() as BoardCell
	if cell != null:
		_play_invalid_shake(cell)

func _play_invalid_shake(cell: BoardCell) -> void:
	if _effects_disabled() or cell.item_view == null:
		return
	var view := cell.item_view
	var base_pos := view.position
	var tween := create_tween()
	for i in 4:
		var offset: float = 6.0 if i % 2 == 0 else -6.0
		tween.tween_property(view, "position", base_pos + Vector2(offset, 0), 0.04)
	tween.tween_property(view, "position", base_pos, 0.04)

func _toast_for_merge_failure(reason: String) -> void:
	var messages := {
		"not_matching": "Those items don't match.",
		"item_blocked": "Clear the box or match the cobwebbed item first.",
		"max_level": "Already at maximum level.",
		"producers_do_not_merge": "Producers can't be merged.",
		"no_space": "No space for the result.",
	}
	if messages.has(reason):
		EventBus.show_toast.emit(messages[reason])

func _merge_audio_key(chain_id: String) -> String:
	if chain_id == "construction": return "merge_wood"
	if chain_id in ["tool", "trap", "vehicle_parts", "clothing"]: return "merge_metal"
	if chain_id == "medical": return "merge_medical"
	if chain_id == "food": return "merge_food"
	if chain_id in ["electronics", "energy_reward"]: return "merge_electronics"
	if chain_id == "fuel": return "merge_fuel"
	return "merge_generic"

func _toast_for_producer_failure(reason: String, unlock_label: String = "") -> void:
	var messages := {
		"cooldown": "Still recharging.",
		"exhausted": "This producer is used up.",
		"no_energy": "Not enough energy.",
		"board_full": "The board is full.",
		"producer_locked": "Unlocks after: %s." % unlock_label,
	}
	if messages.has(reason):
		EventBus.show_toast.emit(messages[reason])
