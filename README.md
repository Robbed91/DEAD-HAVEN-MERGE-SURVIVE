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

## Current status: integrated visual-production vertical slice and audio

The complete functional campaign remains intact across all five residences,
101 merge items, survivor/vehicle systems, defence events, scavenging and the
Signal Keeper story capstone. The visual-production branch now includes the
final Hollow Creek presentation, final merge-board and UI skins, illustrated
runtime merge icons, the implemented survivor/Drifter character set, reusable
animation/VFX systems, and a complete original audio catalog routed through
seven buses. Mara's neutral, concerned and injured portraits are registered
directly in character data; the presenter retains a deliberate procedural
fallback only for a missing or invalid portrait. The playable board continues
to be generated deterministically as an exact 7-column by 9-row grid.

The authoritative production documents are under `docs/`, including the art
bible, visual audit, replacement plan, final-asset/animation/audio manifests,
vertical-slice notes and captured verification evidence.

What already works, end to end, in this build:
- Everything from Phase 1 (main menu, save/load, settings, navigation, dev diagnostics), Phase 2 (the full 7x9 merge board, 101 items across 9 gameplay + 4 reward chains, producers, energy, storage), Phase 3 (9 real repair hotspots on Hollow Creek Farmhouse, task panels, "Find on Board" task highlighting), Phase 4 (a real dialogue engine, an intro scene, and Noah Vance's rescue scene with a genuine choice), Phase 5 (5 real scavenging locations with choice-based encounters and real loot), Phase 6 (a real survivor roster, Noah's personal quest, a 9-stage upgradeable delivery van, skill-based scavenging odds) and Phase 7 (Hollow Creek Farmhouse's tenth milestone: survive the first night attack)
- A second residence, Redwater Service Station, reachable from the World Map once you've survived Hollow Creek's first night: 8 more real repair hotspots (fuel pumps, service bay, convenience store, cashier's office, generator room, perimeter fence, drainage tunnel, garage workshop), a second rescue (mechanic Lena Ortiz, barricaded in the garage workshop) with her own dialogue scene, and its own "Defend the Station" attack event once every hotspot there is repaired
- A third residence, Greybridge School, reachable once you've survived Redwater's own attack: 8 more repair hotspots (main hall, gymnasium, library, cafeteria, boiler room, admin office, playground fence, radio tower), a third rescue (radio technician Riley Chen, found behind a wedged-shut stairwell to the roof) with her own dialogue scene, and its own "Defend the School" attack event whose skill requirements specifically match Riley's own skills - so unlike every prior defence event's skill bonus, this one is live immediately rather than waiting on a future survivor who happens to match
- A fourth residence, Saint Mercy Hospital, reachable once you've survived Greybridge's own attack: 8 more repair hotspots (ER reception, pharmacy, patient ward, surgical suite, power room, ambulance bay, records office, isolation ward), a fourth rescue (Dr Imogen Shaw, found behind the isolation ward's self-sealed doors) with her own dialogue scene, and its own "Defend the Hospital" attack event that deliberately keeps the standard skill requirements rather than matching Imogen's own medical skills - a doctor's triage skill doesn't make her better at holding a barricade
- A fifth and final residence (for the current roster), Northgate Prison, reachable once you've survived Saint Mercy's own attack: 8 more repair hotspots (sally port, guard tower, armory, mess hall, cell block A, control room, transport bay, warden's office), a fifth rescue (Caleb Rusk, found bunkered in the warden's office, openly hostile at first) with his own dialogue scene - and its own "Defend the Prison" attack event's skill requirements are the same standard set Hollow Creek/Redwater/Saint Mercy already use, which means recruiting Caleb (whose real skills are trap/defence/combat) makes all four of those events' skill bonuses live at once, not just this one
- All 10 of the original design spec's scavenging locations, not just the first 5 - the 5 new ones (Police Checkpoint, Electronics Workshop, Clothing Outlet, Warehouse Depot, Radio Relay Station) cover chains the first 5 didn't (trap, electronics, clothing); the Radio Relay Station is the first location gated behind story progress rather than always available
- A main-story capstone ("The Signal Keeper") that triggers once you've survived every residence's defence event, not just the one you just finished: an unprompted radio transmission that pays off the game's very first line of dialogue, gives Mara's search for her missing brother a real (unresolved) lead, and ties Caleb Rusk's seeded hint about the Ashborn faction to something larger - a genuine connecting thread across the whole roster instead of each residence only knowing about unlocking its immediate neighbour
- Chapter tracking ("Chapter 1: The Open Door" -> "Chapter 2: Someone Upstairs" -> "Chapter 4: The First Wave" -> "Chapter 5: The Station" -> "Chapter 6: The Signal" -> "Chapter 7: Do No Harm" -> "Chapter 8: Old Debts" -> "Chapter 9: The Signal Keeper"), shown on all five residence screens' headers
- A real survivor roster: unlocked cards (Mara always, Noah/Lena/Riley/Imogen/Caleb once rescued) show real biography/role/skills; Noah has a personal quest ("Noah's Workbench") completable from his card
- A 9-stage upgradeable delivery van, discovered once all 9 Hollow Creek Farmhouse hotspots are repaired, with a visibly-evolving silhouette and real per-stage item requirements
- Sending a survivor whose skills match a scavenging or defence encounter's needs (e.g. Noah's carpentry skills on the Farm Shed mission) genuinely improves the odds
- Failure at a scavenging or defence encounter costs a little (coins or energy, or one already-repaired hotspot needing re-repair) but never blocks progress or removes anything you already have
- Energy regenerates over time (including while the app is closed) and can be spent by producers, scavenging missions, or either residence's defence event; a debug infinite-energy mode exists for testing
- First-time item discovery grants a coin/energy reward exactly once per item, with a discovery banner

### Honest limitation

The runtime visual and audio layers are integrated and headless-tested, but a
final physical-device pass is still required for representative low/mid-range
Android GPU profiling, touch ergonomics, speaker/headphone balance and OEM
gesture-safe-area behaviour. Historical flattened concepts remain in
`assets/concepts/` as direction references; gameplay screens use runtime
assets and controls rather than those compositions as static replacements.

Godot 4.3 headless validation currently covers 20 smoke scenes. They exercise
screen startup, save recovery, settings, all merge mechanics and final item
icons, residence/task progression, dialogue, scavenging, vehicles/survivors,
all defence events, the Signal Keeper story, UI skin states, animation/VFX,
the full audio catalog, data-driven Mara portraits and the exact 7×9 runtime
grid. See `tests/README.md` for the assertion-level inventory. Desktop captures
are retained under `docs/*-captures/`; final physical Android touch,
performance, safe-area and audio-balance checks remain the outstanding QA.

## Technology

Godot 4.3+, GDScript, portrait orientation, `gl_compatibility` renderer
(chosen for mid-range Android performance over Forward+). No account,
network service, or third-party SDK is required to play.

## Project structure

```
autoload/         Global singletons: EventBus, ItemDatabase, GameManager, BoardState, CharacterDatabase, ResidenceManager, DialogueManager, ScavengingManager, VehicleManager, DefenceManager, SaveManager, AudioManager, SceneRouter
data/              Content: data/items/ (101 ItemDefinition .tres), data/chains/, data/residences/ (Hollow Creek Farmhouse + Redwater Service Station + Greybridge School + Saint Mercy Hospital + Northgate Prison - the full current roster) + data/quests/ (42 quests: 9 Hollow Creek + 8 each for Redwater/Greybridge/Saint Mercy/Northgate repair/rescue quests, plus Noah's personal quest), data/dialogue/ (intro, Noah/Lena/Riley/Imogen/Caleb rescues, the 5-entry Signal Keeper capstone), data/scavenging/ (10 locations - the complete original spec), data/characters/ (6 survivors, all with an unlock path now), data/vehicles/ (delivery van) - see data/README.md. All five defence events' choice data are a deliberate exception, kept inline in autoload/defence_manager.gd rather than data/ - see DEVELOPMENT_LOG.md Phase 7/8/10/11/12.
scenes/            One folder per screen; scenes/ui/ holds shared components (top bar, bottom nav, toast, storage panel, item info panel, discovery banner, task panel); scenes/splash/, scenes/dialogue/, scenes/scavenging/, scenes/vehicle/, scenes/defence/, scenes/redwater/, scenes/greybridge/, scenes/saint_mercy/ and scenes/northgate/ are the Phase 4-12 screens
scripts/
  data_models/     Strongly-typed Resource classes (ItemDefinition, ResidenceDefinition, SurvivorDefinition, ScavengingMission, VehicleDefinition, ...)
  ui/              Theme factory and other UI-only helpers
  merge/           Merge board runtime: item icon renderer, item view, board cell, chain legend icon
  residence/       Hotspot visual (Phase 3)
  vehicle/         Vehicle visual (Phase 6)
  characters/       Reserved for Phase 9+ gameplay logic
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
- `ART_STYLE_GUIDE.md` - formal colour palette, typography and logo system
- `ART_GENERATION_PROMPTS.md` - production prompts used for the first nine approved concepts, plus the still-open exact-grid merge-board brief
- `ART_ILLUSTRATION_CHECKLIST.md` - flat, hand-off-ready checklist of every illustration the game needs, kept current as later phases add content
- `data/README.md` - what content lives in each data folder and when it's populated
- `tests/PHASE1_MANUAL_CHECKLIST.md` - manual verification steps (no test-runner engine available in this environment)
