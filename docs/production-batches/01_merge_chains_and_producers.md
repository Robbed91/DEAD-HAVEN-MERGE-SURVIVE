# Production Batch 01 — Merge Chains and Producers

Date: 31 July 2026  
Baseline commit: `b9c74771eae342cba671927b8b70390e236115ad`

## Result

Approved and verified complete. No gameplay definitions or merge mechanics were
changed during this verification batch.

- 101/101 existing item definitions resolve to final 256×256 illustrated PNGs.
- All nine implemented producer definitions appear on the deterministic 7×9
  workbench and retain their existing energy, cooldown and output behaviour.
- Salvaged Tool Crate includes its authored normal, selected, active,
  low-charge, empty, recharge, cooldown, exhausted, reward and upgraded art.
- The other eight producers use final illustrated producer art plus the shared
  runtime state treatment; no implemented item routes through the procedural
  icon fallback.

## Assets recorded

- Runtime item library: `assets/items/<chain>/`
- Retained generation sheets: `assets/items/source/`
- Authoritative inventory: `docs/MERGE_ITEM_ASSET_MANIFEST.csv`
- Merge-board production record: `docs/MERGE_ICON_PRODUCTION.md`

## Animation recorded

Drag lift, drop bounce, valid-target pulse, invalid shake, merge pull,
compression, expansion, contact bounce, wood/dust/high-level effects, producer
activation/empty/recharge feedback, item discovery and maximum-level feedback
remain integrated through the existing merge presentation scripts.

## Audio recorded

Pickup, drop, invalid move, generic/material merges, producer active/empty/
recharge, reward collection and chest cues remain routed through the existing
audio catalog and buses. No audio files changed in this verification batch.

## Verification

- `tests/smoke_test_merge.tscn` — passed, including producer, merge, storage,
  reward, delete/undo and save/reload assertions.
- `tests/smoke_test_merge_icons.tscn` — passed: 101 definitions, zero missing,
  zero fallback routes.
- `tests/smoke_test_save.tscn` — passed, including corrupted-primary backup
  recovery.
- Running screenshot: `docs/vertical-slice-captures/merge_board_all_producers.png`.
- Merge interaction video: `docs/vertical-slice-captures/merge_board_construction_merge.avi`.

## Files modified in this batch

- `docs/production-batches/01_merge_chains_and_producers.md`

## Remaining placeholders

None among implemented merge items or producers. The procedural item renderer
is retained only as a verified defensive path for corrupt, missing or future
unknown assets and is not reached by current content.
