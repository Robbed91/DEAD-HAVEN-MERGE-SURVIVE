# Dead Haven: Merge & Survive — Art Bible

**Document status:** Production standard, version 1.0
**Date:** 31 July 2026
**Target:** Godot 4.3, Android, portrait 720 × 1280 design space
**Visual direction:** Original premium painterly 2.5D survival drama with strong mobile readability

## Purpose and authority

This document is the visual source of truth for all future artwork, UI skinning, animation, visual effects, and visual asset integration in **Dead Haven: Merge & Survive**. Gameplay code, IDs, progression, balancing, and save behaviour remain authoritative and must not be altered to satisfy an art preference.

The supplied montage is a **quality, mood, hierarchy, and finish benchmark only**. Its layout, characters, compositions, props, and screen designs must not be copied. Every production asset must be original to Dead Haven.

No bulk visual replacement may begin until a proposed asset batch has been checked against this bible. Where this bible conflicts with existing placeholder artwork, this bible governs the final artwork; where it conflicts with gameplay behaviour, gameplay behaviour governs.

## Creative north star

Dead Haven is a story about ordinary people building islands of warmth inside a hostile, rain-darkened world. The visual identity rests on five pillars:

1. **Warmth is earned.** Amber light identifies shelter, human connection, and progress; it is never sprayed across the whole screen.
2. **Danger has atmosphere, not gore.** Threat comes from weather, distance, silhouettes, damage, scarcity, and uneasy negative space.
3. **Everything tells a survival story.** Repairs, wear, improvised fasteners, handwritten labels, patched fabric, and reused materials reveal how people live.
4. **Clarity survives detail.** Shapes and values read immediately at phone size before the player notices painterly surface detail.
5. **People remain the emotional focus.** Environments establish stakes, items express progress, and characters provide meaning.

### Mandatory visual characteristics

- Stylised realism with painterly digital rendering.
- Consistent 2.5D depth and three-quarter construction.
- Clean, slightly exaggerated silhouettes designed for a phone.
- Restrained charcoal edge accents, not uniform cartoon outlines.
- Controlled material texture: weathered, tactile, and selective.
- Cool storm blue-grey surroundings contrasted with warm safe-haven amber.
- Cinematic but readable lighting with one clear focal hierarchy.
- Commercial Android-game polish at every interactive state.

### Prohibited visual characteristics

- Flat polygons, primitive geometric buildings, pixel art, emoji, or default Godot icons.
- Flat corporate-vector illustration or photographic collage.
- Generated text, signatures, watermarks, or logos embedded in illustration files.
- Copied characters, costumes, compositions, or recognisable likenesses from other games or television.
- Excessive gore, fetishised injury, or distress used as decoration.
- Uncontrolled texture noise, crushed shadows, bloom-heavy highlights, or muddy silhouettes.
- Static screenshots substituting for interactive screens.

---

## 1. Final colour palette

### 1.1 Canonical interface colours

These values match the existing theme constants and are the stable semantic anchors. Do not silently change their meaning during asset production.

| Token | Hex | Primary use |
|---|---:|---|
| Charcoal | `#1C1B1A` | Main frame, darkest panel, text shadow |
| Charcoal Light | `#2A2825` | Raised dark surfaces and inactive controls |
| Olive | `#6B7A56` | Positive action, progress, safe utility |
| Olive Dark | `#4D5940` | Pressed positive action, deep foliage |
| Rust | `#B5502B` | Primary brand accent and active navigation |
| Rust Light | `#CF6A3F` | Hover/selected edge, restrained highlight |
| Rust Dark | `#8A3C1F` | Pressed rust control and shaded paint |
| Cream | `#E8DCC5` | Primary light text and parchment highlight |
| Warning Red | `#B23A2E` | Danger, failure, urgent health state |
| Wood | `#6B4A35` | Timber, leather, structural secondary |
| Metal | `#8A8F8A` | Hardware, disabled neutral, cool reflection |
| Safe Amber | `#E2A24A` | Shelter light, reward focal point, hope |
| Storm Blue-grey | `#3C4650` | Exterior atmosphere and cool structural fill |
| High-contrast Black | `#000000` | Accessibility outline/background only |
| High-contrast White | `#FFFFFF` | Accessibility text/icon only |
| High-contrast Orange | `#FF8A3D` | Accessibility selection/action accent |

### 1.2 Illustration support ramps

These extend the canonical palette for painting. They do not replace code constants without a later, separately reviewed integration pass.

| Family | Shadow | Midtone | Light | Use |
|---|---:|---:|---:|---|
| Soot | `#111311` | `#202422` | `#343936` | Night structures, deep UI materials |
| Parchment | `#8E7C60` | `#C5B28F` | `#F0E6D0` | Notes, dialogue, item information |
| Timber | `#3F2C22` | `#72513A` | `#A77A50` | Reclaimed wood and warm interiors |
| Moss | `#303A2C` | `#586548` | `#83906A` | Vegetation, field equipment, safe utility |
| Storm | `#252D35` | `#59646D` | `#929BA0` | Sky, rain, distant metal, exterior fill |
| Ember | `#7E2F21` | `#C76034` | `#F0B45C` | Fire, reward spark, hot metal |
| Skin neutral | `#5A372C` | `#A86E53` | `#DBA17B` | One range among several; never a universal skin ramp |

Skin must be painted from character-specific reference swatches covering the full intended cast. The example neutral ramp is a material example, not a limit on complexion.

### 1.3 Colour hierarchy

- A typical exterior frame is approximately **70% cool/dark field, 20% neutral material, and 10% warm or saturated accent**.
- A safe interior may reach 25–35% warm light, but shadows remain cool-neutral to preserve depth.
- Only one element per panel should carry the strongest amber or rust emphasis.
- Warning red is reserved for real danger, damage, invalid actions, and destructive confirmation.
- Olive communicates achievable, constructive action. Do not use it for locked or unaffordable controls.
- Colour never carries state alone. Pair it with silhouette, icon, label, border, or motion.
- At final phone-size review, primary text and essential icons must meet WCAG-style contrast targets: 4.5:1 for normal text and 3:1 for large text or meaningful graphical controls.

### 1.4 Value discipline

Every illustration must remain legible in greyscale. Use three primary value groups:

1. Dark frame/background mass.
2. Mid-value playable or narrative subject.
3. Small light focal accents.

If a subject disappears when viewed at 25% scale or in greyscale, fix value separation before adding saturation or outlines.

---

## 2. Typography rules

### 2.1 Approved families

| Role | Family | Approved weights | Licence |
|---|---|---|---|
| Display, screen titles, short buttons | **Oswald** | 500, 600, 700 | SIL Open Font License 1.1 |
| Body, labels, counters, dialogue | **Inter** | 400, 500, 600, 700 | SIL Open Font License 1.1 |

Licence sources: [Oswald OFL](https://github.com/google/fonts/blob/main/ofl/oswald/OFL.txt) and [Inter OFL](https://github.com/google/fonts/blob/main/ofl/inter/OFL.txt). A verbatim copy of each applicable OFL file must ship beside the font sources under `assets/fonts/licenses/`. Preserve copyright and licence notices whenever fonts are redistributed or modified. Renamed modified versions must follow the OFL reserved-font-name conditions, if any.

### 2.2 Type scale at the 720 × 1280 logical design size

| Style | Font | Size | Weight | Line height | Use |
|---|---|---:|---:|---:|---|
| Hero display | Oswald | 48–56 | 700 | 1.00–1.08 | Title screen only |
| Screen title | Oswald | 32–38 | 600–700 | 1.05–1.12 | Major screen heading |
| Panel title | Oswald | 26–30 | 600 | 1.10–1.18 | Cards and sections |
| Action label | Oswald | 22–26 | 600 | 1.00 | Short button text |
| Body | Inter | 22–26 | 400–500 | 1.25–1.38 | Description and dialogue |
| UI label | Inter | 20–24 | 500–600 | 1.15–1.25 | Resources, tabs, fields |
| Caption | Inter | 18–20 | 500 | 1.20–1.30 | Secondary metadata only |
| Numeric emphasis | Inter | 24–30 | 600–700 | 1.00 | Currency, energy, level |

At the 405 × 720 desktop preview, validate the final rendered result rather than manually halving type sizes; Godot scaling must preserve the logical design. No essential text may render below a visually equivalent 12 px on the target device.

### 2.3 Composition rules

- Use uppercase Oswald only for short headings, compact tabs, and action verbs. Do not set paragraphs in uppercase.
- Use sentence case for dialogue, item descriptions, quests, and explanatory labels.
- Limit centered text to titles, empty states, and short confirmations. Left-align reading content.
- Allow 3–5% tracking for uppercase headings; keep body tracking neutral.
- Use tabular numerals for changing resource counters when the font build supports them.
- Do not rasterise or generate words into illustrations. All player-facing text remains live Godot text for localisation and accessibility.
- Use a one-pixel dark keyline or restrained shadow only where the background cannot guarantee contrast. Avoid multi-layer glow text.
- Truncation is a last resort. Components must first support wrapping, dynamic width, and localisation expansion of at least 30%.

---

## 3. UI material rules

The interface should resemble durable objects assembled by survivors, refined into a coherent premium system. It must feel tactile without becoming a literal scrapbook.

### 3.1 Material families

| Material | Function | Treatment |
|---|---|---|
| Aged iron | Global chrome, modal frames, top and bottom bars | Charcoal base, subtle brushed grain, worn edge, cool highlight |
| Reclaimed timber | Structural accent and category framing | Directional grain, repaired joins, low saturation, no busy knots behind text |
| Waxed parchment | Dialogue, item detail, narrative cards | Warm neutral, soft fibre, dark ink text, lightly distressed perimeter |
| Painted field metal | Buttons, counters, utility tabs | Olive/rust enamel with edge chips limited to non-text zones |
| Glass and instrument lens | Currency and status accents | Small controlled specular reflection; never broad glossy web styling |

### 3.2 Geometry and depth

- Primary panel corner radius: 8–12 logical px. Compact control radius: 6–9 px.
- Panel border: 2–3 px; selected or focused border: up to 4 px.
- Outer shadow: 4–10 px soft falloff at 20–35% opacity. Avoid pure black cut-out shadows.
- Inner bevel: 1–2 px with a cool top edge and dark lower edge. Keep highlights quieter than text.
- Use 9-slice textures for resizable frames and buttons. The protected corners must contain all painted wear and fasteners.
- Decorative bolts, tape, and chips may never collide with labels or reduce the tappable silhouette.
- Minimum touch target: 64 × 64 logical px. A small visible icon may sit inside that target.
- Global screen margins: 20–28 logical px; compact card gutters: 12–18 px.

### 3.3 Interaction states

| State | Required visual response | Motion/audio hand-off |
|---|---|---|
| Normal | Stable material and clear label | None |
| Pressed | 3–5% darkening, 1–2 px inward displacement, compressed highlight | 60–100 ms tactile tick |
| Selected | Rust-light or amber keyline plus persistent shape marker | 160–220 ms settle |
| Focused | High-contrast outline outside normal silhouette | No pulsing by default |
| Disabled | Desaturated by 55–70%, reduced contrast, still legible | No confirm sound |
| Locked | Disabled treatment plus explicit lock icon and requirement | Short blocked response |
| Affordable | Olive action surface and readable cost | Positive tap response |
| Unaffordable | Neutral dark surface, warning cost, no deceptive green | Blocked response |
| Success | Olive/amber confirmation, check silhouette | Restrained positive accent |
| Danger | Warning-red edge and explicit warning icon | Low, short alert |

### 3.4 Screen hierarchy

- Preserve the existing interactive screen structure. Artwork skins components; it does not replace screens with a single image.
- The top resource bar and bottom navigation are stable anchors and should have quieter texture than content panels.
- Current objective, primary action, and blocking condition must be identifiable within one second.
- Use no more than three panel depth levels in one view.
- Use illustration behind text only when a dedicated darkening or parchment field guarantees readability.

---

## 4. Environment perspective guide

### 4.1 Camera language

- Use a consistent three-quarter construction with believable depth, not strict isometric projection.
- Exterior locations: eye-level to mildly elevated camera, approximately 10–20° downward pitch. Show a dominant front plane and one side plane.
- Interior rooms and tactical maps: approximately 20–30° downward pitch so floor routes and usable objects remain visible.
- Avoid wide-angle distortion. Vertical architecture should remain vertical except for subtle intentional perspective convergence.
- Place the horizon around 25–38% from the top for exterior gameplay views, adjusted only to preserve the primary interaction zone.
- The portrait composition must lead from foreground context through the playable middle plane to atmospheric story depth.

### 4.2 Scale and staging

- Establish a character-height yardstick for each location before painting props.
- Doors, stairs, windows, vehicles, and furniture must maintain believable scale across progression stages.
- Keep interactive hotspots separated by silhouette and at least 16–24 logical px of visual breathing room at final size.
- Foreground framing may overlap scenery but must not cover interaction labels, quest markers, or navigation.
- Use leading lines, pools of light, and material contrast to guide the eye; do not use arbitrary glowing outlines on every object.

### 4.3 Mandatory layer stack

Environment masters must be delivered as separable layers where applicable:

1. Far sky and atmospheric gradient.
2. Distant silhouettes and terrain.
3. Main structure shell.
4. Doors, windows, roof, and architectural states.
5. Furniture and large props.
6. Damage, repairs, barricades, and progression overlays.
7. Interactive hotspot objects and masks.
8. Character placement plane.
9. Foreground occlusion.
10. Lighting, weather, fog, and particle overlays.

The final exported layer count should be the minimum needed for state changes, animation, and parallax. Never flatten a required interactive or progression state into an unusable background.

### 4.4 Detail distribution

- Largest shapes communicate location; medium shapes communicate function; small texture communicates history.
- Reserve the sharpest detail and warmest local contrast for interactive or narrative focal areas.
- Reduce saturation, contrast, and edge sharpness with distance.
- Weathering follows construction: streaks below fasteners, wear at touch points, moisture at ground contact, sun fade on exposed surfaces.
- Repeated props must vary in rotation, repair, colour temperature, and damage without breaking their item identity.

---

## 5. Merge-item perspective guide

### 5.1 Camera, silhouette, and framing

- Use a three-quarter elevated view, approximately 25–35° downward, with the object turned 15–30° to reveal its defining front and side planes.
- All chain members share the same camera height, lens feel, ground relationship, and top-left key light.
- The object should occupy 72–82% of the square canvas, with at least 10–12% transparent safety padding.
- Deliver on transparent background with clean premultiplied-alpha-safe edges. Do not include a square painted tile or accidental matte.
- A restrained, soft contact shadow may be included on its own separated layer or in the item export if the runtime system requires one consistent sprite.
- No labels, numbers, letters, logos, or generated text inside the item image.

### 5.2 Readability and progression

- At 64 px, the item must remain recognisable by outer contour and one signature internal feature.
- Each merge level must change at least two of: silhouette, scale, assembly complexity, material, or signature detail.
- Do not communicate level through colour alone.
- Early levels are single, scavenged components; middle levels show useful assembly; late levels feel engineered, repaired, and valuable.
- Producers need a distinct footprint and visual weight but must remain compatible with the grid.
- Keep micro-detail away from the silhouette edge so transparency does not shimmer when scaled.

### 5.3 Material response

| Material | Signature treatment |
|---|---|
| Wood | Broad grain planes, chipped edges, warm highlight, cool crevice |
| Metal | Controlled edge glint, oxidation patches, no mirror chrome |
| Fabric | Large fold groups and frayed accents, not noisy fibre everywhere |
| Plastic | Muted colour, broad soft highlight, scratched high-contact zones |
| Glass/liquid | Dark boundary, one clear highlight, readable fill level |
| Medical | Cleaner value structure with restrained sterile highlight |
| Food/supplies | Recognisable packaging shape without real-world branding or text |

### 5.4 Master and runtime sizes

- Paint master: 512 × 512 RGBA, layered source retained.
- Standard runtime item: 128 × 128 RGBA.
- Small UI derivative: 64 × 64, manually reviewed and sharpened—not blindly downscaled.
- Hero/reward derivative: 256 × 256 when prominently displayed.

---

## 6. Character proportion guide

### 6.1 Core proportions

- Adults: approximately 7.25–7.75 heads tall, varied naturally by age and build.
- Older teens: approximately 7–7.5 heads; children only where narratively necessary and never used as decorative jeopardy.
- Slightly enlarge hands, carried tools, and distinctive equipment by 5–10% for phone readability.
- Heads may be 3–5% larger than strict realism, especially in full-body gameplay views.
- Keep feet planted and weight believable. Avoid fashion-pose contrapposto during danger or labour.
- Preserve diversity in height, body mass, mobility, age, skin tone, facial structure, and lived experience.
- Clothing is layered, practical, repaired, and character-specific. Avoid sexualised damage or generic apocalypse cosplay.

### 6.2 Silhouette construction

Every major survivor needs three recognisable identifiers:

1. Body or posture silhouette.
2. Hair/headwear silhouette.
3. Tool, garment, or carried-object silhouette.

These identifiers must survive a black-fill test at 96 px. Background characters can be simpler but may not become interchangeable shadow people when they are named or interactive.

### 6.3 Portrait system

- Framing: chest-up or shoulder-up, three-quarter view, eye line in the upper 40%.
- Default gaze is slightly toward the interface content or conversation partner, not always directly at camera.
- Use a consistent neutral pose and crop across the roster.
- Required expression set for principal characters: neutral, hopeful, concerned, determined, relieved, tired, angry, frightened, injured, grieving, suspicious, and smiling.
- Expression changes involve brows, eyelids, cheek tension, mouth shape, head angle, and shoulder tension—not mouth swaps alone.
- Portrait master: minimum 1024 × 1024 layered RGBA. Runtime target: 512 × 512 or lower only after phone-size review.

### 6.4 Full-body and layered delivery

- Full-body master: 1600–2400 px tall, depending on animation and crop needs.
- Separate, when animation requires: head/hair rear, torso, near/far upper arm, near/far forearm, hand/tool, near/far thigh, near/far shin/foot, foreground accessories, and shadow.
- Joints must include enough overlap beneath adjacent pieces to avoid gaps during motion.
- Injury variants should show dirt, fatigue, bandaging, guarded posture, and controlled blood only where story-relevant.

---

## 7. Character lighting guide

### 7.1 Neutral production lighting

- Primary key: upper-left, 35–45° elevation, broad but directional.
- Key-to-fill value relationship: approximately 3:1 for standard portraits; reduce to 2:1 for small thumbnails.
- Key colour is a muted warm neutral; fill is cool storm blue-grey.
- Use a restrained rim only when required to separate dark hair or clothing. It must come from a plausible environmental source.
- Maintain catchlight and eye-socket readability without beauty-light flattening.
- Keep skin chroma alive in shadow; do not grey or purple every complexion with the same overlay.

### 7.2 Environmental adaptation

- Safe haven: warm lateral lantern/window key, cool night fill, amber reflected light under chin and hands.
- Exterior storm: broad cold skylight, small warm practical accent, moist edge highlights only on exposed planes.
- Fire or emergency light: flicker affects value and hue subtly; it does not turn the entire face orange or red.
- Medical interior: pale directional work light with cooler shadows, avoiding horror-green skin.
- Dawn escape: cool ambient field with a narrow warm horizon rim.

Characters must feel present in the scene. Match contact shadow, colour bounce, edge softness, weather effects, and grain to the environment during compositing.

---

## 8. Environment lighting guide

### 8.1 Global principles

- Begin with a three-value lighting thumbnail before colour painting.
- Every scene has one dominant light story and no more than two supporting practical sources.
- Warm light marks safety, work, memory, or a navigable goal. Cold light marks exposure, distance, weather, uncertainty, or mechanical threat.
- Preserve readable darks. Pure black is reserved for the deepest occlusion and accessibility backgrounds.
- Bloom is a small halo around the brightest practicals, never a global haze.
- Fog separates planes and reveals depth; it may not wash out interactive silhouettes.

### 8.2 Location signatures

| Location/screen | Time and atmosphere | Light signature | Emotional purpose |
|---|---|---|---|
| Main menu / haven gate | Rainy blue dusk | Gate lamps and distant refuge amber | Threat outside, possibility inside |
| Hollow Creek Farmhouse | Storm afternoon moving into dusk | Cool overcast field, hearth/window amber | Fragile first shelter |
| Redwater district | Rust-red industrial dusk | Sodium practicals against smoke-blue ambient | Scarcity and unstable machinery |
| Greybridge | Heavy overcast / early night | Steel-blue ambient with isolated radio and work lights | Distance, communication, exposure |
| Saint Mercy | Deep night | Controlled emergency-white and muted amber care zones | Tension, triage, moral responsibility |
| Northgate | Pre-dawn | Blue-black field, searchlight cuts, restrained rose horizon | Final risk and forward motion |
| World map | Neutral storm daylight | Soft top-left relief light, warmer discovered routes | Legibility and strategic scale |
| Merge board | Sheltered worktable light | Warm focused key, cooler edges, quiet background | Concentration and progress |

### 8.3 Progression lighting

Residence upgrades should improve lighting through believable new sources: repaired windows, fuelled lamps, cleared soot, powered fixtures, reflective clean surfaces, and opened sightlines. Do not merely increase global exposure. The haven becomes warmer and more organised while the exterior retains its dangerous cool field.

---

## 9. Visual-effect guide

VFX must explain an action, reward progress, or strengthen atmosphere. Effects cannot conceal board state or compensate for unclear artwork.

### 9.1 Effect language

| Event | Core effect | Colour/material cue | Target duration |
|---|---|---|---:|
| Valid selection | Tight outline sweep and small lift shadow | Amber/cream | 0.18–0.26 s |
| Invalid action | Short lateral nudge and dry dust tick | Rust/warning red | 0.12–0.18 s |
| Standard merge | Inward pull, material flecks, compact flash, settle | Chain-specific | 0.32–0.42 s |
| High-level merge | Standard merge plus restrained radial accent | Amber with material colour | 0.55–0.80 s |
| Producer payout | Object recoil, item arc, small landing dust | Material-specific | 0.45–0.70 s |
| Quest complete | Check stroke, warm line burst, subtle motes | Olive/amber | 0.60–0.90 s |
| Residence repair | Dust fall, fastening sparks, light ignition | Wood/metal/amber | 0.80–1.40 s |
| Damage | Directional impact, debris, brief value dip | Material colour, limited red | 0.20–0.45 s |
| Reward reveal | Backplate glow, upward motes, controlled shine | Cream/amber | 0.70–1.00 s |
| Rain/fog | Layered directional rain and slow depth fog | Storm ramp | Continuous |

### 9.2 Chain-specific merge accents

- Wood: short splinters, sawdust, warm fibre flash.
- Metal/tools: two or three sharp sparks, tiny filings, cool glint.
- Fabric/rope: thread curl, soft fibre puff, no glitter.
- Food/supplies: paper crumb or packaging snap, muted highlight.
- Liquid/fuel: curved glint, one or two droplets, sealed-container emphasis.
- Medical: clean cross-shaped glint without embedding a text character, soft white-blue flare.
- Vehicle: mechanical alignment, bolt spin, restrained headlamp pulse at high level.

### 9.3 Performance and comfort

- Typical merge effect: 8–18 particles; hero event: no more than 30 visible particles without profiling.
- Prefer pooled GPU particles, short sprite sheets, and additive blending only for small emissive elements.
- Avoid full-screen white flashes. Peak overlay opacity should normally remain below 35%.
- Particle sprites should be 64–256 px; atlases no larger than 2048 × 2048 at runtime.
- Low-quality mode halves particle count, disables expensive distortion, and reduces weather layers.
- Reduced-motion mode replaces scale, shake, parallax, and particle bursts with a ≤150 ms opacity/outline confirmation.

---

## 10. Animation timing guide

Author timings in seconds and preview at both 60 fps and 30 fps. Input response begins on press; confirmation may complete on release.

### 10.1 Timing library

| Motion | Timing | Easing / notes |
|---|---:|---|
| Button press | 0.08–0.12 s | Ease out; return with slight ease in-out |
| Tab change | 0.16–0.22 s | Crossfade plus ≤8 px slide |
| Panel enter | 0.18–0.24 s | Cubic ease out; no bounce |
| Modal enter | 0.20–0.28 s | Fade and 96→100% scale |
| Modal exit | 0.14–0.20 s | Quadratic ease in |
| Item select | 0.18–0.26 s | Lift 4–7%, shadow expands |
| Invalid item | 0.12–0.18 s | Two tight offsets; no prolonged shake |
| Merge anticipation | 0.06–0.10 s | Brief inward compression |
| Merge impact | 0.08–0.12 s | Fast material burst |
| Merge settle | 0.16–0.22 s | Overshoot limited to 104–107% |
| Producer cycle | 0.55–0.80 s | Anticipate, recoil, dispense, settle |
| Discovery reveal | 0.70–1.00 s | Silhouette-to-colour with focal light |
| Hotspot action | 0.70–1.20 s | Readable action loop, then state update |
| Major residence beat | 2.5–4.0 s | Multi-stage reveal, skippable after first view |
| Portrait blink | 0.12–0.18 s | Random interval 3–7 s; never synchronised |
| Idle breathing | 2.8–4.0 s | 1–2% movement, asymmetrical secondary motion |
| Scene fade | 0.16–0.22 s | Preserve current responsiveness target |

### 10.2 Motion principles

- Functional motion is fast and direct; narrative motion may breathe.
- Anticipation should be visible but never delay input recognition.
- Use overshoot for reward and physical settle, not for every panel.
- Heavy objects move fewer pixels and settle slowly; light objects travel farther and settle quickly.
- Camera shake is reserved for significant impact, limited to 2–6 logical px and 0.10–0.25 s.
- Looping environmental animation must vary phase and amplitude to avoid mechanical repetition.
- All non-essential looping animation pauses when off-screen or the application is backgrounded.

### 10.3 Reduced-motion standard

Reduced-motion mode disables camera shake, large scale changes, parallax, repeated pulses, and dense particle motion. Confirmations use a short opacity, border, or colour-state change of 0.15 s or less. Narrative sequences retain state clarity and provide an immediate completion path.

---

## 11. Icon-design guide

### 11.1 Construction

- Create a bespoke Dead Haven icon family. Emoji and default engine icons are prohibited in final UI.
- Design on a 128 × 128 master grid with an 8 px safety boundary.
- Target silhouettes: 24, 32, 48, and 64 logical px. Review each size manually.
- At 64 px, major stroke weight should read as approximately 2.5–3.5 px after export.
- Use rounded joins where metal or painted signage requires friendliness; use sharper joins for danger and damaged materials.
- Maximum internal detail: two or three meaningful cuts at 32 px. Remove decorative scratches that collapse into noise.
- Use top-left light and lower-right weight consistent with item art, but keep navigation icons flatter and simpler than merge items.
- Maintain consistent optical mass. A narrow wrench and a broad backpack should feel equally prominent inside their boxes.

### 11.2 Semantic families

| Family | Examples | Treatment |
|---|---|---|
| Navigation | Haven, Merge, Map, Survivors, Inventory | Cream/metal base, rust selected state |
| Resources | Energy, coin, premium currency, level | Distinct silhouette and stable colour identity |
| Status | Health, hunger, repair, timer, danger | Compact, high contrast, paired with text/value |
| Actions | Confirm, cancel, back, inspect, craft, collect | Verb-first silhouette, no ambiguous decoration |
| Map | Location, route, locked, completed, encounter | Clear pin/building silhouettes with explicit state badge |
| Accessibility | Audio, music, motion, contrast | Familiar platform conventions redrawn in house style |

Locked icons are desaturated and paired with an explicit lock silhouette. Completion uses a check shape plus olive/amber treatment. Never rely on a hue shift alone.

### 11.3 Export

- Preferred source: SVG for simple UI symbols; layered raster for painterly resource and item icons.
- Raster exports: 256 × 256 master derivative, 128 × 128 standard, 64 × 64 compact.
- Keep icon and badge separate when the badge count changes at runtime.
- No baked shadows outside the declared icon bounds.

---

## 12. Android texture-size guide

### 12.1 Runtime targets

| Asset class | Source master | Typical runtime | Alpha | Notes |
|---|---:|---:|---|---|
| Full-screen environment | 1440 × 2560 or larger layered source | 720 × 1280 or split layers ≤2048 edge | As needed | Avoid shipping a 4K flat image for a 720p view |
| Large environment layer | 2048–4096 working edge | ≤2048 runtime edge | Usually | Crop transparent dead space |
| Character portrait | 1024 × 1024 | 512 × 512; 256 for compact cards | Yes | Preserve face and hair alpha |
| Full-body character | 1600–2400 px tall | ≤2048 atlas edge per set | Yes | Split animation sets when necessary |
| Merge item | 512 × 512 | 128 × 128; 256 hero | Yes | Manually reviewed 64 px derivative |
| UI icon | SVG or 256 × 256 | 64–128 | Yes | Prefer vector source for simple symbols |
| 9-slice UI panel | 256–512 working edge | Smallest clean 9-slice | Yes/No | Protect corners and edge wear |
| VFX sprite/atlas | 256–512 per element | Atlas ≤2048 × 2048 | Yes | Trim frames and reuse materials |
| Map tile/illustration | 1440 × 2560 source | 720 × 1280 or tiled ≤1024 | As needed | Profile zoom and panning |

### 12.2 Import and compression

- Use ETC2/ASTC-compatible Android imports already supported by the project.
- Use lossless or high-quality alpha compression for UI, icons, portraits, item silhouettes, and VFX with critical edges.
- Opaque painted backgrounds may use carefully reviewed lossy compression; reject visible blocking in skies, fog, gradients, and faces.
- Filtering is enabled for painterly artwork. Nearest-neighbour sampling is prohibited for final art.
- Disable mipmaps for fixed-size UI and unscaled sprites. Enable them only for textures that materially scale down or recede in scene depth.
- Set repeat only for deliberately tileable textures. Edge padding must prevent atlas bleed.
- Use sRGB for colour textures. Masks, data maps, and normal maps must use the correct non-colour import setting.

### 12.3 Memory and draw discipline

- Low-tier visual texture working-set target: **≤64 MB per major screen**.
- Standard-tier target: **≤128 MB per major screen**.
- High-quality tier may reach **≤192 MB** only when profiling confirms stable performance and memory headroom.
- Standard runtime texture edge should not exceed 2048 px. A 4096 px source is an authoring master, not an automatic shipping asset.
- Atlas small items and icons by usage locality, not into one global atlas that keeps every screen resident.
- Separate frequently changing or animated layers from static backgrounds to avoid oversized redraw and memory cost.
- Profile on a representative lower-mid Android device at 30 fps and a target device at 60 fps. Check cold load, repeated screen switching, background/resume, thermal behaviour, and peak memory.

### 12.4 Quality tiers

| Feature | Low | Standard | High |
|---|---|---|---|
| Environment scale | 0.75× where acceptable | 1.0× design resolution | 1.0× plus selected high-detail layers |
| Particles | 50% count | 100% count | Up to 125% after profiling |
| Weather layers | 1 | 2 | 2–3 |
| Parallax | Off/minimal | Standard | Standard plus foreground depth |
| Distortion | Off | Selective | Selective, never global |
| Character idle | Essential only | Full | Full plus secondary detail |

---

## 13. Asset naming rules

### 13.1 General syntax

- Use lowercase `snake_case` ASCII names.
- Never use spaces, dates, personal names, `final`, `new`, `copy`, or undocumented abbreviations.
- Use zero-padded numeric levels and frames: `l01`, `f003`.
- Use three-digit revisions only in authoring/output hand-off when needed: `v001`.
- Godot-facing stable asset IDs must remain unchanged where already referenced. Filename migration requires a mapped integration task, never an ad hoc rename.

### 13.2 Patterns

| Asset type | Pattern | Example |
|---|---|---|
| Environment | `env_<location>_<stage>_<layer>_<state>_v###` | `env_hollow_creek_s02_structure_repaired_v001.png` |
| Character portrait | `chr_<id>_<outfit>_<expression>_<view>_v###` | `chr_mara_field_concerned_threeq_v001.png` |
| Character body | `chr_<id>_<outfit>_<action>_<part>_v###` | `chr_mara_field_idle_forearm_near_v001.png` |
| Merge item | `item_<chain>_l##_<state>_v###` | `item_wood_l03_normal_v001.png` |
| Producer | `producer_<family>_l##_<state>_v###` | `producer_workbench_l02_active_v001.png` |
| UI component | `ui_<component>_<material>_<state>_v###` | `ui_button_metal_olive_pressed_v001.png` |
| Icon | `icon_<family>_<name>_<state>_v###` | `icon_nav_haven_selected_v001.svg` |
| VFX | `vfx_<system>_<variant>_f###_v###` | `vfx_merge_wood_f006_v001.png` |
| Animation | `anim_<actor_or_system>_<action>_<variant>` | `anim_survivor_idle_tired` |
| Music | `music_<context>_<intensity>_<version>` | `music_haven_night_calm_v001.ogg` |
| Ambience | `amb_<location>_<time>_<layer>` | `amb_hollow_creek_dusk_rain.ogg` |
| Sound effect | `sfx_<system>_<action>_<material>_<variant>` | `sfx_merge_impact_wood_01.ogg` |

### 13.3 Source and export structure

- Layered source: `art_source/<asset_class>/<group>/...`
- Reviewed game asset: `assets/<asset_class>/<group>/...`
- Reference sheet: `assets/reference/<discipline>/...`
- Licence material: `assets/licenses/...` or the specific family licence directory.
- Do not import layered PSD/Krita working files into the runtime project unless the pipeline explicitly requires them.

---

## 14. Reference sheets for final consistency

The following sheets are mandatory production deliverables. Until image sheets are commissioned, the tables below are their binding written specification.

### 14.1 Palette and material sheet

**File target:** `assets/reference/style/ref_palette_materials_v001.png`

Must show canonical colours, illustration ramps, aged iron, reclaimed timber, parchment, painted metal, fabric, wet road, oxidised metal, skin under warm/cool light, and approved edge treatment. Each swatch appears in light, midtone, shadow, wet, and worn states without embedded generated text; labels belong in a separate production document or live layout.

### 14.2 UI component sheet

**File target:** `assets/reference/ui/ref_ui_components_v001.png`

Must show one coherent set of: top bar, bottom navigation, panel, modal, parchment card, button, compact icon button, resource counter, progress bar, tab, badge, lock, tooltip, dialogue box, and toast. Each interactive control displays normal, pressed, selected/focused, disabled, locked, affordable, and unaffordable states.

### 14.3 Environment perspective sheet

**File target:** `assets/reference/environment/ref_environment_perspective_v001.png`

Must show the same simple original structure in exterior three-quarter, interior elevated three-quarter, and world-map views, with horizon, verticals, character scale, interaction plane, foreground occlusion, and layer separation clearly demonstrated.

### 14.4 Location lighting sheet

**File target:** `assets/reference/environment/ref_location_lighting_v001.png`

Must compare original thumbnails for the main menu, Hollow Creek, Redwater, Greybridge, Saint Mercy, Northgate, map, and merge board. Each thumbnail is first approved in greyscale and then in colour.

### 14.5 Merge-chain sheet

**File target:** `assets/reference/items/ref_merge_chains_v001.png`

Must show at least one complete original chain each for wood, metal/tools, fabric, food/supplies, medical, fuel/liquid, and vehicle parts. Include 64 px and 128 px views, consistent perspective, silhouette tests, contact shadows, and one producer.

### 14.6 Character identity sheet

**File target:** `assets/reference/characters/ref_character_identity_v001.png`

Must show the principal cast in neutral turnaround or three-quarter construction, black silhouettes, height comparison, skin swatches, outfit materials, signature props, and portrait crops. Differences must come from anatomy, age, posture, clothing, and lived history—not token colour swaps.

### 14.7 Expression and lighting sheet

**File target:** `assets/reference/characters/ref_expression_lighting_v001.png`

Must show the required 12-expression set on one approved principal character and compare neutral, haven, storm, emergency, and dawn lighting without changing identity or skin tone.

### 14.8 VFX and motion sheet

**File target:** `assets/reference/vfx/ref_vfx_motion_v001.png`

Must show key frames for selection, invalid action, standard merge, high-level merge, producer payout, quest completion, repair, damage, reward, rain, and fog. Include standard and reduced-motion outcomes.

### 14.9 Android export sheet

**File target:** `assets/reference/technical/ref_android_exports_v001.png`

Must compare source, 256 px, 128 px, 64 px, compressed standard, and compressed low-tier output for one portrait, item, icon, UI panel, and fog gradient. This is the visual acceptance benchmark for import settings.

### 14.10 Approval checklist for every reference sheet

- Original work; no copied compositions, characters, or brand elements.
- No baked text, generated lettering, signatures, or watermarks.
- Correct palette, perspective, lighting direction, and material response.
- Readable at 405 × 720 preview and representative physical phone size.
- Clear greyscale hierarchy and colour-blind-safe state differentiation.
- Required layers and transparency confirmed.
- Android compression test passed without halos, banding, or unreadable detail.
- Stable existing asset IDs and gameplay bindings documented before integration.

---

## Production reference prompts

These prompts describe the shared visual grammar. They are starting constraints, not substitutes for composition briefs or human review.

### Environment master prompt

> Original Dead Haven survival environment, premium painterly 2.5D mobile-game illustration, stylised realism, consistent three-quarter perspective, strong phone-readable architecture and interaction silhouettes, detailed reclaimed and weathered materials, restrained charcoal edge accents, cool storm blue-grey atmosphere contrasted with a small earned safe-haven amber focal light, cinematic depth, controlled texture, layered for state changes and subtle animation, no people unless specified, no text, no logos, no watermark, no photographic collage, no flat polygons, no pixel art.

### Merge-item master prompt

> Original Dead Haven merge item, single isolated survival object in consistent elevated three-quarter view, premium painterly stylised realism, clean mobile-readable silhouette, slightly exaggerated defining features, top-left warm-neutral key and cool fill, detailed weathered material with controlled texture, transparent background, generous edge padding, no label, no letters, no logo, no watermark, no flat vector art, no pixel art.

### Character master prompt

> Original Dead Haven survivor, premium painterly 2.5D stylised realism, distinctive believable anatomy and silhouette, practical layered repaired clothing, character-driven expression, slightly exaggerated hands and signature equipment for phone readability, warm-neutral upper-left key and cool storm fill, restrained charcoal edge accents, controlled texture, transparent background, no celebrity or existing-character likeness, no logo, no text, no watermark, no excessive gore.

All generated or commissioned work requires visual review for anatomy, unintended symbols, accidental lettering, similarity risk, and consistency. A prompt never constitutes approval.

---

## Review gates and definition of done

### Gate A — Direction

- Thumbnail reads at phone size.
- Original composition supports the existing screen function.
- Perspective, value hierarchy, and focal warmth are approved.

### Gate B — Production master

- Material, anatomy, lighting, and narrative detail meet this bible.
- Required layers, states, and transparent edges are present.
- No generated text, watermarks, copied likeness, or prohibited style.

### Gate C — Integration proof

- Asset is tested inside the real interactive Godot screen.
- Buttons, hotspots, labels, and state changes remain functional.
- No IDs, save behaviour, progression, or gameplay logic changed.
- 405 × 720 preview and 720 × 1280 design view both pass readability review.

### Gate D — Android acceptance

- Texture import, memory, frame pacing, load time, and app resume are profiled.
- Alpha edges, gradients, portraits, and small icons survive device compression.
- Standard, low-quality, high-contrast, and reduced-motion states are checked where applicable.

An asset is final only when it passes all applicable gates, is entered in the asset manifest, has its source and licence provenance recorded, and replaces the intended placeholder without changing gameplay behaviour.

## Current production hold

This art bible completes the required visual direction phase. It does **not** authorise indiscriminate or bulk replacement. The next permitted step is a small representative vertical slice—one environment panel, one character portrait, one merge chain, and one UI component family—reviewed against the reference sheets and gates above before broader production begins.
