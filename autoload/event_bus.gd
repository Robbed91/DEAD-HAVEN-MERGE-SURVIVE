extends Node
## EventBus
##
## Global signal hub so gameplay systems can stay decoupled from each other
## and from the UI. Add new signals here as new phases connect systems -
## do not have systems poll each other directly.

# -- Player state --------------------------------------------------------
signal energy_changed(current: int, maximum: int)
signal coins_changed(amount: int)
signal haven_tokens_changed(amount: int)
signal food_changed(amount: int)
signal medicine_changed(amount: int)
signal fuel_changed(amount: int)
signal morale_changed(amount: int)
signal xp_changed(current: int, needed: int)
signal level_up(new_level: int)

# -- Navigation & settings ------------------------------------------------
signal scene_changed(scene_key: String)
signal settings_changed()

# -- Lightweight UI feedback ----------------------------------------------
## Used by any screen to surface a short non-blocking message, e.g. for
## systems that are not implemented yet in the current development phase.
signal show_toast(text: String)

# -- Save system -----------------------------------------------------------
signal game_saved()
signal game_loaded()
signal save_load_failed(reason: String)
