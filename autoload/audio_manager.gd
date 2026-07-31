extends Node
## AudioManager
##
## Owns the Music/SFX audio buses and plays named cues. No audio assets ship
## yet (see AUDIO_ASSET_GUIDE.md) - playing an unsourced cue logs a clear
## warning and does nothing, it never crashes or fails silently.

var music_bus_idx: int
var sfx_bus_idx: int

var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 6

## Maps a cue key to a stream resource path. Populated as real assets land;
## see AUDIO_ASSET_GUIDE.md for the full planned catalogue and status.
var music_tracks: Dictionary = {}
var sfx_cues: Dictionary = {}
var ambience_tracks: Dictionary = {}

var _current_music_key: String = ""
var _stream_cache: Dictionary = {}

func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	music_bus_idx = AudioServer.get_bus_index("Music")
	sfx_bus_idx = AudioServer.get_bus_index("SFX")

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.name = "MusicPlayer"
	add_child(_music_player)
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = "SFX"
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.volume_db = -8.0
	add_child(_ambience_player)

	_register_vertical_slice_audio()

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		p.name = "SfxPlayer%d" % i
		add_child(p)
		_sfx_players.append(p)

	apply_volume_settings()
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(func(): play_sfx("ui_tap"))

func _register_vertical_slice_audio() -> void:
	music_tracks = {
		"hollow_creek_residence": "res://assets/audio/music/hollow_creek_residence_loop.wav",
	}
	ambience_tracks = {
		"hollow_creek_storm": "res://assets/audio/ambience/hollow_creek_storm_loop.wav",
		"redwater_station": "res://assets/audio/ambience/redwater_station_loop.wav",
	}
	sfx_cues = {
		"ui_tap": "res://assets/audio/sfx/ui_tap.wav",
		"item_lift": "res://assets/audio/sfx/item_lift.wav",
		"merge_pull": "res://assets/audio/sfx/merge_pull_wood.wav",
		"merge": "res://assets/audio/sfx/merge_wood.wav",
		"merge_high": "res://assets/audio/sfx/merge_wood_high.wav",
		"merge_invalid": "res://assets/audio/sfx/merge_invalid.wav",
		"producer_activate": "res://assets/audio/sfx/producer_tools.wav",
		"producer_empty": "res://assets/audio/sfx/producer_empty.wav",
		"producer_recharge": "res://assets/audio/sfx/producer_recharge.wav",
		"discovery": "res://assets/audio/sfx/discovery.wav",
		"task_complete": "res://assets/audio/sfx/task_complete.wav",
		"window_hammer": "res://assets/audio/sfx/window_hammer.wav",
		"wood_creak": "res://assets/audio/sfx/wood_creak.wav",
		"dialogue_radio": "res://assets/audio/sfx/radio_crackle.wav",
		"lantern_ignite": "res://assets/audio/sfx/lantern_ignite.wav",
		"repair_whoosh": "res://assets/audio/sfx/repair_whoosh.wav",
		"redwater_repair": "res://assets/audio/sfx/redwater_repair_metal.wav",
	}

func _resolve_stream(value: Variant, looping: bool = false) -> AudioStream:
	if value is AudioStream:
		return value
	var path := String(value)
	if _stream_cache.has(path):
		return _stream_cache[path]
	var stream: AudioStream = load(path)
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if looping else AudioStreamWAV.LOOP_DISABLED
	_stream_cache[path] = stream
	return stream

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")

func apply_volume_settings() -> void:
	var settings: Dictionary = GameManager.settings
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(settings.get("master_volume", 0.8)))
	AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(settings.get("music_volume", 0.8)))
	AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(settings.get("sfx_volume", 0.9)))

func play_music(key: String, fade_seconds: float = 0.6) -> void:
	if key == _current_music_key:
		return
	if not music_tracks.has(key):
		push_warning("AudioManager: music cue '%s' not sourced yet (see AUDIO_ASSET_GUIDE.md)" % key)
		_current_music_key = key
		return
	_current_music_key = key
	var stream: AudioStream = _resolve_stream(music_tracks[key], true)
	if fade_seconds <= 0.0 or not _music_player.playing:
		_music_player.stream = stream
		_music_player.play()
		return
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -40.0, fade_seconds * 0.5)
	tween.tween_callback(func():
		_music_player.stream = stream
		_music_player.play()
	)
	tween.tween_property(_music_player, "volume_db", 0.0, fade_seconds * 0.5)

func stop_music() -> void:
	_current_music_key = ""
	_music_player.stop()

func play_ambience(key: String) -> void:
	if not ambience_tracks.has(key):
		return
	var stream := _resolve_stream(ambience_tracks[key], true)
	if _ambience_player.playing and _ambience_player.stream == stream:
		return
	_ambience_player.stream = stream
	_ambience_player.play()

func stop_ambience() -> void:
	_ambience_player.stop()

func play_sfx(key: String) -> void:
	if not sfx_cues.has(key):
		push_warning("AudioManager: sfx cue '%s' not sourced yet (see AUDIO_ASSET_GUIDE.md)" % key)
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = _resolve_stream(sfx_cues[key])
			p.play()
			return
	# Pool exhausted - steal the first voice rather than dropping the cue.
	_sfx_players[0].stream = _resolve_stream(sfx_cues[key])
	_sfx_players[0].play()
