# Dead Haven Audio Presentation

## Authorship and licence

Every final audio asset in `assets/audio/sfx`, `assets/audio/ambience`, and `assets/audio/music` is an original deterministic synthesis authored for Dead Haven. The complete source is `tools/build_complete_audio.py`. It uses only mathematical oscillators, amplitude envelopes, periodic synthesized texture, and seeded pseudo-random noise. No recordings, sample packs, copyrighted music, television audio, existing-game audio, vocals, or third-party model output are present.

The files are project-owned originals and may be used, modified, redistributed, and shipped with Dead Haven under the repository/project owner's chosen game licence. `AUDIO_PROVENANCE_MANIFEST.csv` records the origin, licence, bus, cue key, variant number, and loop status of every individual file.

## Bus architecture

| Bus | Purpose | Send |
|---|---|---|
| Master | Overall output | Device |
| Music | Score and musical stings | Master |
| Ambience | Looping environmental beds | Master |
| SFX | General objects, merge and vehicles | Master |
| UI | Interface, rewards and notifications | SFX |
| Characters | Survivor movement, tools and radio | SFX |
| Threats | Hollow and defence cues | SFX |

The settings screen exposes independent Master, Music, Ambience, SFX, UI, Characters, and Threats controls. Older saves remain valid because missing settings use documented defaults before being persisted normally.

## Runtime behavior

- Two music voices and two ambience voices provide smooth equal-duration crossfades.
- Dialogue ducks music by 7 dB and ambience by an additional 5 dB, then restores both smoothly.
- SFX cue definitions specify their bus, concurrency limit, variant list, and pitch-variation range.
- Repeated cues avoid immediately repeating the same variant.
- UI, SFX, Character, and Threat voice pools cap total simultaneous voices for Android.
- Application pause records active players and uses `stream_paused`; resume restores only those players.
- WAV resources are duplicated before applying loop flags so one-shot and looping uses cannot corrupt each other.
- Scene music/ambience is selected from existing `scene_changed` events. Rewards, discovery, levels, quests, missions, defence and vehicles listen to their existing EventBus signals.

## Music direction and tracks

The score uses restrained low drones, periodic pulses, warm harmonic partials, sparse danger percussion, and subtle radio texture. It contains no vocals. All frequencies and modulation cycles resolve exactly across their authored loop duration; the final endpoint also uses a short wrap blend to avoid clicks.

- `main_menu`: restrained title motif and radio texture.
- `safe_residence`: warmer fragile-haven bed.
- `merge_board`: low-fatigue workbench pulse.
- `world_map`: sparse exploratory motif.
- `scavenging`: cautious low pulse.
- `dialogue`: unobtrusive radio-tinted underscore.
- `tension`: low-string threat bed.
- `defence_preparation`: contained preparation pulse.
- `defence`: stronger low percussion and threat rhythm.
- `emotional`: warm restrained dramatic bed.
- `victory`: brief hopeful theme.
- `residence_completion`: warm completion theme.

## Integration coverage

Interface cues are bound to button, navigation, modal, confirmation/error, notification, reward, level, quest, and discovery events. Merge cues cover lift, drop, invalid, general and material-family merges, maximum-level rewards, producers, currency/energy collection, and chest-opening support. Residence cues cover hammer, saw, timber, metal, debris, doors, boarding, generators, traps, fences, footsteps, and tools. Character rigs emit survivor and Drifter cues from their existing visual states. Scavenging, defence, vehicle, dialogue, environment, reward, and residence screens connect only after existing state/result callbacks.

## Mobile format

Final runtime assets are mono 16-bit PCM WAV at 22.05 kHz. This is deliberately compact and avoids decoder startup cost for short mobile cues. Music and ambience are clean-loop authored sources; Android export may apply platform compression without changing cue IDs or integration. The library is approximately 24 MB before Godot import/export compression.
