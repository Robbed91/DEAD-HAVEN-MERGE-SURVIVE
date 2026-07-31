extends Node
## Verifies the final audio catalog, buses, routing and state neutrality.

var _failed := false

func _ready() -> void:
	GameManager.new_game()
	await get_tree().process_frame
	var resources_before := GameManager.resources.duplicate(true)
	var profile_before := GameManager.profile.duplicate(true)
	for bus_name in ["Master", "Music", "Ambience", "SFX", "UI", "Characters", "Threats"]:
		_assert(AudioServer.get_bus_index(bus_name) >= 0, "missing audio bus %s" % bus_name)
	_assert(AudioManager.sfx_cues.size() == 61, "expected 61 SFX cue families")
	_assert(AudioManager.music_tracks.size() == 12, "expected 12 music tracks")
	_assert(AudioManager.ambience_tracks.size() == 14, "expected 14 ambience loops")
	var asset_count := 0
	for key in AudioManager.sfx_cues:
		var entry: Dictionary = AudioManager.sfx_cues[key]
		_assert(entry.has("bus") and entry.has("limit") and entry.has("pitch_semitones"), "%s policy incomplete" % key)
		for path in entry.paths:
			asset_count += 1
			_assert(ResourceLoader.exists(path), "missing SFX %s" % path)
	for path in AudioManager.music_tracks.values():
		asset_count += 1
		_assert(ResourceLoader.exists(path), "missing music %s" % path)
	for path in AudioManager.ambience_tracks.values():
		asset_count += 1
		_assert(ResourceLoader.exists(path), "missing ambience %s" % path)
	_assert(asset_count == 250, "expected 250 catalogued final audio files")

	AudioManager.play_sfx("ui_button")
	for i in 8: AudioManager.play_sfx("ui_button")
	AudioManager.play_music("main_menu", 0.0)
	AudioManager.play_ambience("wind", 0.0)
	await get_tree().process_frame
	_assert(AudioManager._active_by_key.get("ui_button", []).size() <= 3, "per-cue concurrency limit not enforced")
	_assert(AudioManager._current_music_key == "main_menu", "music trigger did not resolve")
	_assert(AudioManager._current_ambience_key == "wind", "ambience trigger did not resolve")
	_assert(AudioManager._music_players[AudioManager._music_active].playing, "music stream was not triggered in running tree")
	_assert(AudioManager._ambience_players[AudioManager._ambience_active].playing, "ambience stream was not triggered in running tree")
	AudioManager._notification(NOTIFICATION_APPLICATION_PAUSED)
	_assert(AudioManager._music_players[AudioManager._music_active].stream_paused, "Android pause did not suspend music")
	AudioManager._notification(NOTIFICATION_APPLICATION_RESUMED)
	_assert(not AudioManager._music_players[AudioManager._music_active].stream_paused, "Android resume did not restore music")
	AudioManager.set_dialogue_active(true)
	_assert(AudioManager._dialogue_active, "dialogue ducking state missing")
	AudioManager.set_dialogue_active(false)

	for pair in [["ambience_volume", .42, "Ambience"], ["ui_volume", .37, "UI"], ["characters_volume", .51, "Characters"], ["threats_volume", .63, "Threats"]]:
		GameManager.update_setting(pair[0], pair[1])
		var linear := db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(pair[2])))
		_assert(absf(linear - pair[1]) < .01, "%s independent volume not applied" % pair[2])

	_assert(GameManager.resources == resources_before, "audio presentation mutated resources")
	_assert(GameManager.profile == profile_before, "audio presentation mutated profile")
	if _failed:
		push_error("SMOKE_AUDIO_PRESENTATION_FAIL")
		get_tree().quit(1)
	else:
		print("SMOKE_AUDIO_PRESENTATION_OK buses=7 cues=61 music=12 ambience=14 assets=250")
		get_tree().quit()

func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("SMOKE_AUDIO_PRESENTATION: %s" % message)
