# Audio asset guide

`autoload/audio_manager.gd` plays cues by key through `music_tracks` and
`sfx_cues` dictionaries. No audio files ship yet - both dictionaries are
empty, and calling `play_music()`/`play_sfx()` with an unsourced key logs a
clear `push_warning` and does nothing (never a crash, never a silent
no-op with no explanation).

Only original or licence-safe (e.g. CC0, purchased-with-redistribution-
rights) audio may be added. Nothing from Merge Mansion, The Walking Dead or
any other existing property.

## Sound effects (planned)

| Key | Category | Status |
|---|---|---|
| `merge` | Merge board | not sourced |
| `item_pickup` | Merge board | not sourced |
| `producer_activate` | Merge board | not sourced |
| `construction_hammer` | Residence | not sourced |
| `task_complete` | Residence / quests | not sourced |
| `dialogue_advance` | Story | not sourced |
| `footsteps` | Residence / scavenging | not sourced |
| `hollow_ambience` | Atmosphere | not sourced |
| `wind` | Atmosphere | not sourced |
| `rain` | Atmosphere | not sourced |
| `generator_start` | Residence | not sourced |
| `vehicle_engine` | Vehicles | not sourced |
| `defence_warning` | Defence events | not sourced |
| `ui_button` | Interface | not sourced |
| `reward_reveal` | Interface | not sourced |
| `level_up` | Interface | not sourced |

## Music (planned)

| Key | Context | Status |
|---|---|---|
| `menu` | Main menu | not sourced |
| `haven_safe` | Residence, calm | not sourced |
| `merge_board` | Merge board | not sourced |
| `scavenging` | Scavenging missions | not sourced |
| `tension` | Approaching threat | not sourced |
| `defence` | Defence events | not sourced |
| `story_emotional` | Key dialogue beats | not sourced |
| `victory` | Milestone completion | not sourced |

## Adding a real cue

1. Drop the file under `assets/audio/sfx/` or `assets/audio/music/`.
2. Import it in the Godot editor (compressed Ogg Vorbis is the mobile-friendly default).
3. Register it in `AudioManager._ready()`: `sfx_cues["merge"] = preload("res://assets/audio/sfx/merge.ogg")`.
4. Update the "status" column above.

## Settings wired up in Phase 1

Master/Music/SFX volume sliders and a Vibration toggle live on the Settings
screen and persist through `GameManager.settings` / `SaveManager`. Reduced
motion is also tracked there for animation-heavy systems to check.
