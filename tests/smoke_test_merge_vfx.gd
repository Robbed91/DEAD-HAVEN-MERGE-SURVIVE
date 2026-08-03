extends Node
## Verifies the chain-ID-driven merge burst: MergeVFX.burst_plan()'s pure
## data is correct for all 9 gameplay chains, and the live MergeBoard reuses
## its pooled particle/glow nodes instead of creating new ones per merge,
## with reduced motion producing a glow-only burst (no flying particles).

const GAMEPLAY_CHAIN_IDS := ["construction", "tool", "food", "medical", "trap", "fuel", "vehicle_parts", "electronics", "clothing"]

var _haven: Control
var _board: MergeBoard

func _ready() -> void:
	if not _check_burst_plan_data():
		return
	if not _check_low_quality_reduces_count():
		return
	if not _check_unknown_chain_falls_back():
		return
	GameManager.new_game()
	_haven = load("res://scenes/haven/haven.tscn").instantiate()
	add_child(_haven)
	_board = _haven.get_node("%BoardPanel")
	if not _check_pool_reused_across_merges():
		return
	if not _check_reduced_motion_skips_particles():
		return
	print("SMOKE_MERGE_VFX_OK chains=%d" % GAMEPLAY_CHAIN_IDS.size())
	get_tree().quit(0)

func _check_burst_plan_data() -> bool:
	for chain_id in GAMEPLAY_CHAIN_IDS:
		if not MergeVFX.has_style(chain_id):
			_fail("%s has no MergeVFX style entry" % chain_id)
			return false
		var low_plan := MergeVFX.burst_plan(chain_id, 1, "standard")
		if int(low_plan.count) != 7 or int(low_plan.particles.size()) != 7:
			_fail("%s level-1 standard-quality burst should have 7 particles, got %s" % [chain_id, low_plan])
			return false
		var high_level_plan := MergeVFX.burst_plan(chain_id, 5, "standard")
		if int(high_level_plan.count) != 12 or not bool(high_level_plan.emphasize):
			_fail("%s level-5 burst should have 12 particles and emphasize=true, got %s" % [chain_id, high_level_plan])
			return false
		for spec in low_plan.particles:
			if String(spec.shape).is_empty():
				_fail("%s produced a particle with an empty shape" % chain_id)
				return false
	print("SMOKE_MERGE_VFX: burst_plan data correct for all 9 gameplay chains OK")
	return true

func _check_low_quality_reduces_count() -> bool:
	var standard_plan := MergeVFX.burst_plan("tool", 1, "standard")
	var low_plan := MergeVFX.burst_plan("tool", 1, "low")
	if int(low_plan.count) >= int(standard_plan.count):
		_fail("low graphics quality should reduce particle count below standard, got low=%d standard=%d" % [low_plan.count, standard_plan.count])
		return false
	if int(low_plan.count) < 1:
		_fail("low graphics quality should still show at least one particle, got %d" % low_plan.count)
		return false
	print("SMOKE_MERGE_VFX: low graphics quality reduces particle count OK")
	return true

func _check_unknown_chain_falls_back() -> bool:
	if MergeVFX.has_style("not_a_real_chain"):
		_fail("has_style() should be false for an unknown chain id")
		return false
	var plan := MergeVFX.burst_plan("not_a_real_chain", 1, "standard")
	if plan.particles.is_empty():
		_fail("an unknown chain id should still fall back to a default style rather than producing nothing")
		return false
	print("SMOKE_MERGE_VFX: unknown chain id falls back instead of failing OK")
	return true

func _check_pool_reused_across_merges() -> bool:
	var initial_particle_pool_size := _board._particle_pool.size()
	var initial_glow_pool_size := _board._glow_pool.size()
	if initial_particle_pool_size != _board.PARTICLE_POOL_SIZE:
		_fail("expected the particle pool to be pre-built at %d, found %d" % [_board.PARTICLE_POOL_SIZE, initial_particle_pool_size])
		return false

	for i in 3:
		var pos_a := BoardState.find_empty_cell()
		var a := BoardState.spawn_item("tool_1", pos_a, false)
		var pos_b := BoardState.find_empty_cell()
		var b := BoardState.spawn_item("tool_1", pos_b, false)
		var result := BoardState.try_merge(a.instance_id, b.instance_id)
		if not result.success:
			_fail("expected a same-level tool_1 merge to succeed, got %s" % result)
			return false
		_board._play_merge_reward(pos_b, 2, "tool")
		if _board._particle_pool.size() != initial_particle_pool_size or _board._glow_pool.size() != initial_glow_pool_size:
			_fail("pool sizes changed after a merge burst - nodes are being created instead of reused")
			return false

	print("SMOKE_MERGE_VFX: pooled nodes are reused across repeated merge bursts, not recreated OK")
	return true

func _check_reduced_motion_skips_particles() -> bool:
	# The previous check's particles may still be mid-tween (visible=true)
	# in real time - force a clean baseline instead of racing their tweens.
	for particle in _board._particle_pool:
		particle.release()
	for glow in _board._glow_pool:
		glow.visible = false
	GameManager.update_setting("reduced_motion", true)
	var pos := BoardState.find_empty_cell()
	_board._play_merge_reward(pos, 2, "tool")
	var any_particle_visible := false
	for particle in _board._particle_pool:
		if particle.visible:
			any_particle_visible = true
			break
	var glow_visible := false
	for glow in _board._glow_pool:
		if glow.visible:
			glow_visible = true
			break
	GameManager.update_setting("reduced_motion", false)
	if any_particle_visible:
		_fail("reduced motion should skip flying particles entirely")
		return false
	if not glow_visible:
		_fail("reduced motion should still show a short glow/fade, not nothing")
		return false
	print("SMOKE_MERGE_VFX: reduced motion shows glow only, no particles OK")
	return true

func _fail(message: String) -> void:
	print("SMOKE_MERGE_VFX_FAIL: %s" % message)
	get_tree().quit(1)
