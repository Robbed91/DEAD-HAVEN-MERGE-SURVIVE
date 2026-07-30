# Art asset guide

Dead Haven's visual identity is an original 2.5D illustrated style - see
"Visual identity" in README.md for the palette. This guide tracks what
exists, what's still a code-drawn placeholder, and what a finished asset
needs to contain when it's produced. See
`assets/manifests/asset_manifest.json` for the machine-readable version of
this table.

## Placeholder technique used in Phase 1

Where a final illustration doesn't exist yet, the corresponding scene has a
small `Control` subclass that draws a simplified but recognisable version
of the intended art directly with Godot's `_draw()` API (flat silhouettes,
the established colour palette, no photo-real detail). This satisfies the
placeholder-art policy - readable silhouettes, consistent style, no blank
rectangles or generic circles standing in for finished characters - while
keeping every placeholder trivially swappable: delete the `_draw()` body
(or the whole script) and point the same node at a `TextureRect`/
`AnimatedSprite2D` instead. Gameplay code never depends on how a visual is
implemented.

Current placeholder scripts:
- `scenes/main_menu/main_menu_background.gd`
- `scenes/haven/haven_background.gd`
- `scenes/world_map/world_map_background.gd`
- `scripts/ui/survivor_silhouette.gd`
- `scripts/merge/item_icon_renderer.gd` (Phase 2) - one reusable renderer for
  all 101 merge items instead of 101 bespoke drawings: a rarity-tinted
  background, a category-specific silhouette (distinct shape per chain -
  planks for Construction, a hammer for Tools, a cross for Medical, etc.),
  a level badge, and overlays for producer/cooldown/exhausted/locked/
  cobweb/bubble states. Every `ItemDefinition.icon_path` already points at
  its intended final PNG location under `assets/items/`; swapping in real
  art means populating those files and switching `ItemView` to draw a
  texture instead of calling this renderer - the renderer itself doesn't
  need to change or be removed immediately, `ItemView` just needs a real-
  asset-exists check added when that art lands.

## Environment layering (per design spec section 20)

Every residence scene should ultimately be built from separable layers so
individual pieces can animate/update independently:

1. Background (sky, distant terrain)
2. Structure (the building itself)
3. Furniture
4. Damage / debris
5. Interactive hotspots
6. Characters
7. Foreground objects
8. Lighting overlays
9. Weather effects
10. Particle effects

`haven_background.gd` currently draws layers 1-4 procedurally in a single
script for Hollow Creek Farmhouse; splitting these into separate nodes/
textures is expected once real art replaces the placeholder (tracked as
high priority in the asset manifest).

## Characters - required set per survivor (not yet produced)

For each main survivor (Mara Vale, Noah Vance, Lena Ortiz, Dr Imogen Shaw,
Riley Chen, Caleb Rusk):

- Neutral pose, speaking pose
- Concerned, angry, happy, injured expressions
- Scavenging outfit, residence outfit

Status: not started. `SurvivorDefinition.portraits` / `.expressions`
(scripts/data_models/survivor_definition.gd) are the Dictionaries these
will be registered under once produced.

## The Hollow - required set per type (not yet produced)

Drifter, Screecher, Breaker, Lurker, Runner, Bloater - each needs idle,
move and attack animation sets per the asset manifest. Direction: stylised
and unsettling, torn clothing, pale/discoloured skin, distinct readable
silhouettes, limited blood - not excessive gore.

## Licensing

All art must be original or licence-safe. Nothing may be copied or
adapted from Merge Mansion, The Walking Dead, or any other existing
copyrighted property - not character designs, not UI layouts, not logos.
