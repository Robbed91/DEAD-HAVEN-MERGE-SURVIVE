# Phase 1 manual test checklist

A Godot 4.3 binary was obtained and run headlessly against this project
during development (see `tests/README.md`) - project import, scene
instantiation, save/load/corruption-recovery and settings/audio/theme
logic have all been verified that way. What headless mode *cannot* verify
is real rendering, touch input and gesture timing on an actual screen, so
none of the checklist below has been visually confirmed. Please run
through it on a device or in the editor's game view and file anything that
fails.

## Boot & navigation
- [ ] Project opens in Godot 4.3+ without import errors
- [ ] Running the project (F5) boots straight to the main menu, no console errors
- [ ] "New Game" with no existing save starts immediately (no dialog)
- [ ] "Continue" is disabled/greyed out when no save exists
- [ ] Bottom nav (Haven / Merge / Map / Survivors / Inventory) switches screens with a visible fade
- [ ] Inventory shows a "coming later" toast instead of navigating
- [ ] Back button on Settings returns to where it was opened from

## Save/load
- [ ] Starting a new game, changing a setting, then closing and reopening the app preserves that setting
- [ ] "New Game" over an existing save shows the overwrite confirmation dialog; Cancel leaves the old save untouched
- [ ] Manually corrupting `user://saves/slot1.json` (e.g. truncate the file) and launching "Continue" falls back to the `.bak` copy instead of crashing
- [ ] "Reset Progress" in Settings asks for confirmation, then starts a clean game

## Settings
- [ ] Master/Music/SFX sliders move and persist across restarts
- [ ] Reduced Motion, when enabled, visibly shortens/removes the main menu glow pulse, world map marker pulse and toast fade
- [ ] High Contrast visibly swaps the theme palette
- [ ] Text Scale slider visibly changes font size across screens

## Developer diagnostics (debug build only)
- [ ] Tapping the main menu title 5 times within ~1.5s opens the developer menu
- [ ] It does NOT open after 5 taps spread out over a longer period (timer should reset)
- [ ] +Energy / Fill Energy / +Coins / +1 Level buttons update the top resource bar immediately
- [ ] FPS and state labels update live
- [ ] Buttons for unimplemented systems (items, residences, defence, scavenging, vehicles, survivors) are visibly disabled with a tooltip

## Known-good vs. known-missing (read this before filing a bug)
Missing merge gameplay, residence repair, story scenes, scavenging,
recruitable survivors, vehicle repair and defence events are **expected** -
see `DEVELOPMENT_LOG.md` for what Phase 1 intentionally does not include.
