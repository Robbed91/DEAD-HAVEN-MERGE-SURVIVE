# Dead Haven: Merge & Survive — Visual Replacement Plan

This plan follows the audit at commit
`4d93ff297290ce0a625f45b0612cd011a17f213b`. It does not authorize gameplay
redesign. The complete gameplay implementation remains the source of truth.

## Non-negotiable integration rules

1. Keep every gameplay ID, resource definition, quest requirement, residence
   order, board coordinate, save key and balance value unchanged.
2. Keep interactive screens live. Never replace a screen with a flattened image.
3. Preserve node names referenced through `%Name`, signals, public methods and
   scene-router keys unless an equivalent visual wrapper preserves the contract.
4. Treat art as layered content beneath/above existing interaction nodes.
5. Add code only to select visual states, play animation/VFX/audio, adapt layout,
   expose accessibility settings or reduce mobile cost.
6. Run the full smoke suite and capture affected screens after every integration
   batch. Compare behavior against the baseline screenshots in
   `docs/visual-audit-screenshots/`.

## Visual target

Use the supplied reference as a quality and rendering benchmark, not as a layout
or IP template. Dead Haven's original art direction should use:

- hand-painted 2D mobile illustration with broad readable planes;
- dark aged metal/wood framing and parchment information surfaces;
- chunky illustrated objects that remain legible at 64–128 px;
- condensed display headings with clear body text;
- desaturated earth/olive/charcoal materials, warm amber shelter light and cool
  storm-blue exteriors;
- layered depth, atmospheric dusk/night lighting and restrained survival wear;
- original Dead Haven characters, buildings, icons, layouts and branding.

## Phase 0 — Lock contracts and production templates

Deliverables:

- Record node/signal/state contracts for every target scene.
- Establish font licenses and import settings.
- Build reusable nine-slice dark-chrome, parchment, button, card, meter and icon
  templates at 1×/2× source scale.
- Define texture budgets, compression presets and atlas rules.
- Produce one approved UI component sheet, one item-icon sample chain, one
  survivor portrait sample and one residence layer test before batch work.

Gate: no gameplay diff; all 14 tests pass; 405×720 and 720×1280 previews readable.

## Phase 1 — Shared shell and critical UI skin

Order:

1. Typography and `ThemeFactory` states.
2. Top resource bar with owned icons and meters.
3. Bottom navigation with owned tab icons.
4. Buttons, cards, panels, sliders, checkboxes, option menus and progress bars.
5. Task, item-info, storage, discovery and toast components.

Why first: these components appear on almost every later screenshot. Skinning
them once prevents environment/character reviews being polluted by default UI.

Gate: no emoji remain in production UI; touch targets stay at least 64 logical
pixels; high-contrast/color-blind/reduced-motion settings still function.

## Phase 2 — Core vertical slice: Haven + merge board

### Hollow Creek

- Produce layered Stage 1–5 exterior art: sky/distance, structure, furniture,
  damage/debris, interactive repair layers, characters, foreground, lighting,
  weather and particles.
- Produce before/after visuals for all nine Hollow Creek hotspots.
- Keep existing normalized hotspot coordinates and quest completion states.
- Implement one full repair sequence using the existing completion signal, then
  reuse the template without altering quest logic.

### Merge board

- Build the board frame and exactly 7×9 live cell surfaces.
- Produce all 13 chain sets (101 icons total) and producer states.
- Produce cell overlays and chain legend icons.
- Add chain-themed merge VFX and existing-trigger SFX.

Gate: complete a real repair from board item through task panel and see the live
environment state change; all merge/residence/save tests pass unchanged.

## Phase 3 — Characters, roster and dialogue

- Produce full portrait/expression/outfit sets for Mara, Noah, Lena, Riley,
  Imogen and Caleb.
- Preserve each `SurvivorDefinition.id`; populate its existing `portraits` and
  `expressions` dictionaries.
- Build shared portrait masks/frames and locked-card treatment.
- Add lightweight blink/breath/talk animation and reduced-motion fallback.
- Layer dialogue environments/foregrounds without baking text or choices into art.
- Add dialogue advance/choice/radio cues to existing entry/choice events.

Gate: every authored speaker displays the correct original character; missing
expressions fail safely; dialogue branching and rewards remain unchanged.

## Phase 4 — Remaining world screens

Order:

1. Redwater Service Station and eight hotspot sets.
2. Greybridge School and eight hotspot sets.
3. Saint Mercy Hospital and eight hotspot sets.
4. Northgate Prison and eight hotspot sets.
5. World map, routes and all marker states.
6. Scavenging location cards/backgrounds and encounter presentation.
7. Defence environment, survivor, Hollow, trap and barricade layers.

Use one residence pipeline and naming convention for all five. Do not change
residence unlock conditions or defence gates.

Gate: residence-specific smoke tests and main-story smoke test pass; screenshots
show distinct location identity and clear active/locked/completed states.

## Phase 5 — Hollow, vehicle, animation and VFX

- Produce six Hollow types with animation-ready separated layers or sprite sheets.
- Produce nine visually continuous van upgrade stages.
- Integrate survivor/Hollow/vehicle action sets from `ANIMATION_MANIFEST.csv`.
- Add ambient environment loops, route reveals, repair sequences, producer
  actions, reward reveals and defence feedback.
- Every non-essential effect must respect reduced motion and graphics quality.

Gate: no animation changes outcome timing or input availability; low-quality mode
has bounded particle counts and no persistent per-frame allocations.

## Phase 6 — Audio production and integration

- Compose/commission the music set and create seamless loops.
- Produce UI, merge, repair, environment, dialogue/radio, Hollow, defence and
  vehicle cue families with variations.
- Register assets in the existing `AudioManager` dictionaries.
- Add new visual/audio-only trigger calls only where the manifest says a trigger
  is missing.
- Verify Music/SFX/Master settings, focus loss, looping and voice-pool behavior.

Gate: no unsourced cue warnings during a complete vertical-slice playthrough;
audio remains optional and cannot block gameplay.

## Phase 7 — Mobile optimization and release polish

- Atlas small UI/item textures by category; trim transparent bounds.
- Prefer Ogg Vorbis for music/ambience and short compressed WAV/Ogg as appropriate.
- Use ETC2/ASTC-friendly texture sizes; cap residence layers to device-informed
  budgets; avoid unnecessary full-resolution alpha.
- Profile 405×720, 720×1280 and representative Android devices.
- Verify readable text, safe areas, 64 px touch targets, color contrast, low/high
  graphics modes, reduced motion and no state signaled by color alone.
- Re-run all tests, capture all 16 major screens, and compare against baseline.

## Recommended first production batch

Do not attempt the whole game at once. The first approved batch should contain:

1. Shared top bar, bottom navigation, button/panel skin and icon family.
2. Hollow Creek Stage 1 layered exterior plus front-door and kitchen-window states.
3. Construction chain levels 1–8 plus producer.
4. Mara neutral/concerned/injured portraits.
5. Merge, invalid, discovery, producer and task-complete SFX.

That batch exercises every integration path—UI, environment, hotspot state, item
path, portrait lookup, VFX and audio—while preserving the existing game rules.

## Verification checklist for every batch

- [ ] Git diff contains only art/audio/integration/optimization scope.
- [ ] No IDs, requirements, rewards, balance or save keys changed.
- [ ] Godot clean import succeeds.
- [ ] All existing smoke tests pass.
- [ ] Affected screen captured at 405×720 and 720×1280.
- [ ] Touch targets and text remain readable.
- [ ] Locked, disabled, selected, completed, injured and error states are distinct.
- [ ] Reduced-motion and low-graphics fallbacks work.
- [ ] Texture/audio import settings are mobile-appropriate.
- [ ] Manifest rows and license/source records are updated.
