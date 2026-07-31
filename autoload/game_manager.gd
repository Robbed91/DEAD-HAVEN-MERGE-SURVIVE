extends Node
## GameManager
##
## Single source of truth for player profile, resources and settings.
## Other systems read/write state through this autoload instead of holding
## their own copies, and call SaveManager when state needs to persist.

const MAX_ENERGY_DEFAULT := 100
const XP_CURVE_BASE := 100 # xp needed for level 2; scales per level, see xp_needed_for_level()
const ENERGY_REGEN_INTERVAL_SECONDS := 180.0 # 1 energy per 3 minutes; rebalance freely
const ENERGY_REGEN_AMOUNT := 1

var _energy_regen_timer: Timer
## Debug-only, never persisted: while true, spend_energy() always succeeds
## without deducting. Toggled from the dev diagnostics screen.
var debug_infinite_energy: bool = false

var profile: Dictionary = {
	"survivor_name": "Mara Vale",
	"level": 1,
	"xp": 0,
	"current_residence_id": "hollow_creek_farmhouse",
	"tutorial_step": 0,
	"tutorial_complete": false,
	"unlocked_survivor_ids": [],
	"current_chapter_id": "chapter_1_the_open_door",
	"story_flags": {},
}

var resources: Dictionary = {
	"energy": MAX_ENERGY_DEFAULT,
	"energy_max": MAX_ENERGY_DEFAULT,
	"coins": 250,
	"haven_tokens": 10,
	"food": 0,
	"medicine": 0,
	"fuel": 0,
	"morale": 70,
}

var settings: Dictionary = {
	"master_volume": 0.8,
	"music_volume": 0.8,
	"ambience_volume": 0.75,
	"sfx_volume": 0.9,
	"ui_volume": 0.9,
	"characters_volume": 0.85,
	"threats_volume": 0.9,
	"vibration": true,
	"reduced_motion": false,
	"high_contrast": false,
	"colorblind_mode": false,
	"subtitles": true,
	"text_scale": 1.0,
	"graphics_quality": "standard", # "low" | "standard" | "high" - see ART_STYLE_GUIDE.md / brief section 38
}

## True once a game has been started/loaded this session. Prevents screens
## from reading profile/resources before they exist.
var is_game_active: bool = false

func is_debug_enabled() -> bool:
	return OS.is_debug_build()

## Single source of truth for whether non-essential motion/particle effects
## (merge bursts, hotspot repair dust, map marker pulses, ...) should play -
## folds together the accessibility "reduced motion" toggle and the
## performance "graphics_quality" tier (brief section 38's Low/Standard/
## High modes) so effect call sites don't each duplicate this check.
func effects_enabled() -> bool:
	return not settings.get("reduced_motion", false) and settings.get("graphics_quality", "standard") != "low"

func _ready() -> void:
	_energy_regen_timer = Timer.new()
	_energy_regen_timer.wait_time = ENERGY_REGEN_INTERVAL_SECONDS
	_energy_regen_timer.one_shot = false
	_energy_regen_timer.timeout.connect(_on_energy_regen_tick)
	add_child(_energy_regen_timer)
	_energy_regen_timer.start()

func _on_energy_regen_tick() -> void:
	resources.last_energy_tick_unix = Time.get_unix_time_from_system()
	if resources.energy < resources.energy_max:
		add_energy(ENERGY_REGEN_AMOUNT)

## Grants energy accrued while the app was closed, based on how much time
## passed since the save was last written. Capped at one full refill's
## worth of ticks so an absurd clock jump can't be exploited.
func _apply_offline_energy_regen() -> void:
	var last_tick: float = resources.get("last_energy_tick_unix", 0.0)
	if last_tick <= 0.0:
		resources.last_energy_tick_unix = Time.get_unix_time_from_system()
		return
	var elapsed: float = Time.get_unix_time_from_system() - last_tick
	if elapsed <= 0.0:
		resources.last_energy_tick_unix = Time.get_unix_time_from_system()
		return
	var ticks := int(elapsed / ENERGY_REGEN_INTERVAL_SECONDS)
	var max_useful_ticks: int = resources.energy_max # more ticks than this can't matter, energy is already clamped
	ticks = mini(ticks, max_useful_ticks)
	if ticks > 0:
		resources.energy = clampi(resources.energy + ticks * ENERGY_REGEN_AMOUNT, 0, resources.energy_max)
	resources.last_energy_tick_unix = Time.get_unix_time_from_system()

# -- Lifecycle -------------------------------------------------------------

func new_game() -> void:
	profile = {
		"survivor_name": "Mara Vale",
		"level": 1,
		"xp": 0,
		"current_residence_id": "hollow_creek_farmhouse",
		"tutorial_step": 0,
		"tutorial_complete": false,
		"unlocked_survivor_ids": [],
		"current_chapter_id": "chapter_1_the_open_door",
		"story_flags": {},
	}
	resources = {
		"energy": MAX_ENERGY_DEFAULT,
		"energy_max": MAX_ENERGY_DEFAULT,
		"coins": 250,
		"haven_tokens": 10,
		"food": 0,
		"medicine": 0,
		"fuel": 0,
		"morale": 70,
		"last_energy_tick_unix": Time.get_unix_time_from_system(),
	}
	is_game_active = true
	BoardState.reset_new_board()
	ResidenceManager.reset_new_game()
	ScavengingManager.apply_save_data({})
	VehicleManager.reset_new_game()
	DefenceManager.reset_new_game()
	SaveManager.save_game()
	EventBus.game_loaded.emit()

func continue_game() -> bool:
	var loaded := SaveManager.load_game()
	if loaded.is_empty():
		return false
	apply_save_data(loaded)
	is_game_active = true
	EventBus.game_loaded.emit()
	return true

## Serializes all persistent state. SaveManager owns the file format;
## GameManager only owns what the fields mean.
func to_save_data() -> Dictionary:
	return {
		"profile": profile.duplicate(true),
		"resources": resources.duplicate(true),
		"settings": settings.duplicate(true),
		"board": BoardState.to_save_data(),
		"residence": ResidenceManager.to_save_data(),
		"scavenging": ScavengingManager.to_save_data(),
		"vehicle": VehicleManager.to_save_data(),
		"defence": DefenceManager.to_save_data(),
	}

func apply_save_data(data: Dictionary) -> void:
	if data.has("profile"):
		profile.merge(data["profile"], true)
	if data.has("resources"):
		resources.merge(data["resources"], true)
	if data.has("settings"):
		settings.merge(data["settings"], true)
	_apply_offline_energy_regen()
	BoardState.apply_save_data(data.get("board", {}))
	ResidenceManager.apply_save_data(data.get("residence", {}))
	ScavengingManager.apply_save_data(data.get("scavenging", {}))
	VehicleManager.apply_save_data(data.get("vehicle", {}))
	DefenceManager.apply_save_data(data.get("defence", {}))
	AudioManager.apply_volume_settings()

# -- Resources ---------------------------------------------------------------

func add_energy(amount: int) -> void:
	resources.energy = clampi(resources.energy + amount, 0, resources.energy_max)
	EventBus.energy_changed.emit(resources.energy, resources.energy_max)
	SaveManager.request_autosave()

## Returns true if there was enough energy to spend (always true in debug
## infinite-energy mode, and energy is not deducted in that case).
func spend_energy(amount: int) -> bool:
	if debug_infinite_energy:
		return true
	if resources.energy < amount:
		return false
	resources.energy -= amount
	EventBus.energy_changed.emit(resources.energy, resources.energy_max)
	SaveManager.request_autosave()
	return true

func add_coins(amount: int) -> void:
	resources.coins = maxi(0, resources.coins + amount)
	EventBus.coins_changed.emit(resources.coins)
	SaveManager.request_autosave()

func add_haven_tokens(amount: int) -> void:
	resources.haven_tokens = maxi(0, resources.haven_tokens + amount)
	EventBus.haven_tokens_changed.emit(resources.haven_tokens)
	SaveManager.request_autosave()

func add_food(amount: int) -> void:
	resources.food = maxi(0, resources.food + amount)
	EventBus.food_changed.emit(resources.food)

func add_medicine(amount: int) -> void:
	resources.medicine = maxi(0, resources.medicine + amount)
	EventBus.medicine_changed.emit(resources.medicine)

func add_fuel(amount: int) -> void:
	resources.fuel = maxi(0, resources.fuel + amount)
	EventBus.fuel_changed.emit(resources.fuel)

func add_morale(amount: int) -> void:
	resources.morale = clampi(resources.morale + amount, 0, 100)
	EventBus.morale_changed.emit(resources.morale)

## Idempotent - unlocking an already-unlocked survivor is a no-op.
func unlock_survivor(survivor_id: String) -> void:
	var unlocked: Array = profile.unlocked_survivor_ids
	if unlocked.has(survivor_id):
		return
	unlocked.append(survivor_id)
	EventBus.survivor_unlocked.emit(survivor_id)
	SaveManager.request_autosave()

func is_survivor_unlocked(survivor_id: String) -> bool:
	var unlocked: Array = profile.unlocked_survivor_ids
	return unlocked.has(survivor_id)

## Mara is always unlocked (she's the player character); everyone else
## comes from profile.unlocked_survivor_ids.
func get_unlocked_survivor_ids() -> Array[String]:
	var ids: Array[String] = ["mara_vale"]
	for id in profile.unlocked_survivor_ids:
		ids.append(String(id))
	return ids

# -- Story flags & chapters (Phase 4) ----------------------------------------

## Lightweight placeholder ahead of Phase 6's real trust/friendship/rivalry
## survivor-relationship system: dialogue choices write arbitrary flags
## here (e.g. "noah_trusted": true) so a choice has a real, persisted
## consequence now, without inventing a numeric relationship model that
## nothing else reads yet.
func set_story_flag(key: String, value: Variant) -> void:
	profile.story_flags[key] = value
	SaveManager.request_autosave()

func get_story_flag(key: String, default_value: Variant = false) -> Variant:
	return profile.story_flags.get(key, default_value)

## Idempotent for the current chapter - calling this again with the same id
## (e.g. multiple completion paths racing) is a no-op rather than
## re-emitting the signal.
func advance_chapter(chapter_id: String) -> void:
	if profile.current_chapter_id == chapter_id:
		return
	profile.current_chapter_id = chapter_id
	EventBus.chapter_changed.emit(chapter_id)
	SaveManager.request_autosave()

# -- Experience & levelling ---------------------------------------------------

func xp_needed_for_level(level: int) -> int:
	# Gentle early curve; re-balance freely, this is the only place it lives.
	return XP_CURVE_BASE * level

func add_xp(amount: int) -> void:
	profile.xp += amount
	var needed := xp_needed_for_level(profile.level)
	while profile.xp >= needed:
		profile.xp -= needed
		profile.level += 1
		EventBus.level_up.emit(profile.level)
		needed = xp_needed_for_level(profile.level)
	EventBus.xp_changed.emit(profile.xp, needed)
	SaveManager.request_autosave()

# -- Settings ------------------------------------------------------------

func update_setting(key: String, value: Variant) -> void:
	if not settings.has(key):
		push_warning("GameManager.update_setting: unknown setting key '%s'" % key)
		return
	settings[key] = value
	EventBus.settings_changed.emit()
	if key in ["master_volume", "music_volume", "ambience_volume", "sfx_volume", "ui_volume", "characters_volume", "threats_volume"]:
		AudioManager.apply_volume_settings()
	if key in ["text_scale", "high_contrast", "colorblind_mode"]:
		# Previously these baked into the Theme once at Boot and never
		# again - toggling High Contrast or Colour-blind Mode in Settings
		# had no visible effect until the app restarted. Rebuilding here
		# makes every accessibility setting take effect immediately.
		get_window().theme = ThemeFactory.build_theme(
			settings.text_scale, settings.high_contrast, settings.colorblind_mode
		)
	SaveManager.request_autosave()

func reset_progress() -> void:
	SaveManager.delete_save()
	new_game()

# -- Debug tools (dev diagnostics screen only, never in release builds) ------

func set_debug_infinite_energy(enabled: bool) -> void:
	debug_infinite_energy = enabled

func debug_instant_recharge() -> void:
	add_energy(resources.energy_max)

func debug_reset_all_cooldowns() -> void:
	BoardState.debug_reset_all_cooldowns()
