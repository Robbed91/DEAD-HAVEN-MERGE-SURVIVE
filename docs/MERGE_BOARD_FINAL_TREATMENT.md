# Construction Merge Board — Final Visual Treatment

Status: integrated and verified in Godot 4.3 on the `visual-production` branch.

## Protected gameplay boundary

The treatment does not modify `BoardState`, item IDs, chain order, merge validation, producer rules, storage capacity, resource economy, save fields, or progression. `MergeBoard` still calls the existing `move_to_cell`, `try_merge`, and `tap_producer` APIs exactly once per interaction. Presentation awaits and effects occur around the returned result.

## Final asset set

- `assets/ui/merge_board/survival_workbench.jpg`: 720 × 1556 painterly reinforced workbench, clean central play area, edge-only survival props.
- `assets/ui/merge_board/cell_*.png`: 128 × 128 normal, valid, invalid, and locked cell materials.
- `assets/ui/merge_board/storage_slot.png`: 128 × 128 final storage slot material.
- `assets/ui/merge_board/selection_frame.png`, `lock_plate.png`, `cobweb.png`: transparent interaction overlays.
- `assets/ui/merge_board/reward_glow.png`, `wood_chip.png`, `dust_soft.png`: transparent merge-reward effects.
- `assets/items/construction/level_1.png` through `level_8.png`: 256 × 256 transparent final construction chain. These map in order to splintered scrap wood, reclaimed offcuts, cut timber strips, stacked boards, reinforced plank bundle, portable barricade kit, fortified wall section, and defensive gate assembly. The existing item IDs remain unchanged.
- `assets/items/construction/producer.png` and `producer_{selected,active,low_charge,empty,recharge,upgraded}.png`: 256 × 256 transparent Salvaged Tool Crate states. The live infinite-charge producer uses normal, selected, active, and recharge states. Low-charge, empty, and upgraded are available through the presentation-only state API without inventing gameplay data.

All board items use a consistent three-quarter top-down camera, upper-left key light, clean silhouette, alpha background, internal padding, restrained charcoal edge, and painted contact shadow. Levels 5–8 are different constructed objects rather than scaled copies.

## Integrated feedback

- Drag lift: enlarged drag ghost, source fade, lift sound.
- Valid target: olive/amber cell pulse computed from the current definitions without changing drop acceptance.
- Invalid target: rust/red cell signal plus the existing shake path.
- Successful merge: source pull, dual compression, result expansion, contact bounce, textured glow, wood chips, and dust.
- High-level merge: larger particle radius, stronger glow, and separate high-level wood cue from level 5 onward.
- Producer: selected texture, open active texture and bounce, recharge texture/cue, and empty texture/cue.
- Storage: final wood/iron drawer and slots using the same item renderer and drag behavior as the board.
- Discovery reward: parchment reward card with the resulting final item art.

Reduced-motion/effects settings continue to suppress motion-heavy effects through the existing `GameManager.effects_enabled()` path.

## Audio

New stereo 22.05 kHz WAV cues:

- `item_lift.wav`
- `merge_pull_wood.wav`
- `merge_wood_high.wav`
- `producer_empty.wav`
- `producer_recharge.wav`

The existing `merge_wood.wav`, `merge_invalid.wav`, `producer_tools.wav`, and `discovery.wav` remain the base cues. Cue registration is presentation-only in `AudioManager`.

## Verification artifacts

- `docs/vertical-slice-captures/merge_board_construction_ready.png`
- `docs/vertical-slice-captures/merge_board_construction_merged.png`
- `docs/vertical-slice-captures/merge_board_final_running.png`
- `docs/vertical-slice-captures/merge_board_construction_merge.avi`

The capture harness uses the real board controller to merge the two starter `construction_1` instances and fails if the result is not exactly one `construction_2`. Non-construction producers are moved into storage in this test-only scene solely to keep the approval capture focused; production starting-layout behavior is unchanged.

The recorded 405 × 720 Android-size run is four seconds at 60 FPS. Godot reported an average 0.95 ms CPU and 0.31 ms GPU per frame during recording.

## Generated illustration provenance

The workbench was generated with the built-in image-generation tool in `stylized-concept` mode and then downscaled to the Android source budget. Final prompt:

> Original premium portrait mobile merge-board background: worn survival planning table/reinforced field workbench; warm neutral scarred oak inside weathered charcoal steel-and-wood framing; folded map, nails, cord, carpenter pencil, ruler, and wood shavings confined to outer edges; central 82% clean for a 7 × 9 runtime grid; painterly 2.5D stylized realism; warm amber upper-left light against cool blue-grey rim; no text, grid, controls, logos, watermark, characters, item icons, flat vector geometry, collage, or clutter.

Small state overlays and short sound cues are reproducibly built by `tools/build_merge_board_assets.py`. Construction-chain and crate art retain the approved Hollow Creek vertical-slice concept source.
