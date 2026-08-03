# Residence junk and cobweb layouts

Date: 2026-08-03

Starting commit: `14a07ec0a8eb5c88b92a304931759b17bb479a4a`

Branch: `visual-production`

## Objective

Activate the dormant box/cobweb board-item state for all five isolated residence boards. New boards must begin as rooms to excavate rather than sparse grids, while normal merge results, tasks, economy, IDs, and the version-2 save envelope remain compatible.

## Authored layouts

Five runtime JSON manifests define deterministic, residence-specific starting arrangements:

- `data/boards/hollow_creek_farmhouse.json`
- `data/boards/redwater_service_station.json`
- `data/boards/greybridge_school.json`
- `data/boards/saint_mercy_hospital.json`
- `data/boards/northgate_prison.json`

Every fresh 7x9 board contains 59 occupied cells and four work cells: nine established producers, two free Construction level-1 starters, six visible cobwebbed items, and 42 box-covered items. The covered item pools are reordered by residence identity without adding item definitions or changing chain progression.

## Interaction rules

- Box-covered and cobwebbed items cannot be dragged, stored, deleted, collected, consumed by tasks, counted toward task requirements, or used as the dragged merge source.
- A successful merge reveals orthogonally adjacent box-covered items as cobwebbed underlying items.
- A cobwebbed target accepts only a matching free item with the same existing chain and level. The normal merge result is then created in the target cell; no alternate outcome or gameplay value was introduced.
- Producer locks continue to use the existing progressive story/repair rules and are not mistaken for revealable junk.
- UI drag behavior, item details, and failure toasts explain the blocked state while retaining the existing lock-plate and cobweb presentation assets.

## Save compatibility

Each residence payload records `layout_version = 1` inside the already-versioned board document. Existing version-2 boards keep every saved item and position, then fill only eligible empty cells from their residence manifest once. Version-1 migration still assigns the legacy board to one residence exactly once before the same one-time layout backfill. Account-wide discovery rewards are not granted for authored junk.

No save key, content ID, quest requirement, merge result, producer output, charge, cooldown, energy cost, reward value, story flag, or residence/hotspot definition changed.

## Android packaging

Both Android presets explicitly include `data/boards/*.json`, because these manifests are loaded through dynamic string paths. The focused export-resource test parses all five manifests and checks their layout version, nine producer positions, six cobweb items, and four empty work cells.

## Verification

- Focused merge smoke: pass. Confirms 59 occupied cells, 42 boxes, six cobwebs, four work cells, blocked interactions, adjacency reveal, matching cobweb clear, producer progression 1 to 9, residence isolation, and save/reload.
- Focused save smoke: pass. Confirms version-1 exact-position migration, five materialized residence boards, version-2 round trip, and intentional corrupt-primary backup recovery.
- Android export-resource contract: pass for both presets and all five layout manifests.
- Empty-cache Godot 4.3 import rebuilt 1,722 imported artifacts but returned exit 1 without a diagnostic at process cleanup. The immediate verbose reconciliation import exited 0 with no parser, missing-resource, import, shader, or texture failure.
- Full smoke suite: 33/33 pass. The only emitted diagnostics were established ObjectDB shutdown warnings and the save test's intentional corrupt-primary/backup-recovery warnings.

## Assets and presentation

- Assets created or rejected: none. Existing final item art plus the existing lock-plate and cobweb overlay textures are used.
- Visual states added: active box-covered and cobwebbed board states.
- Animations and audio: no new assets; existing invalid-action feedback remains authoritative.
- Optimisation: layouts are small JSON manifests and junk discovery rewards are suppressed during materialization.

## Next batch

Extract the board into a reusable residence-owned panel, activate the correct residence board before child setup, embed it in all five residence scenes, show hotspot task requirements without navigation, and remove Merge from bottom navigation while retaining test coverage for the standalone scene only as an internal compatibility harness until the unified view is proven.
