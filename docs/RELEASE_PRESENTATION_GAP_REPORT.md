# Release Presentation Gap Report

Updated: 2026-08-03
Branch audited: `visual-production` at `64f94c2`

## Verified complete in the running project

| Area | Runtime evidence | Result |
|---|---|---|
| Merge items | `SMOKE_MERGE_ICONS_OK definitions=101 missing=0 fallback=0` | Every implemented definition imports final 256 × 256 art; no procedural item renderer is release-facing. |
| Survivors | `SMOKE_CHARACTER_PORTRAITS_OK survivors=6 expressions=48 fallback=pass grid=7x9` | All six implemented survivors have eight registered expressions; fallback remains defensive only. |
| Repair hotspots | Hollow Creek/Northgate tests plus `SMOKE_REMAINING_HOTSPOT_ICONS_OK icons=24 source=1024 runtime=256 fallback=0` | All 41 implemented hotspot IDs use final illustrated artwork; procedural pictograms remain defensive only. |
| World map | `SMOKE_WORLD_MAP_PRESENTATION_OK unique_scavenge=10 locked_identity=1 routes=4 vehicle=1` | Final regional art, markers, routes and vehicle presentation are integrated. |
| Dialogue | `SMOKE_DIALOGUE_PRESENTATION_OK speakers=7 backgrounds=7 geometric_fallback=0 reduced_motion=1 reveal_animation=1` | Every implemented dialogue speaker/environment mapping uses final presentation. |
| Scavenging | `SMOKE_SCAVENGING_PRESENTATION_OK locations=10 runtime=1024x683 dynamic=1` | Ten implemented locations use unique final environments in the real interactive flow. |
| Vehicles | `SMOKE_VEHICLE_PRESENTATION_OK stages=9 runtime=512 layered=1 state_neutral=1 save_states=9` | All implemented delivery-van states are illustrated, animated and save-neutral. |
| Defence | `SMOKE_DEFENCE_PRESENTATION_OK events=5 leaders=5 drifter=5 encounter_animation=1 gameplay_mutations=0` | Five implemented defence events use final environments, survivor rigs and Drifter presentation. |
| UI skin | `SMOKE_UI_SKIN_OK states=8 navigation=4 embedded_merge=1 emoji_markers=0` | Final global controls, top bar, four navigation destinations (Merge is embedded, not a destination), and map markers are active. |
| Main menu | `SMOKE_MAIN_MENU_PRESENTATION_OK final_art=1 runtime=720x1280 controls=4 ambient_layers=4 reduced_motion=pass primitives=0` | Final painterly interactive menu is integrated. |
| Splash | `SMOKE_SPLASH_PRESENTATION_OK final_art=1 live_title=1 legacy_svg=0 reduced_motion=pass` | Final illustrated boot presentation is integrated. |
| Animation/effects | `SMOKE_ANIMATION_LAYER_OK reduced_motion=pass offscreen=pass state_neutral=pass` | Shared motion is accessibility-gated, off-screen suspended and gameplay-neutral. Chain-specific merge VFX, environment presets, and danger presentation are not yet built - see blockers below. |
| Audio | `SMOKE_AUDIO_PRESENTATION_OK buses=7 cues=61 music=12 ambience=14 assets=250` | Implemented audio catalogue and routing are complete. |
| Save compatibility | `SMOKE_SAVE_TEST_OK` | Current save/reload and corrupt-primary backup recovery pass, including the version-1-to-version-2 per-residence-board migration. |
| Producer state art | `SMOKE_PRODUCER_STATES_OK producers=9 states=5` | All nine producers (not just Construction) resolve authored selected/active/low-charge/empty/recharge art live through `item_view.gd`. |
| Gameplay-chain cash-out | `SMOKE_GAMEPLAY_CASH_OUT_OK` | Tap-to-collect now works on the nine gameplay chains via each item's existing `sell_value`, not only the four reward chains, gated correctly against producer/box/cobweb/bubble/task-reserved states. |
| Chain-legend art | `SMOKE_CHAIN_LEGEND_ART_OK chains=9` | The merge board's chain-highlight legend shows final producer art instead of procedural swatches. |
| Unified Home screen | Six real 720×1600 captures under `docs/ui-skin-captures/` | Merge is no longer a separate destination - all five residences embed their own isolated 7×9 board directly. |

## Defensive fallback code that is not a current release-facing placeholder

- `scripts/merge/item_icon_renderer.gd` is retained only for malformed or future item definitions. The inventory test proves all 101 implemented definitions bypass it.
- `scripts/residence/hotspot_visual.gd` retains procedural fallback drawing for malformed or future residences. Tests prove all 41 implemented hotspot IDs bypass it.
- `scripts/ui/survivor_silhouette.gd` is retained for missing/future character data. Every implemented survivor and the Drifter have final artwork.
- `scripts/vfx/ambient_vfx.gd` draws low-cost particles and light/fog primitives as effects, not as substitute environment artwork. It is accessibility-gated and off-screen suspended.
- `scenes/world_map/world_map_background.gd` draws interactive route strokes over final map art; these are stateful UI overlays, not environment substitutes.
- `scripts/merge/chain_legend_icon.gd`'s call into `ItemIconRenderer.draw_chain_swatch()` is now also defensive-only, matching the pattern above - all 9 real chains bypass it.

These files must not be deleted merely because a text search finds `draw_*`; removal is safe only after export-time validation proves no future/error path relies on them.

## Genuine remaining release blockers

1. **Android device optimisation and APK verification — High.** Not started. Import-size/VRAM audit, ETC2/ASTC verification, narrow/large/gesture-safe layout testing, representative Android frame time and memory measurement, a signed installable APK, then clean install, upgrade install, pause/resume, and save persistence testing. This is `docs/CLAUDE_HANDOVER_2026-08-03.md`'s Batch 4 and the actual remaining finish line - the debug toolchain/baseline exist (see `docs/production-batches/20_android_debug_baseline.md`), the export-size audit does not.
2. **Chain-specific merge VFX, environment presets, and danger presentation — Medium/High.** Not started. `smoke_test_animation_layer` only proves shared motion is accessibility-gated and gameplay-neutral, not that per-chain merge particles, per-residence environment effects (rain/fog/dust/leaves/smoke/embers/sparks/flicker/radio pulses/cloud shadows/foliage), or gameplay-neutral danger presentation exist yet. Still generic. `docs/CLAUDE_HANDOVER_2026-08-03.md`'s remaining Batch 3 work.
3. **Verified obsolete-placeholder cleanup — Medium.** Remove only assets proven unreachable in an exported build. Defensive error/future fallbacks (listed above) should remain until the export dependency audit in blocker 1 is complete.

Resolved since the previous version of this report: the Android launcher/adaptive icon is final and integrated (`docs/production-batches/19_android_launcher_identity.md`); manifest reconciliation is this update.

## Implemented scope clarification

The audit lists Screecher, Breaker, Lurker, Runner and Bloater as future/missing concepts, but no gameplay definitions currently implement those Hollow types. The only implemented Hollow type is the Drifter, which has final art and animation. Future enemy concepts are not blockers for completing the existing game presentation and must not be wired in by changing gameplay scope. Hollow Creek's 6 interior rooms are similarly not implemented as navigable gameplay screens and are deferred, not a release blocker.

## Git branch consolidation status

As of this update:

- `origin/main` is **47 commits behind** `visual-production`.
- `origin/claude/dead-haven-repo-setup-gvbesn` is **32 commits behind** `visual-production`.
- `origin/visual-production` matches this branch at `64f94c2`.

This proves all currently published branch work is already contained in `visual-production`. The same fetch and left/right ancestry check is mandatory immediately before APK creation so later branch changes are not missed. Per `docs/CLAUDE_HANDOVER_2026-08-03.md`, consolidating `visual-production` back into `claude/dead-haven-repo-setup-gvbesn` is the user's own step, not something to do from this branch.
