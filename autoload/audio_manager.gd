extends Node
## Complete state-neutral audio presentation. Streams are selected from the
## generated original catalog; gameplay systems remain authoritative.

const CATALOG_PATH := "res://assets/audio/audio_catalog.json"
const BUS_NAMES := ["Master", "Music", "Ambience", "SFX", "UI", "Characters", "Threats"]
const POOL_SIZES := {"SFX": 8, "UI": 4, "Characters": 5, "Threats": 5}
const LEGACY_SFX := {
	"ui_tap": "ui_button", "item_lift": "item_pickup", "merge_pull": "merge_wood",
	"merge": "merge_generic", "discovery": "item_discovery", "task_complete": "quest_complete",
	"window_hammer": "window_board", "wood_creak": "wood_place", "dialogue_radio": "radio_pulse",
	"lantern_ignite": "confirmation", "repair_whoosh": "wood_place", "redwater_repair": "metal_fastening",
}
const LEGACY_MUSIC := {"hollow_creek_residence": "safe_residence"}
const SCENE_AUDIO := {
	"main_menu": ["main_menu", "wind"], "haven": ["safe_residence", "hollow_creek_storm"],
	"redwater": ["safe_residence", "redwater_station"], "greybridge": ["safe_residence", "wind"],
	"saint_mercy": ["safe_residence", "rain"], "northgate": ["tension", "distant_hollow"],
	"world_map": ["world_map", "road"],
	"scavenging": ["scavenging", "forest"], "dialogue": ["dialogue", "abandoned_building"],
	"defence": ["defence_preparation", "distant_hollow"], "vehicle": ["world_map", "road"],
}

var music_tracks: Dictionary = {}
var ambience_tracks: Dictionary = {}
var sfx_cues: Dictionary = {}
var _stream_cache: Dictionary = {}
var _pools: Dictionary = {}
var _active_by_key: Dictionary = {}
var _last_variant: Dictionary = {}
var _music_players: Array[AudioStreamPlayer] = []
var _ambience_players: Array[AudioStreamPlayer] = []
var _music_active := 0
var _ambience_active := 0
var _current_music_key := ""
var _current_ambience_key := ""
var _ambience_layers: Dictionary = {}
var _sting_player: AudioStreamPlayer
var _dialogue_active := false
var _suspended_players: Array[AudioStreamPlayer] = []
var _last_energy := -1
var _last_coins := -1

func _ready() -> void:
	for bus_name in BUS_NAMES: _ensure_bus(bus_name)
	_load_catalog()
	_build_players()
	apply_volume_settings()
	get_tree().node_added.connect(_on_node_added)
	EventBus.scene_changed.connect(_on_scene_changed)
	EventBus.settings_changed.connect(apply_volume_settings)
	EventBus.show_toast.connect(func(_text): play_sfx("notification"))
	EventBus.item_discovered.connect(func(_id): play_sfx("item_discovery"))
	EventBus.quest_completed.connect(func(_id): play_sfx("quest_complete"); play_music_sting("residence_completion"))
	EventBus.level_up.connect(func(_level): play_sfx("level_up"))
	EventBus.survivor_unlocked.connect(func(_id): play_sfx("reward"))
	EventBus.vehicle_discovered.connect(func(_id): play_sfx("reward"))
	EventBus.vehicle_stage_changed.connect(func(_id, _stage): play_sfx("vehicle_start"))
	EventBus.mission_completed.connect(_on_mission_completed)
	EventBus.defence_resolved.connect(_on_defence_resolved)
	EventBus.dialogue_finished.connect(func(_id): set_dialogue_active(false))
	EventBus.energy_changed.connect(_on_energy_changed)
	EventBus.coins_changed.connect(_on_coins_changed)
	_last_energy = int(GameManager.resources.get("energy", 0))
	_last_coins = int(GameManager.resources.get("coins", 0))
	call_deferred("_detect_initial_scene")

func _load_catalog() -> void:
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("AudioManager: missing original audio catalog")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("AudioManager: invalid audio catalog")
		return
	sfx_cues = parsed.get("sfx", {})
	music_tracks = parsed.get("music", {})
	ambience_tracks = parsed.get("ambience", {})

func _build_players() -> void:
	for i in 2:
		var music := _player("Music", "Music%d" % i)
		music.volume_db = -60.0
		_music_players.append(music)
		var ambience := _player("Ambience", "Ambience%d" % i)
		ambience.volume_db = -60.0
		_ambience_players.append(ambience)
	_sting_player = _player("Music", "MusicSting")
	for bus_name in POOL_SIZES:
		var pool: Array[AudioStreamPlayer] = []
		for i in int(POOL_SIZES[bus_name]): pool.append(_player(bus_name, "%sVoice%d" % [bus_name, i]))
		_pools[bus_name] = pool

func _player(bus_name: String, node_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = bus_name
	add_child(player)
	return player

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0: return
	var index := AudioServer.bus_count
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "SFX" if bus_name in ["UI", "Characters", "Threats"] and AudioServer.get_bus_index("SFX") >= 0 else "Master")

func apply_volume_settings() -> void:
	var s := GameManager.settings
	_set_bus("Master", float(s.get("master_volume", .8)))
	_set_bus("Music", float(s.get("music_volume", .8)))
	_set_bus("Ambience", float(s.get("ambience_volume", .75)))
	_set_bus("SFX", float(s.get("sfx_volume", .9)))
	_set_bus("UI", float(s.get("ui_volume", .9)))
	_set_bus("Characters", float(s.get("characters_volume", .85)))
	_set_bus("Threats", float(s.get("threats_volume", .9)))

func _set_bus(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0: AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, .0001)))

func _resolve_stream(path: String, looping: bool) -> AudioStream:
	var cache_key := "%s|%s" % [path, looping]
	if _stream_cache.has(cache_key): return _stream_cache[cache_key]
	var loaded: AudioStream = load(path)
	var stream: AudioStream = loaded.duplicate() if loaded != null else null
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if looping else AudioStreamWAV.LOOP_DISABLED
	_stream_cache[cache_key] = stream
	return stream

func play_sfx(raw_key: String, volume_db := 0.0) -> void:
	var key := String(LEGACY_SFX.get(raw_key, raw_key))
	if not sfx_cues.has(key):
		push_warning("AudioManager: unknown SFX cue '%s'" % raw_key)
		return
	var entry: Dictionary = sfx_cues[key]
	var active: Array = _active_by_key.get(key, [])
	active = active.filter(func(p): return is_instance_valid(p) and p.playing)
	var limit := int(entry.get("limit", 3))
	if active.size() >= limit: active[0].stop(); active.pop_front()
	var bus_name := String(entry.get("bus", "SFX"))
	var player := _free_voice(bus_name)
	if player == null: return
	var paths: Array = entry.get("paths", [])
	if paths.is_empty(): return
	var variant := randi_range(0, paths.size() - 1)
	if paths.size() > 1 and variant == int(_last_variant.get(key, -1)): variant = (variant + 1) % paths.size()
	_last_variant[key] = variant
	player.stream = _resolve_stream(String(paths[variant]), false)
	var semitones := float(entry.get("pitch_semitones", 0.0))
	player.pitch_scale = pow(2.0, randf_range(-semitones, semitones) / 12.0)
	player.volume_db = volume_db
	player.play()
	active.append(player)
	_active_by_key[key] = active

func _free_voice(bus_name: String) -> AudioStreamPlayer:
	var pool: Array = _pools.get(bus_name, _pools.get("SFX", []))
	for player in pool:
		if not player.playing: return player
	if pool.is_empty(): return null
	pool[0].stop()
	return pool[0]

func play_music(raw_key: String, fade_seconds := .8) -> void:
	var key := String(LEGACY_MUSIC.get(raw_key, raw_key))
	if key == _current_music_key or not music_tracks.has(key): return
	_current_music_key = key
	_music_active = 1 - _music_active
	_crossfade(_music_players[1 - _music_active], _music_players[_music_active], String(music_tracks[key]), fade_seconds, -7.0 if _dialogue_active else 0.0)

func stop_music(fade_seconds := .35) -> void:
	_current_music_key = ""
	_fade_stop(_music_players[_music_active], fade_seconds)

func play_ambience(key: String, fade_seconds := 1.2) -> void:
	if key == _current_ambience_key or not ambience_tracks.has(key): return
	_current_ambience_key = key
	_ambience_active = 1 - _ambience_active
	_crossfade(_ambience_players[1 - _ambience_active], _ambience_players[_ambience_active], String(ambience_tracks[key]), fade_seconds, -4.0 if _dialogue_active else -3.0)

func stop_ambience(fade_seconds := .5) -> void:
	_current_ambience_key = ""
	_fade_stop(_ambience_players[_ambience_active], fade_seconds)

func play_ambience_layer(key: String, volume_db := -12.0) -> void:
	if not ambience_tracks.has(key) or _ambience_layers.has(key): return
	var player := _player("Ambience", "Layer_%s" % key)
	player.stream = _resolve_stream(String(ambience_tracks[key]), true)
	player.volume_db = -60.0
	player.play()
	_ambience_layers[key] = player
	create_tween().tween_property(player, "volume_db", volume_db, .7)

func stop_ambience_layer(key: String, fade_seconds := .4) -> void:
	var player: AudioStreamPlayer = _ambience_layers.get(key)
	if player == null: return
	_ambience_layers.erase(key)
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -60.0, fade_seconds)
	tween.tween_callback(player.queue_free)

func stop_all_ambience_layers() -> void:
	for key in _ambience_layers.keys(): stop_ambience_layer(key)

func _crossfade(old: AudioStreamPlayer, fresh: AudioStreamPlayer, path: String, seconds: float, target_db: float) -> void:
	fresh.stream = _resolve_stream(path, true)
	fresh.volume_db = -60.0
	fresh.play()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(old, "volume_db", -60.0, seconds)
	tween.tween_property(fresh, "volume_db", target_db, seconds)
	tween.chain().tween_callback(old.stop)

func _fade_stop(player: AudioStreamPlayer, seconds: float) -> void:
	if not player.playing: return
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -60.0, seconds)
	tween.tween_callback(player.stop)

func play_music_sting(key: String) -> void:
	if not music_tracks.has(key): return
	_sting_player.stream = _resolve_stream(String(music_tracks[key]), false)
	_sting_player.volume_db = 0.0
	_sting_player.play()

func set_dialogue_active(active: bool) -> void:
	if _dialogue_active == active: return
	_dialogue_active = active
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_music_players[_music_active], "volume_db", -7.0 if active else 0.0, .35)
	tween.tween_property(_ambience_players[_ambience_active], "volume_db", -8.0 if active else -3.0, .35)

func _on_node_added(node: Node) -> void:
	if node is ConfirmationDialog:
		node.about_to_popup.connect(func(): play_sfx("modal_open"))
		node.confirmed.connect(func(): play_sfx("confirmation"))
		node.close_requested.connect(func(): play_sfx("modal_close"))
	if not node is BaseButton: return
	var button := node as BaseButton
	button.pressed.connect(func():
		var lower: String = String(button.name).to_lower() + " " + button.text.to_lower()
		if "back" in lower or "close" in lower: play_sfx("modal_close")
		elif button.name in ["HavenButton", "MapButton", "SurvivorsButton", "InventoryButton"]: play_sfx("ui_navigation")
		else: play_sfx("ui_button")
	)

func _detect_initial_scene() -> void:
	var scene := get_tree().current_scene
	if scene == null: return
	for key in SceneRouter.SCENE_PATHS:
		if String(SceneRouter.SCENE_PATHS[key]) == scene.scene_file_path:
			_on_scene_changed(key)
			return

func _on_scene_changed(key: String) -> void:
	if not SCENE_AUDIO.has(key): return
	stop_all_ambience_layers()
	var pair: Array = SCENE_AUDIO[key]
	play_music(String(pair[0]))
	play_ambience(String(pair[1]))
	set_dialogue_active(key == "dialogue")
	match key:
		"haven":
			play_ambience_layer("thunder", -17.0)
			play_ambience_layer("distant_hollow", -20.0)
			play_ambience_layer("lantern", -15.0)
		"redwater":
			play_ambience_layer("road", -16.0)
			if ResidenceManager.get_hotspot_state("generator_room") == ResidenceHotspot.State.COMPLETED: play_ambience_layer("generator", -13.0)
		"saint_mercy": play_ambience_layer("electrical_hum", -15.0)
		"world_map": play_ambience_layer("wind", -17.0)
		"vehicle": play_ambience_layer("vehicle_engine", -12.0)

func _on_mission_completed(_id: String, success: bool) -> void:
	play_sfx("scavenge_success" if success else "scavenge_failure")
	if success: play_music_sting("victory")

func _on_defence_resolved(success: bool) -> void:
	play_sfx("defence_success" if success else "defence_failure")
	play_music_sting("victory" if success else "tension")

func _on_energy_changed(value: int, _maximum: int) -> void:
	if _last_energy >= 0 and value > _last_energy: play_sfx("energy_collect")
	_last_energy = value

func _on_coins_changed(value: int) -> void:
	if _last_coins >= 0 and value > _last_coins: play_sfx("coin_collect")
	_last_coins = value

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_suspended_players.clear()
		for child in get_children():
			if child is AudioStreamPlayer and child.playing:
				child.stream_paused = true
				_suspended_players.append(child)
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		for player in _suspended_players:
			if is_instance_valid(player): player.stream_paused = false
		_suspended_players.clear()
