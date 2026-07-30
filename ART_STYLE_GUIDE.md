# Dead Haven: Merge & Survive - Art Style Guide

This is the formal visual-identity reference the art/graphics brief (see
"Art production" in `ART_ASSET_GUIDE.md`) asked for: a single place
defining the palette, typography, and logo system that every screen and
every future illustrated asset must agree with. Code already implements
the palette (`scripts/ui/theme_factory.gd`); this document is the
human-readable version of the same source of truth, plus the parts code
can't express (typography direction, logo usage rules).

## 1. Art direction summary

Dead Haven's visual identity sits between stylised realism and clean
mobile-game readability: warm, lived-in interiors reclaimed from a cold,
overgrown exterior world. Every screen should read instantly at arm's
length on a phone - strong silhouettes and a controlled palette before
surface detail. See "Visual identity" in `README.md` for the short
version and `ART_GENERATION_PROMPTS.md` for how this translates into an
actual image-generation brief once illustrated art is produced.

## 2. Colour palette

Canonical values live in `scripts/ui/theme_factory.gd` as named
constants - this table is that same palette with its semantic role, so
design and code can never drift apart.

| Role | Constant | Hex | Used for |
|---|---|---|---|
| Haven charcoal | `CHARCOAL` | `#1c1b1a` | Dark panels, navigation, outer framing |
| Haven charcoal (raised) | `CHARCOAL_LIGHT` | `#2a2825` | Panels raised one step off the base background |
| Survival olive | `OLIVE` | `#6b7a56` | Primary gameplay controls, successful actions, safe-zone markers |
| Survival olive (deep) | `OLIVE_DARK` | `#4d5940` | Disabled controls, olive shadow/depth |
| Rust orange | `RUST` | `#b5502b` | Warnings, construction, important highlights |
| Rust orange (light) | `RUST_LIGHT` | `#cf6a3f` | Hover/active state of rust-toned elements |
| Rust orange (dark) | `RUST_DARK` | `#8a3c1f` | Pressed state, deep construction/workshop accents |
| Emergency red | `WARN_RED` | `#b23a2e` | Danger, injuries, horde warnings, critical resources - **never** ordinary actions |
| Warm cream | `CREAM` | `#e8dcc5` | Task cards, dialogue boxes, item information, primary readable text |
| Safe-haven amber | `SAFE_AMBER` | `#e2a24a` | Completed-residence glow, rewards, hopeful story moments, high-value discoveries |
| Storm blue-grey | `STORM_BLUEGREY` | `#3c4650` | Exterior scenes, locked locations, night sequences, scavenging screens |
| Wood | `WOOD` | `#6b4a35` | Timber/construction-material accents outside the button system |
| Metal | `METAL` | `#8a8f8a` | Tool/vehicle-part accents |

### Colour rules (brief section 5, unchanged - already enforced in code)

- Interactive buttons (`RUST`/`OLIVE` family via `ThemeFactory`) are
  always visually distinct from panel backgrounds (`CHARCOAL` family) -
  never same-hue-on-same-hue.
- `WARN_RED` is reserved for danger/injury/horde/critical-resource
  states. It must never be reused for an ordinary button or informational
  badge - grep for `WARN_RED` before adding a new use.
- Green (`OLIVE`) is never the *only* signal of success - every success
  state also carries an icon, label, or state change (e.g. the hotspot
  repair checkmark badge in `scripts/residence/hotspot_visual.gd`, not
  colour alone).
- A colour-blind-safe pass is still open work: today's contrast comes
  from `GameManager.settings.high_contrast` swapping to `HC_BG`/`HC_TEXT`/
  `HC_ACCENT` (pure black/white/orange) rather than per-hue
  deuteranopia/protanopia adjustment - tracked as a Phase 9 (Polish) item.

## 3. Typography

No font files are bundled yet - the project currently renders with
Godot's built-in default font. These are the recommended, licence-clear
choices for when real fonts are added (both are SIL Open Font License
1.1, free for commercial use, no attribution required, both distributed
via Google Fonts):

| Role | Font | Licence | Used for |
|---|---|---|---|
| Display | **Oswald**, Bold/Heavy weight | SIL OFL 1.1 | Game logo, chapter headings, horde warnings, location names - see brief section 6: a distressed *look* comes from styling/texture applied to hero artwork, not from the interface typeface itself, since body/UI text must always stay in dynamic, screen-reader-friendly text controls, never baked into artwork |
| Interface | **Inter**, Regular/Medium/SemiBold | SIL OFL 1.1 | Buttons, task descriptions, item info, dialogue, menus, resource counters |

Typography rules already followed by every screen in this project (no
screen bakes UI text into an image; every label is a `Label`/`Button`
node driven by data): keep it that way as real fonts are added - swapping
the default font for Oswald/Inter is a `Theme` change in
`scripts/ui/theme_factory.gd`, not a per-screen rewrite.

## 4. Logo system

Source files: `assets/branding/logo/`.

| File | Use |
|---|---|
| `logo_horizontal_dark.svg` | Wide lockup on dark chrome (main menu, dark panels) |
| `logo_horizontal_light.svg` | Wide lockup on light/cream chrome (documents, store listing body copy) |
| `logo_stacked_dark.svg` | Square/tall lockup (splash screen, app-store icon composition) |
| `logo_icon_only.svg` | Mark alone, no wordmark (compact UI placements) - visually identical to `icon.svg` at the repo root, which is the actual Godot launcher icon and must stay there per `project.godot`'s `config/icon` setting |
| `logo_monochrome.svg` | Single-colour (`currentColor`) silhouette version for print/watermark/single-colour placements |
| `assets/branding/app_icon/notification_icon.svg` | Flat white silhouette on transparency, per Android's notification-icon requirements (the system tints/masks it itself - never a recolour of the full-colour launcher icon) |

Motif: a boarded-over doorway with warm light leaking through the gaps,
a lone Hollow silhouette outside in cool storm blue-grey - "damaged but
still standing," per brief section 7, without excessive blood. The
wordmark is "DEAD HAVEN" in a bold condensed treatment with a rust-orange
hazard-stripe underline (standing in for the "survival-warning detail"
the brief asks for) and "MERGE & SURVIVE" as the subtitle line.

Not yet produced: a real distressed/texture pass on the wordmark itself
(current SVGs use a subtle `feTurbulence` displacement filter as a
stand-in, not hand-painted wear), and a raster PNG export pass at
Android's required launcher-icon densities - both are Art Phase 1
finishing work, tracked in `assets/manifests/asset_manifest.json`.
