# Production Batch 20 — Android Debug Toolchain and Version-Code-1 Baseline

## Signing policy

This plan uses Godot's normal auto-generated debug keystore for every installable artifact. No release keystore, alias, or password is required or stored in Git. Keeping the same local debug keystore and package ID provides the stable signing identity needed for Android's upgrade path and save-persistence test.

## Verified local toolchain

- Godot editor/exporter: `4.3.stable.official.77dcf97d8`.
- Export templates: matching `4.3.stable` Android debug and release templates.
- Java: OpenJDK 17.
- Android SDK: platform tools, installed build tools, `adb`, `aapt`, and `apksigner`.
- Emulator: Pixel 9 profile, 1080×2424.
- Signing: Godot-generated debug keystore kept outside the repository.

`tools/verify_android_debug_toolchain.ps1` checks these requirements without accepting, reading, or printing a keystore password. It also verifies the baseline artifact identity, ABIs, APK signature, APK checksum, and signing-certificate fingerprint.

## Baseline artifact

The baseline was exported from exact commit `b79ae07a6d0d7847fdfc10a9c4cb5bf251bc2ed3` before tracked visual changes.

- Package: `com.deadhaven.mergeandsurvive`.
- Version code/name: `1` / `0.1.0`.
- ABIs: `arm64-v8a`, `x86_64`.
- APK SHA-256: `21e9e27cde8406cf9822ece36eee6f434cfb9ae14d01236cbbd26f62bf3d58db`.
- Debug certificate SHA-256: `1fba3d732cbc32351fb7e67e69044aeed0d27d1a84fc680fec79ffc7eb2b9f94`.
- External artifact: `S:\Rob B\Codex\B\Codex\godot-4.3\artifacts\baseline-b79ae07\dead-haven-v1-debug-baseline.apk`.

The APK stays outside version control. APKs, keystores, and credentials remain ignored.

## Representative save fixture

The installed baseline save contains residence progress, populated merge-board cells, a survivor unlock, resources, and settings.

- Fixture SHA-256: `dccf7b2030d7b4113b2c0c108d60d6d79877d5f45f74506d868d2fffd5c33abf`.
- External fixture: `S:\Rob B\Codex\B\Codex\godot-4.3\artifacts\baseline-b79ae07\representative-slot1.json`.

The same hash is present in the currently installed v1 app sandbox. This becomes the source data for the version-code-2 upgrade-persistence gate.

## Baseline findings carried into the export audit

- The broad `all_resources` preset produces a 373,175,068-byte APK and packages development/source content.
- Directory enumeration used to discover catalogs works in the editor but leaves dynamically discovered catalogs empty in the packed Android baseline.
- Both are baseline defects to fix in the audited v2 export; neither changes the authoritative v1 save fixture or signing identity.

