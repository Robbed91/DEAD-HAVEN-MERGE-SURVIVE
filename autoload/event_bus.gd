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

# -- Merge board -----------------------------------------------------------
signal board_item_added(instance_id: String)
signal board_item_moved(instance_id: String)
signal board_item_removed(instance_id: String)
signal items_merged(dragged_instance_id: String, target_instance_id: String, resulting_instance_id: String)
signal item_discovered(item_id: String)
signal producer_activated(producer_instance_id: String, spawned_instance_id: String)

# -- Residence / quests (Phase 3) ------------------------------------------
signal hotspot_state_changed(hotspot_id: String, new_state: int)
signal quest_completed(quest_id: String)
signal survivor_unlocked(survivor_id: String)

# -- Story (Phase 4) --------------------------------------------------------
signal chapter_changed(chapter_id: String)
signal dialogue_finished(entry_id: String)

# -- Lightweight UI feedback ----------------------------------------------
## Used by any screen to surface a short non-blocking message, e.g. for
## systems that are not implemented yet in the current development phase.
signal show_toast(text: String)

# -- Save system -----------------------------------------------------------
signal game_saved()
signal game_loaded()
signal save_load_failed(reason: String)
