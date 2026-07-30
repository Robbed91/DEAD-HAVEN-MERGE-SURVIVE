# Dead Haven: Merge & Survive

**Build shelter. Find survivors. Outlast the dead.**

An original zombie-survival merge-puzzle game for Android, built in Godot
4. Dead Haven combines a merge-board puzzle system with a story-driven
survival campaign: restore and fortify a network of safe residences,
scavenge for supplies, recruit survivors, repair a vehicle, and defend what
you've built against The Hollow.

This is an original intellectual property. It takes broad, unavoidable
genre inspiration from polished story-based merge games and zombie
survival drama in general, but no characters, dialogue, locations,
interface layouts, storylines, logos, sound effects or art assets are
copied from Merge Mansion, The Walking Dead, or any other existing
property. The world (the Haven Line, Mara Vale, the Ashborn, the Signal
Keeper, The Hollow), every character, and the visual identity described
below were created for this project.

## Setting

Several years after a sudden outbreak, survivor Mara Vale is searching for
her missing brother Eli when she finds a damaged field radio repeating a
message: *"Haven Seven is still active. Follow the marked roads. Trust no
open gate."* She sets out along the Haven Line - a network of shelters
secretly prepared before the collapse, most now abandoned, damaged, or
deliberately sabotaged - piecing together what happened to it, to Eli, and
to the people who built it.

## Visual identity

Deep charcoal, faded olive green, rust orange, dusty cream, warning red,
weathered wood and aged metal, lit with warm safe-house interiors against
cool blue-grey exteriors. See `scripts/ui/theme_factory.gd` for the exact
palette values and `ART_ASSET_GUIDE.md` for how it's applied to
environments and characters.

## Current status: Phase 5 - Scavenging

Phases 1-4 (foundation, merge board, residence system, story) are done,
and now the World Map has 5 real scavenging locations: send a survivor,
face a choice-based encounter, and come back with real loot. **It is not
yet the full game** - a real survivor roster with skills, vehicles, and
defence events are scoped for the phases that follow (see
`DEVELOPMENT_LOG.md` for the authoritative phase-by-phase plan and status).

What already works, end to end, in this build:
- Everything from Phase 1 (main menu, save/load, settings, navigation, dev diagnostics), Phase 2 (the full 7x9 merge board, 101 items across 9 gameplay + 4 reward chains, producers, energy, storage), Phase 3 (9 real repair hotspots on Hollow Creek Farmhouse, task panels, "Find on Board" task highlighting) and Phase 4 (a real dialogue engine, an intro scene, and Noah Vance's rescue scene with a genuine choice)
- 5 scavenging locations on the World Map (Abandoned Grocery Store, Petrol Station, Farm Shed, Roadside Wreck, Medical Clinic) - pick a survivor, spend energy to send them, choose how to handle the encounter, and get real merge-board loot back
- Failure at a scavenging encounter costs a little (coins or energy) but never blocks progress or removes anything you already have
- Chapter tracking ("Chapter 1: The Open Door" -> "Chapter 2: Someone Upstairs" once the front door is secured), shown on Haven's header
- Energy regenerates over time (including while the app is closed) and can be spent by producers or scavenging missions; a debug infinite-energy mode exists for testing
- First-time item discovery grants a coin/energy reward exactly once per item, with a discovery banner

### Honest limitation

This container has no display server and no Android SDK/export templates,
so the assistant could not open the graphical editor or export a real
APK. It did download a Godot 4.3.stable Linux binary and run the project
headlessly, which confirmed: the project imports with no script/parse
errors; every screen instantiates without a runtime error; new game /
save / reload / corrupted-save-falls-back-to-backup all behave as
designed; settings changes actually reach the audio bus and rebuilt
theme; merging, producers, energy, storage, delete/undo and reward
collection (Phase 2) all behave as designed against the real data; task
requirement checks, item consumption, reward delivery, hotspot state
changes and the Noah unlock (Phase 3) all behave as designed; dialogue
chain/branch resolution, choice rewards and story flags, and chapter
advancement (Phase 4) all behave as designed; and (new in Phase 5)
scavenging's energy cost, forced success/failure encounter resolution,
loot delivery and non-blocking-failure guarantee all behave as designed
too (see `tests/README.md` for the smoke tests this was checked with). It has
**not** been visually confirmed on a real screen - touch input, drag
gesture feel, layout at actual device resolutions, and animation timing
still need a real run in the editor or on a device. Please report anything
that doesn't look/feel right.

## Technology

Godot 4.3+, GDScript, portrait orientation, `gl_compatibility` renderer
(chosen for mid-range Android performance over Forward+). No account,
network service, or third-party SDK is required to play.

## Project structure

```
autoload/         Global singletons: EventBus, ItemDatabase, GameManager, BoardState, ResidenceManager, DialogueManager, ScavengingManager, SaveManager, AudioManager, SceneRouter
data/              Content: data/items/ (101 ItemDefinition .tres), data/chains/, data/residences/ + data/quests/ (Hollow Creek Farmhouse), data/dialogue/ (intro + Noah rescue), data/scavenging/ (5 locations) - see data/README.md
scenes/            One folder per screen; scenes/ui/ holds shared components (top bar, bottom nav, toast, storage panel, item info panel, discovery banner, task panel); scenes/dialogue/ and scenes/scavenging/ are the Phase 4/5 screens
scripts/
  data_models/     Strongly-typed Resource classes (ItemDefinition, ResidenceDefinition, SurvivorDefinition, ScavengingMission, ...)
  ui/              Theme factory and other UI-only helpers
  merge/           Merge board runtime: item icon renderer, item view, board cell, chain legend icon
  residence/       Hotspot visual (Phase 3)
  characters/ vehicles/   Reserved for Phase 6+ gameplay logic
assets/            Art/audio; assets/manifests/asset_manifest.json tracks placeholder vs. final status
shaders/           Reserved for later visual-effects work
tests/             Headless smoke tests + manual test checklists; see tests/README.md
```

## Running it

1. Install [Godot 4.3 or later](https://godotengine.org/download) (the standard, non-.NET build - this project uses GDScript only).
2. Open Godot, choose **Import**, and select this repository's `project.godot`.
3. Press **F5** (or the Play button) to run. It boots to the main menu.

## Exporting an Android APK

1. In Godot, go to **Editor > Manage Export Templates** and install the templates matching your Godot version.
2. Install the Android SDK and set its path under **Editor > Editor Settings > Export > Android**. Godot's own [Android export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html) covers this in detail (JDK, SDK command-line tools, Gradle build).
3. Generate/point to a debug keystore under the same settings page (Godot can generate one for you).
4. This repo already includes `export_presets.cfg` (package `com.deadhaven.mergeandsurvive`, portrait, min SDK 28 / target SDK 34, no network permissions). Open **Project > Export** to review it, then click **Export Project** to produce an APK.
5. `export_presets.cfg` was written by hand to match Godot 4's format since no editor was available to generate it here - if Godot reports it as invalid when you first open the Export dialog, delete it and let the editor regenerate a fresh Android preset with the same package name/settings described above.

## Debug tools

A hidden developer menu (add/set energy, coins, level, reset save, live
FPS and state display) is reachable only when `OS.is_debug_build()` is
true, via 5 taps on the main menu title. It is never present in a release
export. Functions for systems not yet built (items, residences, vehicles,
survivors, defence, scavenging) appear disabled with a tooltip naming the
phase that implements them, rather than pretending to work.

## Licensing

Original code and design. No third-party copyrighted assets are included.
See `AUDIO_ASSET_GUIDE.md` and `ART_ASSET_GUIDE.md` for the status of every
placeholder and what a licence-safe replacement needs to look like.

## Documentation

- `DEVELOPMENT_LOG.md` - phase-by-phase build log (files touched, features completed, known issues, next phase)
- `ART_ASSET_GUIDE.md` / `AUDIO_ASSET_GUIDE.md` - asset status and requirements
- `data/README.md` - what content lives in each data folder and when it's populated
- `tests/PHASE1_MANUAL_CHECKLIST.md` - manual verification steps (no test-runner engine available in this environment)
