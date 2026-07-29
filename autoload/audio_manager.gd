extends Node
## AudioManager
##
## Owns the Music/SFX audio buses and plays named cues. No audio assets ship
## yet (see AUDIO_ASSET_GUIDE.md) - playing an unsourced cue logs a clear
## warning and does nothing, it never crashes or fails silently.

var music_bus_idx: int
var sfx_bus_idx: int

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 6

## Maps a cue key to a stream resource path. Populated as real assets land;
## see AUDIO_ASSET_GUIDE.md for the full planned catalogue and status.
var music_tracks: Dictionary = {}
var sfx_cues: Dictionary = {}

var _current_music_key: String = ""

func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	music_bus_idx = AudioServer.get_bus_index("Music")
	sfx_bus_idx = AudioServer.get_bus_index("SFX")

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.name = "MusicPlayer"
	add_child(_music_player)

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		p.name = "SfxPlayer%d" % i
		add_child(p)
		_sfx_players.append(p)

	apply_volume_settings()

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
	var stream: AudioStream = music_tracks[key]
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

func play_sfx(key: String) -> void:
	if not sfx_cues.has(key):
		push_warning("AudioManager: sfx cue '%s' not sourced yet (see AUDIO_ASSET_GUIDE.md)" % key)
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = sfx_cues[key]
			p.play()
			return
	# Pool exhausted - steal the first voice rather than dropping the cue.
	_sfx_players[0].stream = sfx_cues[key]
	_sfx_players[0].play()
