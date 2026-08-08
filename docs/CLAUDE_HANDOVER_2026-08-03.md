# Claude handover — Dead Haven visual-production

Date: 2026-08-03

Repository: `https://github.com/Robbed91/DEAD-HAVEN-MERGE-SURVIVE`

Branch: `visual-production` only; create no branch.

## Base state

Start from the latest `origin/visual-production`. The unified residence/merge checkpoint is commit `a96f0b5` (`ui: unify residence and merge home screen`). The subsequent producer-art commit should be immediately above it.

Completed and pushed before this handover:

- Locked hotspot taps are blocked.
- All nine producers unlock progressively from story/repair progress.
- Tested-APK padlock source was traced and documented.
- Save schema version 2 stores five isolated residence boards and migrates a legacy global board exactly once without losing item instance IDs, positions, storage, charges/cooldowns, lock/cobweb/bubble flags, or discovery.
- Every fresh residence board is dense: 59 occupied cells, 42 boxes, six exposed cobwebs, nine progressively gated producers, two free starters, four work cells.
- Adjacent normal merges reveal boxes; matching free items clear cobwebbed items. Covered/cobwebbed items cannot move, store, delete, collect, count for tasks, or be task-consumed.
- All five residences now embed their own 7x9 board with hotspots and in-place task modal. Merge is removed from bottom navigation and public routing. **Find on Board** highlights the embedded chain.
- The unified batch passed clean import reconciliation, 33/33 smoke scenes, Android runtime-resource checks, and 720x1600/large layout checks.

## Artwork ready for integration

Eight approved state families now exist at stable runtime paths:

- `assets/items/tool/producer_{selected,active,low_charge,empty,recharge}.png`
- `assets/items/food/producer_{selected,active,low_charge,empty,recharge}.png`
- `assets/items/medical/producer_{selected,active,low_charge,empty,recharge}.png`
- `assets/items/trap/producer_{selected,active,low_charge,empty,recharge}.png`
- `assets/items/fuel/producer_{selected,active,low_charge,empty,recharge}.png`
- `assets/items/vehicle_parts/producer_{selected,active,low_charge,empty,recharge}.png`
- `assets/items/electronics/producer_{selected,active,low_charge,empty,recharge}.png`
- `assets/items/clothing/producer_{selected,active,low_charge,empty,recharge}.png`

Do not replace any existing `producer.png`. Source masters are under `assets/concepts/producer_states/`; review sheets are under `docs/producer-state-captures/`.

## Required coding batches, in order

### 1. Integrate producer state artwork

Generalize `scripts/merge/item_view.gd::_resolve_icon_texture()` so every producer resolves `res://assets/items/<chain>/producer_<state>.png`. Preserve normal `ItemDefinition.icon_path` fallback and the existing Construction behavior. Do not alter producer IDs, charges, cooldowns, energy, outputs, unlocks, spawn probabilities, or save data.

Add focused tests that instantiate all nine producers in normal/selected/active/low-charge/empty/recharge and assert the expected final texture path. Verify locked producers still remain interaction-blocked and that visual state calls do not mutate gameplay state. Capture the full contact sheet and a live embedded-board active/empty/recharge sequence.

### 2. Gameplay-chain cash-out

The latest user correction supersedes earlier merge feedback. Add tap-to-collect at several data-driven levels on the nine gameplay chains, not only the four reward chains. Keep task/story/vehicle uses intact. A surplus item must offer a meaningful but balanced coin/energy/rare-item return; collecting must remain optional. Never allow producer, box-covered, cobwebbed, bubbled, or task-reserved state to bypass its restrictions. Do not change chain order or normal merge results.

Store reward metadata in additive item fields or a separate stable catalog; avoid changing existing item IDs or save keys. Extend save/smoke coverage around collect, undo/invalid state where applicable, and reload.

### 3. Remaining strict-quality presentation

- Add one pooled, chain-ID-driven merge VFX system for Construction, Tools, Food, Medical, Traps, Fuel, Vehicle Parts, Electronics, and Clothing. Preserve merge timing/results; reduced motion uses a short fade/glow; low quality reduces particles; hidden effects stop processing.
- Add environment presets and scene mappings for rain, fog, dust, leaves, smoke/exhaust, embers, sparks, lantern/interior flicker, radio pulses, cloud shadows, and foliage. Effects must be state-plausible and cannot obscure cells, hotspots, tasks, dialogue, or resources.
- Add gameplay-neutral danger presentation only to existing defence/scavenging/fuel/danger triggers. No new hazards or probability changes; no aggressive flashing; reduced motion retains static warning information.
- Replace the live procedural chain-legend swatches with existing final illustrated representative item/producer art. Retain defensive renderer scripts unless an exported-dependency audit proves them unreachable.
- Reconcile stale `docs/RELEASE_PRESENTATION_GAP_REPORT.md`, `assets/manifests/asset_manifest.json`, `docs/FINAL_ASSET_MANIFEST.csv`, and related animation/checklist rows against runtime truth. The launcher is already final; all five residence visual progressions, all 101 items, all implemented characters, all 41 hotspots, vehicles, maps, scavenging, and audio are already final/integrated. Hollow interiors and unimplemented Hollow enemy types are deferred, not release blockers.

### 4. Android verification and package

Use Godot's normal debug signing only. No release keystore is required. Keep the same package ID and debug signing identity for version-code-1 to version-code-2 upgrade testing. Never commit a keystore or credentials.

Complete export-size/resource audit, texture/audio/memory review, 720x1600 / 1080x2400 / Pixel 9 1080x2424 / 1440x3200 safe-area checks, frame-time/PSS measurements, clean install, upgrade without clearing data, pause/resume/force-stop/relaunch, and persistence validation. Produce the arm64 debug-signed APK plus x86_64 verification APK if the emulator requires it, checksum, certificate report, size/content report, screenshots/videos, and install/upgrade evidence.

## Lower-priority requested design items

- XP-star bonus drops on merges to level 5+.
- A story/chapter key currency distinct from Coins, Energy, and Haven Tokens.

Plan these explicitly before implementation because both touch balance and saves. They are not blockers for the producer integration/cash-out batch.

## Non-negotiable compatibility

Do not alter task/quest/residence/hotspot/item IDs, chain order/levels/results, producer economy, energy/resource balance, survivor/relationship/dialogue/defence/vehicle/story data, navigation destinations, save keys, or save schema except through an explicitly planned additive migration. Existing version-1 and version-2 saves must continue loading.

## Verification discipline

For every batch: clean headless import, all exactly 33 `tests/smoke_test*.tscn` scenes, focused tests, error-signature scan, relevant save/reload, runtime capture, `DEVELOPMENT_LOG.md`, separate commit, and push to `origin/visual-production`. Do not merge or rewrite any Claude branch; the user handles later fast-forwarding.
