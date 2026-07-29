# Tests

Godot has no built-in unit-test runner comparable to a typical xUnit
framework; these are small headless-runnable scenes instead. Each one
loads real game systems (autoloads, real `.tscn` screens) and prints a
`..._OK` / `..._FAIL` line, so they work in CI or a plain terminal with no
display server.

Run any of them with a Godot 4.3+ binary:

```bash
godot4 --headless --path . tests/smoke_test.tscn
godot4 --headless --path . tests/smoke_test_save.tscn
godot4 --headless --path . tests/smoke_test_settings.tscn
```

None of these are wired up as the project's `run/main_scene` - they're
opt-in, point Godot at them directly as shown above.

## What each one covers

- **smoke_test** - instantiates every Phase 1 screen (Haven, Merge Board, World Map, Survivors, Settings, Dev Diagnostics) in turn and fails loudly if any of them throws a script error on `_ready()`.
- **smoke_test_save** - new game -> mutate resources -> save -> reload -> asserts the values round-tripped; then corrupts the primary save file on disk and asserts `SaveManager` recovers from the `.bak` copy instead of crashing.
- **smoke_test_settings** - changes audio/accessibility settings through `GameManager.update_setting()` and asserts the audio bus volume and rebuilt `Theme`'s font size actually reflect them.

## What these do NOT cover

They run with Godot's headless server backend - no window, no real touch
input, no on-screen rendering. They catch script/logic errors, not visual
bugs, gesture timing, or layout issues on an actual device. Use
`PHASE1_MANUAL_CHECKLIST.md` for that, on a real Android device or in the
editor's running game view.

Results as of Phase 1 (Godot 4.3.stable, run in this development
container): all three pass.
