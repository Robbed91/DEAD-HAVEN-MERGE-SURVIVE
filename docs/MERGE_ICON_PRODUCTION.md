# Merge Icon Production Record

## Scope

The repository contains 101 implemented merge-item definitions. All 101 now resolve to final 256 x 256 RGBA artwork: nine construction assets, sixty-four level/producer assets across the eight standard chains, and twenty-eight reward assets across four reward chains.

No definitions currently exist for separate story-evidence, defence-supply, reward-chest, or special-event chains. Those categories were not invented or mapped onto unrelated IDs. The authoritative definition-level inventory is `MERGE_ITEM_ASSET_MANIFEST.csv`.

## Art direction and generation

The new library was generated with the built-in image-generation model in high-quality raster mode. Each source sheet used this prompt pattern, with the exact item names and order supplied per chain:

> Original premium painterly 2.5D survival mobile-game item icons on a uniform #ff00ff chroma background, arranged in a strict four-by-two invisible grid. Consistent three-quarter top-down perspective, fixed upper-left key light, cool blue-grey fill, warm amber rim, weathered materials, clean mobile-readable silhouettes, identical camera scale, padding, baseline, and soft contact shadows. One distinct progression item per cell; higher levels must be genuinely upgraded objects. No text, letters, numbers, logos, UI, watermark, people, hands, emoji, pixel art, flat vector art, duplicated subjects, crossing cells, or magenta within the objects.

High-resolution source sheets are retained under `res://assets/items/source/`. The deterministic exporter `tools/build_all_merge_icons.ps1` removes the chroma matte, suppresses colour spill, protects sheet gutters, normalises each subject to a shared 210 x 210 safe area, and writes the final runtime PNGs under `res://assets/items/<chain>/`.

## Runtime integration

The existing `icon_path` values and every item ID, name, level, chain, rarity, producer relationship, task consumer, and gameplay behaviour remain unchanged. `ItemView` now treats any valid implemented `icon_path` as final art. The old procedural drawing path remains only as a defensive fallback for a missing or future unknown asset; validation confirms that zero implemented definitions route through it.

Construction retains its authored Salvaged Tool Crate state artwork. Other implemented producers use their final producer PNG plus existing runtime selection, active, low-charge, empty, and recharge feedback without modifying producer mechanics.

## Validation contract

- Exactly 101 item definitions are inventoried.
- Every definition resolves to an existing final PNG.
- Every runtime PNG is 256 x 256 RGBA with transparent corners.
- Every definition is accepted by `ItemView` as final artwork.
- Existing merge, producer, reward, storage, delete/undo, and save/reload behaviour remains covered by `tests/smoke_test_merge.tscn`.
- The asset-route contract is covered by `tests/smoke_test_merge_icons.tscn`.
- A real running-board verification capture is stored at `docs/vertical-slice-captures/merge_board_all_producers.png`.
