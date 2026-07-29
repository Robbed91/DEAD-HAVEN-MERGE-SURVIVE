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

## Current status: Phase 1 - Foundation

This build contains the project foundation only: navigation, save/load,
settings, the UI theme, and placeholder screens for every major system.
**It is not yet a playable merge-puzzle game** - the merge board, residence
repair logic, story, scavenging, survivors-as-characters, vehicles and
defence events are scoped for the phases that follow (see
`DEVELOPMENT_LOG.md` for the authoritative phase-by-phase plan and status).

What already works, end to end, in this build:
- Main menu with New Game / Continue / Settings / Quit
- New Game vs. Continue correctly detect and load/overwrite a save
- Local JSON save/load with a backup copy and safe handling of a corrupted save
- Autosave on resource changes, app pause and app close
- Bottom navigation between Haven / Merge / World Map / Survivors (Inventory is a stub)
- A top resource bar showing level, XP, energy, coins and Haven Tokens, live-updating via signals
- A fully wired Settings screen (audio volumes, vibration, reduced motion, high contrast, colour-blind mode, subtitles, text scale, reset progress)
- A hidden developer diagnostics menu (debug builds only, reached by tapping the main menu title 5 times)

### Honest limitation

This container has no display server and no Android SDK/export templates,
so the assistant could not open the graphical editor or export a real
APK. It did download a Godot 4.3.stable Linux binary and run the project
headlessly, which confirmed: the project imports with no script/parse
errors; every Phase 1 screen instantiates without a runtime error; new
game / save / reload / corrupted-save-falls-back-to-backup all behave as
designed; and settings changes actually reach the audio bus and rebuilt
theme (see `tests/README.md` for the three smoke tests this was checked
with). It has **not** been visually confirmed on a real screen - touch
input, layout at actual device resolutions, and animation timing still
need a real run in the editor or on a device. Please report anything that
doesn't look/feel right.

## Technology

Godot 4.3+, GDScript, portrait orientation, `gl_compatibility` renderer
(chosen for mid-range Android performance over Forward+). No account,
network service, or third-party SDK is required to play.

## Project structure

```
autoload/         Global singletons: EventBus, GameManager, SaveManager, AudioManager, SceneRouter
data/              Content (item/quest/residence/etc. data) - see data/README.md
scenes/            One folder per screen; scenes/ui/ holds shared components (top bar, bottom nav, toast)
scripts/
  data_models/     Strongly-typed Resource classes (ItemDefinition, ResidenceDefinition, SurvivorDefinition, ...)
  ui/              Theme factory and other UI-only helpers
  merge/ residence/ quests/ characters/ vehicles/   Reserved for Phase 2+ gameplay logic
assets/            Art/audio; assets/manifests/asset_manifest.json tracks placeholder vs. final status
shaders/           Reserved for later visual-effects work
tests/             Manual test checklists (see tests/PHASE1_MANUAL_CHECKLIST.md); no engine available here to run automated tests
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
