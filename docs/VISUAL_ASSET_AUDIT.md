# Dead Haven: Merge & Survive — Visual Asset Audit

Audit date: 2026-07-31
Audit branch: `visual-production`
Baseline commit: `4d93ff297290ce0a625f45b0612cd011a17f213b` (`Art Phase 2 (part 1): approved vertical-slice concepts`)
Engine verified: Godot `4.3.stable.official.77dcf97d8`

## Audit boundary

This is an audit only. No gameplay system, progression rule, ID, balance value,
save-data behavior, or production visual was changed. Interrupted visual work
that existed before the audit was preserved separately in `stash@{0}` and is
not part of this baseline.

The functional game is the source of truth. Visual replacements must attach to
the existing scenes, exported resource paths, signals, state dictionaries, and
animation/audio trigger points. Interactive screens must remain interactive.

## Baseline verification

- The project imports successfully in Godot 4.3 with no parse/import failure.
- All 14 existing smoke-test scenes pass.
- Sixteen major screens were captured with the normal OpenGL renderer at the
  project's actual 405×720 desktop preview size.
- All 101 `ItemDefinition.icon_path` targets are currently missing.
- Both `AudioManager.music_tracks` and `AudioManager.sfx_cues` are empty.
- The launcher icon is the original Dead Haven `icon.svg`; no default Godot icon
  is referenced anywhere in the project.

## Priority definitions

| Classification | Meaning |
|---|---|
| Critical | Dominates a core loop or first impression and materially prevents the game from matching the supplied reference. |
| High | Frequently visible production art/UI/audio that must ship, but can follow the first critical vertical slice. |
| Medium | Supporting polish, secondary state, or less-frequent screen. |
| Minor | Debug-only, transient, or finishing detail. |
| Already acceptable | Original, integrated asset that is not placeholder geometry and can ship in its current role. |

No flat geometric environment, procedural polygon illustration, emoji icon, or
silhouette character is classified as acceptable final artwork.

## Executive finding

The repository contains a complete functional prototype with a coherent color
palette and several original concept sheets, but not a production visual pass.
The live game is dominated by `Control._draw()` rectangles, circles, lines and
polygons; default Godot controls; emoji navigation/resource/map icons; empty
portrait dictionaries; and silent audio calls. The supplied reference instead
uses hand-painted mobile-game illustration, strong dark framing, parchment
information surfaces, illustrated inventory objects, readable character art,
condensed display typography, cinematic lighting, and layered scene depth.

The largest visible gaps are:

1. Five residence screens are flat geometric building diagrams.
2. The 7×9 merge board has no final frame, cells, item icons, producers or VFX.
3. All six survivors are generic color silhouettes in roster and dialogue.
4. The map, vehicle, hotspots and main-menu background are procedural drawings.
5. Navigation, resource counters and map markers use emoji rather than owned art.
6. Scavenging, defence and dialogue lack illustrated scene content.
7. No music or sound file ships, despite several existing cue calls.

The detailed production rows are in [FINAL_ASSET_MANIFEST.csv](FINAL_ASSET_MANIFEST.csv),
[ANIMATION_MANIFEST.csv](ANIMATION_MANIFEST.csv), and
[AUDIO_MANIFEST.csv](AUDIO_MANIFEST.csv).

## Major-screen review

| Screen | Evidence | Current presentation | Classification |
|---|---|---|---|
| Splash | [splash](visual-audit-screenshots/splash.png) | Original logo on a plain field; capture catches the existing fade. Logo is usable, composition needs finish. | Medium |
| Main menu | [main menu](visual-audit-screenshots/main_menu.png) | Procedural circle/house motif, basic buttons, no cinematic environment. | Critical |
| Settings | [settings](visual-audit-screenshots/settings.png) | Dense default sliders, checkboxes, option control and grey panels. | High |
| Hollow Creek Haven | [haven](visual-audit-screenshots/haven.png) | Flat striped field, polygon farmhouse and boxed geometric hotspots. | Critical |
| Redwater | [redwater](visual-audit-screenshots/redwater.png) | Flat gradient, rectangles/lines for station, garage, canopy and pumps. | Critical |
| Greybridge | [greybridge](visual-audit-screenshots/greybridge.png) | Flat brick block, rectangle windows and line-drawn tower/fence. | Critical |
| Saint Mercy | [Saint Mercy](visual-audit-screenshots/saint_mercy.png) | Flat hospital block, repeated rectangles, no illustrated atmosphere. | Critical |
| Northgate | [Northgate](visual-audit-screenshots/northgate.png) | Flat prison blocks, bars and line-drawn foreground wire. | Critical |
| Merge Board | [merge board](visual-audit-screenshots/merge_board.png) | Empty dark grid; procedural chain swatches and item renderer; no final board skin. | Critical |
| World Map | [world map](visual-audit-screenshots/world_map.png) | Plain paper rectangle, procedural route and emoji markers. | Critical |
| Scavenging | [scavenging](visual-audit-screenshots/scavenging.png) | Text and default panels only; no location art, survivor art, encounter illustration or reward art. | Critical |
| Survivors | [survivors](visual-audit-screenshots/survivors.png) | Generic colored silhouettes and flat cards; five locked placeholders. | Critical |
| Dialogue | [dialogue](visual-audit-screenshots/dialogue.png) | Black field, generic silhouette, plain bottom text/buttons; no environment layer. | Critical |
| Vehicle | [vehicle](visual-audit-screenshots/vehicle.png) | Rectangles and circles form a static van silhouette. | High |
| Defence | [defence](visual-audit-screenshots/defence.png) | Text/default panels only; no Hollow, barricade, survivor, environment or VFX. | Critical |
| Developer diagnostics | [diagnostics](visual-audit-screenshots/dev_diagnostics.png) | Functional debug-only default controls. | Minor |

## Placeholder visual inventory

### Flat geometric environments

| Asset | Live source | Scene | Finding |
|---|---|---|---|
| Main-menu environment | `scenes/main_menu/main_menu_background.gd` | `main_menu.tscn` | Gradient bands, polygon treeline/house, circular glow and line boards. |
| Hollow Creek Farmhouse | `scenes/haven/haven_background.gd` | `haven.tscn` | Gradient bands, polygon roof/barn, rectangle wall/window/door and line grass. |
| Redwater Service Station | `scenes/redwater/redwater_background.gd` | `redwater.tscn` | Gradient bands and rectangle/line station geometry. |
| Greybridge School | `scenes/greybridge/greybridge_background.gd` | `greybridge.tscn` | Rectangle building/windows and line/circle tower/fence. |
| Saint Mercy Hospital | `scenes/saint_mercy/saint_mercy_background.gd` | `saint_mercy.tscn` | Rectangle hospital/bay/windows/ambulance and line foreground. |
| Northgate Prison | `scenes/northgate/northgate_background.gd` | `northgate.tscn` | Rectangle walls/tower/cells, line bars and razor-wire shorthand. |
| World map | `scenes/world_map/world_map_background.gd` | `world_map.tscn` | Flat paper field, random dots and one procedural route polyline. |

All seven are placeholders and require final layered illustration. Existing
gameplay hotspot positions and marker coordinates can remain unchanged while
art layers beneath/around them are replaced.

### Procedural artwork scripts

The following 14 scripts draw artwork with rectangles, circles, lines, arcs,
polylines, strings or colored polygons:

| Script | Procedural role | Classification |
|---|---|---|
| `scenes/main_menu/main_menu_background.gd` | Main-menu environment and glow | Critical |
| `scenes/haven/haven_background.gd` | Hollow Creek exterior | Critical |
| `scenes/redwater/redwater_background.gd` | Redwater exterior | Critical |
| `scenes/greybridge/greybridge_background.gd` | Greybridge exterior | Critical |
| `scenes/saint_mercy/saint_mercy_background.gd` | Saint Mercy exterior | Critical |
| `scenes/northgate/northgate_background.gd` | Northgate exterior | Critical |
| `scenes/world_map/world_map_background.gd` | Paper map and route | Critical |
| `scripts/residence/hotspot_visual.gd` | All 41 repair-hotspot symbols, state badge and dust burst | Critical |
| `scripts/merge/item_icon_renderer.gd` | All 101 merge/reward items, producers and state overlays | Critical |
| `scripts/merge/item_view.gd` | Invokes the item renderer and cooldown redraw | Critical |
| `scripts/merge/chain_legend_icon.gd` | Procedural merge-chain filter swatches | High |
| `scenes/merge_board/merge_board.gd` | Generic merge-success ring burst | High |
| `scripts/ui/survivor_silhouette.gd` | Generic roster/dialogue bust and lock | Critical |
| `scripts/vehicle/vehicle_visual.gd` | Nine van upgrade states from rectangles/circles/lines | High |

These scripts may remain temporarily as low-graphics fallbacks, but they must
not be presented as final art. Replacement should be visual-only: retain their
public properties, signals and state lookups or wrap them behind texture/scene
selection without changing gameplay behavior.

## Emoji icon audit

There are 19 live emoji placements plus one plain token glyph requiring owned
vector or raster icons:

- Bottom navigation (`scenes/ui/bottom_nav.tscn`): 🏚 Haven, 🧩 Merge,
  🗺 Map, 🧑‍🤝‍🧑 Survivors, 🎒 Inventory.
- Top resource bar (`scenes/ui/top_resource_bar.tscn`): ⚡ Energy, 🪙 Coins,
  🔔 Notifications. Haven Tokens use a plain `◆` glyph and also need a final icon.
- World map (`scenes/world_map/world_map.tscn`, `world_map.gd`): 🏚 Hollow
  Creek, four 🔒 locked residences, ⛽ Redwater, 🏫 Greybridge, 🏥 Saint Mercy,
  🏛 Northgate, 🚐 vehicle and 📦 scavenging locations.

The same icon system should provide normal/pressed/disabled/locked/notification
states, with meaning never communicated by color alone.

## Default Godot asset audit

- No default Godot launcher icon is used.
- `project.godot` points to the original Dead Haven `res://icon.svg`.
- The original logo set under `assets/branding/logo/` and launcher icon are
  classified **Already acceptable** for their current roles.
- The Android notification SVG is original and suitable, but is not yet wired
  to an Android export preset.
- Godot's default font and default control skins are used broadly. They are not
  image assets, but every production-facing UI screen needs the final typography
  and control-skin pass listed in the final manifest.

## Character and creature audit

All six `SurvivorDefinition` resources have empty `portraits` and `expressions`
dictionaries:

| Character | Current live visual | Missing final set | Classification |
|---|---|---|---|
| Mara Vale | Generic olive silhouette | Neutral/speaking plus 12-expression set, scavenging/residence/injured outfits, action rig | Critical |
| Noah Vance | Generic rust silhouette | Same complete portrait/outfit/action set | Critical |
| Lena Ortiz | Generic orange silhouette | Same complete portrait/outfit/action set | Critical |
| Riley Chen | Generic blue silhouette | Same complete portrait/outfit/action set | Critical |
| Dr Imogen Shaw | Generic teal silhouette | Same complete portrait/outfit/action set | Critical |
| Caleb Rusk | Generic muted silhouette | Same complete portrait/outfit/action set | Critical |

Mara and Noah have flattened concept sheets only. They have no transparent
runtime crops, separated rig layers or animation-ready production source.

The six Hollow types—Drifter, Screecher, Breaker, Lurker, Runner and Bloater—
have no live sprites at all. Only the Drifter has a flattened concept sheet.
Defence currently represents every enemy entirely through text.

## Merge-item audit

- 101 `.tres` item definitions exist across 13 chains.
- All 101 declared PNG paths under `assets/items/` are missing.
- `ItemIconRenderer` substitutes category silhouettes, rarity borders, level
  numbers and geometric producer/cooldown/lock/cobweb/bubble overlays.
- Every chain needs a coherent illustrated progression plus its producer:
  construction (9 files), clothing (8), electronics (8), food (8), fuel (8),
  medical (8), tools (8), traps (8), vehicle parts (8), and four seven-level
  reward chains: coins, energy, Haven Tokens and XP.
- Board cell states also need final empty/occupied/selected/valid/invalid/locked/
  cobweb/reward/bubble/task-required/rare/max visuals without changing the 7×9
  board geometry or merge logic.

## Animation and VFX audit

Implemented motion is limited to simple Tweens or per-frame procedural effects:
scene fade, splash fade, main-menu glow, map-marker pulse, item select bounce,
invalid shake, generic merge ring, generic hotspot dust, toast fade and discovery
banner fade. These are functional triggers, not a complete animation pass.

Missing production animation includes survivor rigs/actions/expressions, all
Hollow motion, nine-stage vehicle motion, environment ambience/parallax/weather,
full residence repair sequences, chain-themed merge particles, producer opening,
item spawn/collect/bubble/cobweb effects, map route reveals/travel, defence enemy/
trap/barricade actions, resource-counter feedback and production panel/button
transitions. See [ANIMATION_MANIFEST.csv](ANIMATION_MANIFEST.csv).

## Audio audit

No `.ogg`, `.wav` or `.mp3` file ships. `AudioManager` creates working Music and
SFX buses and a six-voice SFX pool, but both cue dictionaries are empty. Existing
code calls only `merge`, `merge_invalid`, `discovery`, `producer_activate`,
`task_complete`, and dialogue-entry `sound_cue`; each currently logs an unsourced
warning. No scene currently calls `play_music()`.

Required music, UI sound, merge foley, repair foley, ambience, dialogue/radio,
Hollow, defence and vehicle audio is enumerated in
[AUDIO_MANIFEST.csv](AUDIO_MANIFEST.csv).

## UI components requiring a final skin

Every production-facing UI component needs artwork/typography treatment:

- `ThemeFactory`: font family, button, panel, checkbox, slider, option menu,
  progress bar, focus/disabled/pressed states and high-contrast variants.
- `top_resource_bar`: resource backplates, final icons, XP/energy meters,
  notification state.
- `bottom_nav`: owned tab icons, dark chrome, active/pressed/disabled states.
- Main-menu title treatment, button stack and version/footer.
- Residence title/progress plate, hotspot markers and defence CTA.
- Merge-board frame, 63 cells, chain legend, storage entry, item-info panel,
  storage panel, task panel and discovery banner.
- World-map parchment/terrain, routes, residence/scavenging/vehicle markers and
  locked/completed/active states.
- Survivor cards, portrait masks, lock/recruit/injury/assignment states.
- Dialogue portrait frame, speaker plate, text parchment, continue/choice states
  and optional cinematic background/foreground layers.
- Scavenging and defence preparation/encounter/outcome panels.
- Vehicle stage art, requirement panel and upgrade action treatment.
- Settings groups and controls; toast; debug diagnostics (minor priority).

## Existing non-runtime concepts

Nine flattened PNG concepts exist under `assets/concepts/vertical_slice/`:
Mara, Noah, Drifter, Hollow Creek stages 1/2, construction progression, producer
states, repair storyboard and intro composition. They are useful references but
are not transparent, layered, sliced, animated, optimized or wired into runtime.
They do not satisfy the final asset requirements by themselves.

## Replacement safety conclusion

Nearly all listed work can occur without changing gameplay logic. The safe
integration pattern is to preserve scene paths, node names used through `%Name`,
signals, IDs, data resources, state enums, touch targets and public methods while
replacing only render nodes/resources and attaching animation/audio to existing
events. New code is justified only for visual-state selection, animation playback,
audio playback, responsive layout, accessibility or mobile optimization.
