# Batch 08 — Construction Chain Approval Gate

## Scope

One merge chain only: the existing final construction chain and Salvaged Tool Crate producer. No other merge chain or navigation/category icon was converted in this approval batch.

## Verified illustrated objects

1. Scrap Wood (`construction_1`)
2. Wood Offcut (`construction_2`)
3. Timber Strip (`construction_3`)
4. Wooden Board (`construction_4`)
5. Reinforced Plank Bundle (`construction_5`)
6. Barricade Kit (`construction_6`)
7. Fortified Wall Section (`construction_7`)
8. Defensive Gate Assembly (`construction_8`)
9. Salvaged Tool Crate (`construction_producer`) and its existing selected, active, low-charge, empty, recharge, upgraded, cooldown, exhausted, and reward artwork.

Every level is a distinct upgraded physical assembly in the shared three-quarter perspective. All item IDs, displayed names, merge order, levels, rarity, producer behavior, and task consumers remain unchanged.

## Integration and animation

- The real `ItemView` uses the transparent raster illustration for every construction item; procedural item fallback count is zero.
- Existing drag lift, valid/invalid target feedback, merge pull/compression/expansion, bounce, dust/wood particles, maximum-level feedback, producer states, cooldown, cobweb, and bubble treatment remain connected to the existing board events.

## Verification

- `SMOKE_MERGE_ICONS_OK definitions=101 missing=0 fallback=0`
- `SMOKE_MERGE_TEST_OK`, including a real construction merge, invalid/max-level rejection, producer energy/cooldown, storage, delete/undo, reward collection, and save/reload.
- Real OpenGL capture: `docs/vertical-slice-captures/merge_board_construction_chain_final.png`; all eight levels and the producer were found through the running board's `ItemView` nodes before capture.

## Remaining placeholders

No additional icon family was modified. Navigation-icon visual approval and all non-construction merge chains remain outside this gate exactly as requested.
