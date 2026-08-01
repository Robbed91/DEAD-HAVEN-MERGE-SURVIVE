# Batch 3 — Android export dependency audit

Date: 2026-08-01

Starting commit: `781c27c`

Branch: `visual-production`

## Outcome

This checkpoint replaces the broad Android package with two audited debug-signing presets and fixes packed-build catalog discovery. It preserves the package name, gameplay data, IDs, economy, and save schema.

- `Android`: version code 2, version `0.2.0`, arm64 only.
- `Android Verification`: version code 2, version `0.2.0`, arm64 and x86_64.
- Package: `com.deadhaven.mergeandsurvive`.
- Signing policy: Godot's persistent local debug keystore; no release key or credentials are tracked.
- Required dynamic JSON is explicitly included.
- Development-only folders, tests, tools, concepts, manifests, source masters, and duplicate Hollow Creek state renders are excluded.
- The live farmhouse dialogue background was promoted from `assets/concepts` to `assets/art/dialogue/runtime` before concepts were excluded.
- Packed `.tres.remap` directory entries are normalized to their runtime `.tres` resource names. Installed-build logging previously demonstrated all 101 items, 13 chains, 6 characters, 5 residences, 42 quests, 23 dialogue entries, 10 scavenging locations, and 1 vehicle loading.
- `window/handheld/orientation` is the Godot 4.3 integer enum value `1`; the generated Android manifest now contains `android:screenOrientation="portrait"`.

## Export evidence

The regenerated filtered Android tree contains 2,179 files and 163,664,357 bytes. Its generated manifest is portrait. Godot completed resource generation but its Gradle wrapper process did not return within the allotted window. Direct assembly from that exact generated tree produced:

- External APK: `S:\Rob B\Codex\B\Codex\godot-4.3\artifacts\batch3-export-audit\dead-haven-v2-debug-verification-portrait.apk`
- Size: 315,345,644 bytes.
- SHA-256: `ED06DF7387B7DC091D16CED5E60E2A980A0F517852674DF37E7EDBA212891CA1`.
- ABIs: `arm64-v8a`, `x86_64`.
- Signature: verified with the same debug certificate as the version-code-1 baseline.
- Certificate SHA-256: `1fba3d732cbc32351fb7e67e69044aeed0d27d1a84fc680fec79ffc7eb2b9f94`.

The earlier version-code-2 verification package was installed over the signed version-code-1 baseline without clearing data. The canonical `files/saves/slot1.json` SHA-256 remained `dccf7b2030d7b4113b2c0c108d60d6d79877d5f45f74506d868d2fffd5c33abf`; Continue, residence progress, merge-board contents, and stored inventory were visible afterward. Captures are in `docs/android-export-captures/`.

The newly rebuilt portrait APK above has signature/package inspection only. Its final emulator install was intentionally deferred when local Gradle packaging became slow, at the user's request to push the checkpoint for another packager.

## Tests

- Clean headless import from a newly created `.godot` cache: pass.
- `tests/android_export_resource_test.tscn`: pass, both presets and all catalog counts.
- Full smoke loop: 32 of 33 passed.
- `tests/smoke_test_audio_presentation.tscn`: passed on its first isolated rerun but remains timing-sensitive and failed inside the final rapid sequential loop because headless music/ambience playback had not entered the playing state.
- `tests/smoke_test_dialogue_presentation.tscn`: updated for the promoted runtime filename and passed.

This checkpoint is not represented as the plan's final verified 33/33 batch. The remaining gate is to install the portrait APK, repeat save persistence, and obtain a clean 33/33 run (or make the existing headless audio timing test deterministic).

## Next phase

Package/install the portrait verification APK, confirm portrait runtime and upgrade persistence, then build the arm64-only playtest artifact. After that, proceed to texture/audio/memory optimisation and the remaining visual batches.
