extends Node
## GameManager
##
## Single source of truth for player profile, resources and settings.
## Other systems read/write state through this autoload instead of holding
## their own copies, and call SaveManager when state needs to persist.

const MAX_ENERGY_DEFAULT := 100
const XP_CURVE_BASE := 100 # xp needed for level 2; scales per level, see xp_needed_for_level()

var profile: Dictionary = {
	"survivor_name": "Mara Vale",
	"level": 1,
	"xp": 0,
	"current_residence_id": "hollow_creek_farmhouse",
	"tutorial_step": 0,
	"tutorial_complete": false,
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
	"sfx_volume": 0.9,
	"vibration": true,
	"reduced_motion": false,
	"high_contrast": false,
	"colorblind_mode": false,
	"subtitles": true,
	"text_scale": 1.0,
}

## True once a game has been started/loaded this session. Prevents screens
## from reading profile/resources before they exist.
var is_game_active: bool = false

func is_debug_enabled() -> bool:
	return OS.is_debug_build()

# -- Lifecycle -------------------------------------------------------------

func new_game() -> void:
	profile = {
		"survivor_name": "Mara Vale",
		"level": 1,
		"xp": 0,
		"current_residence_id": "hollow_creek_farmhouse",
		"tutorial_step": 0,
		"tutorial_complete": false,
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
	}
	is_game_active = true
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
	}

func apply_save_data(data: Dictionary) -> void:
	if data.has("profile"):
		profile.merge(data["profile"], true)
	if data.has("resources"):
		resources.merge(data["resources"], true)
	if data.has("settings"):
		settings.merge(data["settings"], true)
	AudioManager.apply_volume_settings()

# -- Resources ---------------------------------------------------------------

func add_energy(amount: int) -> void:
	resources.energy = clampi(resources.energy + amount, 0, resources.energy_max)
	EventBus.energy_changed.emit(resources.energy, resources.energy_max)
	SaveManager.request_autosave()

## Returns true if there was enough energy to spend.
func spend_energy(amount: int) -> bool:
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
	if key in ["master_volume", "music_volume", "sfx_volume"]:
		AudioManager.apply_volume_settings()
	SaveManager.request_autosave()

func reset_progress() -> void:
	SaveManager.delete_save()
	new_game()
