# Dead Haven Final Interface Skin

## Scope and invariants

This pass replaces the shared visual skin without changing information architecture, control names, signal connections, route keys, destinations, dynamic text, save data, progression, economy, or gameplay behavior. All changing values remain live Godot labels and controls.

The final palette follows the art bible: weathered charcoal structure, warm cream content cards, olive primary actions, rust-orange construction actions, amber reward/focus cues, storm blue-grey secondary surfaces, and emergency red reserved for danger.

## Component state contract

| Requested state | Final implementation |
| --- | --- |
| Normal | Olive or charcoal nine-slice material control with cream text |
| Pressed | Darkened material plate with retained silhouette and touch target |
| Selected | `NavSelectedButton` olive plate plus live `button_pressed` state |
| Disabled | Desaturated charcoal plate and reduced-contrast text |
| Focused | Three-pixel amber outline independent of colour perception |
| Notification | Brass bell plus optional amber flare badge and `NotificationButton` variation |
| Loading | Mechanical loading-cog artwork and `LoadingButton` variation |
| Locked | Steel padlock artwork, storm tint, and `LockedButton` variation |

The global theme also provides final parchment, charcoal, storm, survivor-card, locked-card and dialogue-panel variations; textured progress fills; custom checked/unchecked toggles; and a custom dropdown arrow.

## Integrated components

- Top resource bar: dynamic level, energy, coins, Haven Tokens and notification state with final illustrated icons.
- Bottom navigation: Haven, Merge, Map, Survivors and Inventory destinations preserved exactly, with final original icons and selected-tab treatment.
- Residence headers: weathered charcoal location/chapter/progress plate across all five implemented residences.
- Task and item-detail panels: warm parchment hierarchy, final task/item artwork, rust find action, olive completion action, disabled and danger states.
- Merge board and storage: existing final workbench/cells retained and brought under the shared navigation, modal and state skin.
- Survivor roster: responsive full-width cards, parchment recruited treatment, charcoal locked treatment and authored portrait/lock artwork.
- Dialogue: cinematic environment retained with a warm parchment text surface and final action controls.
- World map: original illustrated regional map, authored residence/mission/vehicle/lock markers, and dynamic route overlay. Marker coordinates and destinations are unchanged.
- Settings and utility screens: charcoal material backdrop, custom toggles/dropdown, styled buttons and focus/disabled treatments.
- Toast and discovery layers: explicit theme propagation across `CanvasLayer` boundaries.

## Original artwork production

Built-in image-generation mode was used for two 12-icon atlases and one regional map illustration. High-resolution sources are retained under `res://assets/ui/source/`, with runtime icons under `res://assets/ui/icons/final/` and the map under `res://assets/ui/world_map/`.

Icon prompt pattern:

> Original premium painterly 2.5D survival mobile-game UI icons in a strict grid on uniform #ff00ff chroma, fixed upper-left amber key light and cool storm-blue-grey fill, weathered charcoal/olive/rust/cream materials, clean phone-readable silhouettes and identical padding. No text, logos, emoji, watermark, flat vector art, pixel art, duplicated subjects or crossing cells.

Map prompt pattern:

> Original portrait 9:20 painterly survival-region map, high three-quarter top-down view, storm-battered rural county, winding roads, forests, farms, river, broken bridges and abandoned settlements, cool storm palette with restrained haven lights. No text, labels, pins, route lines, UI, logos or watermark.

`tools/build_ui_icon_atlases.ps1` performs deterministic cell extraction, matte removal, despill, gutter protection and shared 216-pixel safe-area normalisation.

## Android layout verification

Running-game captures are stored in `docs/ui-skin-captures/`:

- Reference: 1080 x 2400.
- Narrow Android: 720 x 1600.
- Large Android: 1440 x 3200.
- Gesture-navigation simulation: 1080 x 2400 with 48 logical pixels top inset and 72 logical pixels bottom inset.
- Representative map, merge, survivor, task, settings and dialogue screens at 1080 x 2400.

Top and bottom shared components calculate Android display-safe-area insets at runtime. Desktop capture overrides exist only in the test harness and do not alter production behavior.

## Verification

- `tests/smoke_test_ui_skin.tscn`: state styles, icons, selected navigation and map-marker contract.
- `tests/smoke_test.tscn`: every major screen instantiates successfully.
- Existing settings, merge, residence, dialogue, scavenging, vehicle/survivor and defence tests remain the gameplay-behavior authority.
- Repository scan confirms no emoji remain in production `.gd` or `.tscn` interface files.
