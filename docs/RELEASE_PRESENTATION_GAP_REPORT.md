# Release Presentation Gap Report

Updated: 2026-08-01  
Branch audited: `visual-production` at `0040f07`

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
| UI skin | `SMOKE_UI_SKIN_OK states=8 navigation=5 emoji_markers=0` | Final global controls, top bar, five navigation destinations and map markers are active. |
| Main menu | `SMOKE_MAIN_MENU_PRESENTATION_OK final_art=1 runtime=720x1280 controls=4 ambient_layers=4 reduced_motion=pass primitives=0` | Final painterly interactive menu is integrated. |
| Splash | `SMOKE_SPLASH_PRESENTATION_OK final_art=1 live_title=1 legacy_svg=0 reduced_motion=pass` | Final illustrated boot presentation is integrated. |
| Animation/effects | `SMOKE_ANIMATION_LAYER_OK reduced_motion=pass offscreen=pass state_neutral=pass` | Shared motion is accessibility-gated, off-screen suspended and gameplay-neutral. |
| Audio | `SMOKE_AUDIO_PRESENTATION_OK buses=7 cues=61 music=12 ambience=14 assets=250` | Implemented audio catalogue and routing are complete. |
| Save compatibility | `SMOKE_SAVE_TEST_OK` | Current save/reload and corrupt-primary backup recovery pass. |

## Defensive fallback code that is not a current release-facing placeholder

- `scripts/merge/item_icon_renderer.gd` is retained only for malformed or future item definitions. The inventory test proves all 101 implemented definitions bypass it.
- `scripts/residence/hotspot_visual.gd` retains procedural fallback drawing for malformed or future residences. Tests prove all 41 implemented hotspot IDs bypass it.
- `scripts/ui/survivor_silhouette.gd` is retained for missing/future character data. Every implemented survivor and the Drifter have final artwork.
- `scripts/vfx/ambient_vfx.gd` draws low-cost particles and light/fog primitives as effects, not as substitute environment artwork. It is accessibility-gated and off-screen suspended.
- `scenes/world_map/world_map_background.gd` draws interactive route strokes over final map art; these are stateful UI overlays, not environment substitutes.

These files must not be deleted merely because a text search finds `draw_*`; removal is safe only after export-time validation proves no future/error path relies on them.

## Genuine remaining release blockers

1. **Android launcher/adaptive icon — High.** `icon.svg` is original but still a flat geometric boarded-door symbol and does not meet the approved premium illustrated-object standard. Create final launcher artwork, separate adaptive foreground/background layers, export density variants, and update both `project.godot` and `export_presets.cfg`.
2. **Android device optimisation and APK verification — High.** Perform import-size/VRAM audit, verify ETC2/ASTC settings, test narrow/large/gesture-safe layouts, measure representative Android frame time and memory, build a signed installable APK, then test clean install, upgrade install, pause/resume and save persistence.
3. **Manifest reconciliation — Medium.** Several original audit rows still describe now-replaced runtime content as Critical/placeholder. Their asset records need an evidence-based status update; the runtime tests above, not those stale labels, are currently authoritative.
4. **Verified obsolete-placeholder cleanup — Medium.** Remove only assets proven unreachable in an exported build. Defensive error/future fallbacks should remain until the export dependency audit is complete.

## Implemented scope clarification

The audit lists Screecher, Breaker, Lurker, Runner and Bloater as future/missing concepts, but no gameplay definitions currently implement those Hollow types. The only implemented Hollow type is the Drifter, which has final art and animation. Future enemy concepts are not blockers for completing the existing game presentation and must not be wired in by changing gameplay scope.

## Git branch consolidation status

After `git fetch --prune origin` on 2026-08-01:

- `origin/main` has **0 commits absent** from `visual-production`; `visual-production` is 35 commits ahead.
- `origin/claude/dead-haven-repo-setup-gvbesn` has **0 commits absent** from `visual-production`; `visual-production` is 20 commits ahead.
- `origin/visual-production` matches the local branch at the audit point.

This proves all currently published branch work is already contained in `visual-production`. The same fetch and left/right ancestry check is mandatory immediately before APK creation so later branch changes are not missed.
