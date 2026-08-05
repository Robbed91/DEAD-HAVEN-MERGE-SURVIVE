# Android import optimisation and device verification

Date: 2026-08-04

Starting commit: `b138e83`

Branch: `visual-production`

## Objective

Apply the two fixes named by `docs/EXPORT_SIZE_AUDIT.md`, produce debug-signed
version-code-2 APKs, and execute the available Pixel 9 emulator size,
performance, upgrade, pause/resume, and persistence checks without changing
gameplay data or save keys.

## Import changes

- 46 background-only PNG/JPG imports use ETC2/VRAM compression. Scope is
  limited to the world map, residence state/background art, the five requested
  weather layers, scavenging backgrounds, and the dialogue approach
  background. Alpha-heavy gameplay items, producers, portraits, hotspots,
  navigation, and UI remain lossless.
- 26 WAV imports under `assets/audio/music/` and `assets/audio/ambience/` use
  IMA-ADPCM. The 224 short SFX imports remain unchanged.
- `project.godot` disables text-resource-to-binary conversion during export.
  Godot 4.3's converter reproducibly erased all 41 hotspot task-link arrays in
  the packed build; a clean pack with conversion disabled reports
  `hotspot_links=41 link_errors=0`.

## Artifacts and size

Artifacts are intentionally outside Git under
`S:/Rob B/Codex/B/Codex/godot-4.3/artifacts/batch-import-optimisation/`.

- `dead-haven-v2-optimized-debug-arm64-final.apk`
  - 205,710,503 bytes (196.18 MiB)
  - SHA-256 `45726F779BC8DC1F5625E6A9A65DB2E8D00514D7A680426DFC3606B5C9D4068D`
  - ABI: arm64-v8a
- `dead-haven-v2-optimized-debug-verification-final.apk`
  - 283,128,596 bytes
  - SHA-256 `544FF62A410CFADBC6D44305826230EFDD574B4191F5BD69B9E8DC65CEC75F2C`
  - ABIs: arm64-v8a, x86_64
- Both use version code 2, package `com.deadhaven.mergeandsurvive`, APK
  Signature Scheme v2, and the same normal Godot debug certificate as the
  preserved version-code-1 baseline. Certificate SHA-256:
  `1fba3d732cbc32351fb7e67e69044aeed0d27d1a84fc680fec79ffc7eb2b9f94`.

The universal APK is 32,217,048 bytes smaller than the pre-optimisation
315,345,644-byte verification APK. The final arm64 APK is below 200 MiB but is
5,710,503 bytes over a strict decimal 200 MB cap.

## Emulator verification

- Pixel 9 AVD, 1080x2424, Android API 37 x86_64 16 KB image.
- Corrected APK installed over the version-code-1 fixture without clearing
  app data. Installed package remained debug-signed, version code 2, version
  name 0.2.0, x86_64 runtime ABI.
- Cold start: 1,144 ms and 1,282 ms measured after warm-up.
- Hollow Creek active screen: 201,211 KB total PSS, 319,864 KB total RSS.
- SurfaceFlinger actual-present intervals, 62-frame steady-state sample:
  median 16.63 ms, p95 18.50 ms, max 20.61 ms.
- Main menu and the upgraded Hollow Creek residence/merge board rendered at
  the Pixel 9's full portrait resolution. ETC2 residence art showed no visible
  corruption at emulator scale. Full per-background A/B review and listening
  review of all ADPCM loops remain manual gates.
- Godot 4.3's native libraries fail Android 16 KB `zipalign -P 16` validation
  on this API 37 emulator image. Normal 4-byte APK alignment and v2 signature
  verification pass. Resolving 16 KB native-library alignment requires a newer
  Godot Android toolchain/template and is not silently treated as a 4.3 pass.

## Upgrade and lifecycle result

The representative v1 save loaded and migrated to v2. The following remained
intact through upgrade, pause/save, Home/return, and force-stop/relaunch:

- Hollow Creek front-door completion and chapter 2 progress.
- Legacy board contents, position, cobweb, charge/cooldown, and storage data.
- Noah survivor unlock.
- Haven Tokens and accessibility/audio settings.
- Five independently materialised residence boards after migration.

Energy rose from 83 to 100 through the existing offline-regeneration rule,
which is expected for the fixture timestamp. Coins unexpectedly rose from
1,250 to 1,450 when the four missing residence boards were materialised. The
cause is existing `BoardState._materialize_missing_boards()` setup calling
normal discovery-reward paths; this is a strict upgrade-persistence blocker
for the coding handover.

## Automated verification

- Clean Godot 4.3 `--headless --import`: exit 0, no parser/import errors.
- All 39 discovered `tests/smoke_test*.tscn` scenes ran and printed their
  expected `_OK` marker.
- 37/39 were clean under the release error-signature scan.
- `smoke_test_save.tscn` printed the expected JSON parser error while
  deliberately corrupting its primary file to prove backup recovery.
- `smoke_test_danger_presentation.tscn` printed seven genuine pre-existing
  deferred `_bind_button` errors while rapidly freeing test scenes. Its logical
  assertions pass, but the strict no-error gate does not.
- `android_launcher_asset_test.tscn`: pass.
- `android_export_resource_test.tscn`: pass; two presets, version code 2,
  correct ABIs/catalog counts.

## Remaining release blockers

1. Suppress discovery rewards while materialising missing residence boards so
   v1→v2 migration cannot mutate coins or discoveries.
2. Make `UIAnimationDirector`'s deferred button binding resilient to a Button
   being freed before the deferred call executes.
3. Decide whether the size gate means 200 MiB or 200,000,000 bytes; optimise a
   further 5.71 MB if the latter.
4. Move to a Godot Android toolchain that produces 16 KB-aligned native
   libraries before targeting Android devices that require it.
5. Complete manual listening and per-background ETC2 A/B review on the target
   physical device.
