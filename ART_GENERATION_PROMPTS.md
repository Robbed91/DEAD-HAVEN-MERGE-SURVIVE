# Dead Haven: Merge & Survive - Art Generation Prompts

Production-ready prompts for the vertical-slice assets the art brief's
Section 48 asks for, written so anyone with an image-generation tool can
produce consistent, on-model art without further direction. This is the
Section 45 fallback in practice: this project's environment has no
image-generation tool, so every asset below is tracked as **concept**
status in `assets/manifests/asset_manifest.json` rather than skipped or
faked with a raster placeholder.

Every prompt in this document must be prefixed with the shared style
definition below (Section 46 of the brief) before its own detail, and
should be generated alongside its negative prompt (Section 47). Treat
each prompt as one entry in a **grouped production batch** - generate the
whole vertical slice together, in one sitting/model, so results share a
consistent hand rather than drifting style between assets generated days
apart.

## Shared style header (prepend to every prompt below)

> Original premium 2.5D mobile-game illustration for Dead Haven: Merge &
> Survive, stylised realism, painterly digital rendering, clean
> mobile-readable silhouettes, slightly exaggerated proportions,
> atmospheric cinematic lighting, weathered post-apocalyptic materials,
> controlled detail, consistent three-quarter perspective, warm
> safe-haven amber contrasted with cool storm blue-grey, deep charcoal
> outlines used sparingly, polished commercial Android game quality,
> original characters and objects, no copyrighted designs, no text, no
> watermark.

## Shared negative prompt (append to every prompt below)

> No copyrighted characters, no Walking Dead characters, no Merge Mansion
> interface, no logos, no watermarks, no embedded text, no photographic
> collage, no inconsistent lighting, no extra fingers, no deformed hands,
> no duplicated objects, no floating equipment, no extreme gore, no
> modern pristine objects unless narratively required, no unreadable
> clutter, no cropped important objects, no mismatched perspectives, no
> pixel-art style, no anime style, no flat corporate-vector style.

---

## 1. Mara Vale - character sheet

Source: `data/characters/mara_vale.tres` (protagonist, resourceful,
determined, skills: leadership/improvisation/negotiation), `README.md`
"Setting" (searching for her missing brother Eli, following the Haven
Seven radio signal), `ART_ASSET_GUIDE.md` "Character rendering".

- **Dimensions**: full-body source 1600-2400px tall (layered for rigging
  per brief section 32); dialogue portrait crop 1024x1024.
- **Background/transparency**: transparent PNG, no background elements.
- **Camera angle**: full-body front view, three-quarter view, side view,
  back view - four separate panels on one sheet, consistent proportions
  across all four.
- **Lighting**: neutral, even studio-style lighting for the turnaround
  views (no cast shadow direction bias, so the character reads correctly
  when later composited into any scene's own lighting).
- **Character details**: early thirties, athletic but not exaggerated
  build, dark practical jacket, faded red scarf/cloth accent, utility
  trousers, work boots, small backpack, handheld radio clipped to a
  strap, an improvised tool on her belt, visible signs of travel and
  exhaustion (dust, a little grime, nothing gory), strong but approachable
  facial features. Include a neutral pose, an action pose, a scavenging
  pose, and an injured pose on the same sheet.
- **Expression set** (separate small panel, head-and-shoulders only):
  neutral, happy, relieved, concerned, afraid, angry, suspicious, sad,
  injured, exhausted, determined, shocked - twelve total per brief
  section 18.
- **Progression notes** (annotate, don't fully illustrate three separate
  outfits in this pass): early game = light equipment, damaged clothing,
  small backpack, minimal protection; mid game = reinforced jacket, larger
  backpack, better gloves, radio equipment, tool harness; late game =
  expedition armour, Haven insignia, advanced comms gear, weatherproof
  clothing. She must stay recognisable (scarf, hair, face) through all
  three.
- **Prohibited elements**: no weapon posed aggressively at camera, no
  modern tactical gear that reads as military-industrial rather than
  improvised-survivor, no exposed wounds beyond a small bandage.
- **Required separated layers**: hair, head, torso/jacket, backpack,
  scarf, belt tools, legs/boots - each its own layer for later rigging
  (Skeleton2D cut-out per brief section 20).

## 2. Noah Vance - character sheet

Source: `data/characters/noah_vance.tres` (former carpenter, protective,
quiet, suspicious of strangers, skills: construction/tool/barricades),
`data/dialogue/noah_01.tres`-`noah_03.tres` (found feverish and wounded in
the farmhouse's upstairs bedroom, slow to trust).

- **Dimensions/background/camera angle**: same spec as Mara Vale above
  (full turnaround sheet + expression set + separated layers).
- **Character details**: strong build, worn work jacket, tool belt with
  visible carpentry tools (hammer, folding rule), worn leather work
  gloves, restrained/muted colour palette (browns, dull greens - he is
  the visual opposite of Lena Ortiz's rust-orange mechanic accent),
  reserved facial expression, guarded posture. Include a specific
  **introduction/injured pose**: curled defensively, a torn strip of
  shirt pressed to a wound on his arm, feverish - this is his first-seen
  state in `data/dialogue/noah_01.tres` and should be produced as its own
  panel, separate from his standard healthy poses.
- **Prohibited elements**: no gore beyond a small bandaged wound, no
  expression that reads as hostile rather than guarded/suspicious.
- **Required separated layers**: same breakdown as Mara Vale.

## 3. Drifter (The Hollow) - concept sheet

Source: `ART_ASSET_GUIDE.md` / brief Section 19.

- **Dimensions**: 256x256 per-frame sprite target; concept sheet itself
  can be larger (e.g. 2000px wide, multiple poses).
- **Background/transparency**: transparent PNG for in-game sprites; the
  concept sheet itself may use a plain neutral grey background since it's
  a reference document, not a runtime asset.
- **Camera angle**: front view and side view, plus one distant silhouette
  study (how it reads at small size/low light, since Drifters should be
  identifiable from across a dark yard).
- **Lighting**: cool storm blue-grey exterior lighting, consistent with
  every other exterior asset in this style guide.
- **Object details**: slow, unbalanced posture, torn ordinary clothing
  (not military/tactical - Drifters were civilians), pale weathered skin,
  asymmetrical silhouette (one shoulder lower, an uneven gait implied even
  in a static pose). Unsettling through posture and asymmetry, not gore.
- **Prohibited elements**: no exposed viscera, no excessive wounds, no
  design elements that read as a specific copyrighted zombie archetype
  (avoid the "shuffling suburban commuter in business attire" look
  specifically associated with certain existing franchises - keep Drifter
  wardrobe generic rural/working clothing consistent with the Haven
  Line's setting).
- **Required separated layers**: none required for the concept sheet
  itself; production sprites need idle/walk/attack/hit/collapse frame
  layers once approved (see `animation_manifest.json`'s
  `hollow_animation_set` entry).

## 4. Hollow Creek Farmhouse exterior - Stage 1 (recently discovered)

Source: `scenes/haven/haven_background.gd` (current procedural version -
use its composition as the layout reference), brief Section 13 "Stage 1".

- **Dimensions**: 1080x2400 portrait source (brief section 31's base
  reference), layered for parallax per brief section 20.
- **Background/transparency**: opaque, full scene illustration (this is a
  background, not a sprite).
- **Camera angle**: slightly elevated three-quarter view of the farmhouse
  exterior, matching the current procedural composition's framing (barn
  visible left background, farmhouse centred, kitchen window and front
  door as the two foreground focal points since they're the first two
  repair hotspots).
- **Lighting**: overcast grey sky, no warm light sources anywhere in the
  building - this state must read as cold and unwelcoming.
- **Scene details**: weather-damaged farmhouse, broken kitchen window,
  front door hanging open, collapsed section of fence, overgrown garden,
  damaged barn silhouette in the distance, an abandoned wheelbarrow, a
  muddy path leading to the porch, one or two distant Hollow figures at
  the tree line (small, not a focal point), grey overcast sky, no safe
  lighting anywhere.
- **Prohibited elements**: no warm interior light (that belongs only to
  later stages), no gore, no readable text on any signage.
- **Required separated layers**: sky, distant barn, farmhouse structure,
  damage/debris (broken window, open door - these are the two hotspot
  locations and must be easy to isolate/repaint per hotspot state),
  foreground (path, wheelbarrow, grass).

## 5. Hollow Creek Farmhouse exterior - Stage 2 (temporarily secured)

Same spec as Stage 1 above, with these changes per brief Section 13
"Stage 2":

- Front door now repaired/closed, several windows boarded (reuse the
  boarded-window motif established in `icon.svg`/the logo set for visual
  continuity across the brand and the game world), debris on the porch
  partly cleared, one small lantern near the entrance providing the
  scene's first and only warm light source. Sky can lighten slightly but
  should still read as tense, not yet safe - this is "held," not "home."

## 6. Merge-board design

Source: `scenes/merge_board/merge_board.gd` (current 7x9 grid layout and
cell-state logic - use its states as the literal spec, not just
inspiration), brief Section 9.

- **Dimensions**: board frame background at 1080px wide (fills the merge
  screen's play area), individual cell art at 128x128.
- **Background/transparency**: board surface is opaque (a worn
  planning-table/scavenged-workbench illustration); cell-state overlays
  (selected, valid-target, invalid-target, locked, cobweb, reward,
  bubble) are transparent PNG overlays composited on top per cell.
- **Camera angle**: flat top-down view of the table surface (this is the
  one asset in the whole game that should NOT use the three-quarter
  perspective - a merge grid needs to read as a flat, gridded surface).
- **Lighting**: warm neutral lighting, as if lit from a lamp just off
  frame - this is an interior workbench, not an exterior scene.
- **Scene details**: worn wood/scavenged-workbench surface texture, a
  dark outer frame, subtle environmental details at the very edges only
  (a few tools, a mug, nothing that encroaches on the 7x9 grid itself -
  per the brief's own rule, avoid decorative debris inside playable
  cells). Produce the full cell-state set as separate overlay assets:
  empty, occupied, selected, valid-merge-target, invalid-merge-target,
  locked, cobweb, reward, bubble-item, task-required-item, rare-item,
  maximum-level-item (twelve states, matching `BoardState`'s actual
  runtime states in `autoload/board_state.gd`).
- **Prohibited elements**: no perspective/depth cues inside the grid
  itself (breaks merge readability), no cell decoration that could be
  mistaken for a playable item.
- **Required separated layers**: table surface, frame, each of the twelve
  cell-state overlays as individual transparent PNGs.

## 7. Construction merge chain (8 levels)

Source: `data/items/construction_1.tres` through `construction_8.tres`
and `data/chains/construction.json` for the exact existing level
count/order (this project's construction chain is 8 levels, not the
brief's illustrative 8-level example - they happen to match, use the
existing data as ground truth if they ever diverge).

- **Dimensions**: 256x256 or 512x512 source per brief section 32,
  displayed at 128x128 runtime.
- **Background/transparency**: transparent PNG, consistent padding
  across all 8 levels so they visually align in a merge animation.
- **Camera angle**: consistent three-quarter view across all 8 levels -
  this consistency matters more for this asset than almost any other,
  since the player sees these items merge into each other constantly.
- **Lighting**: consistent single virtual light source (upper-left,
  matching the rest of the item set) across all 8 levels.
- **Object details, level by level**: 1) splintered scrap wood 2) several
  usable wood offcuts 3) cut timber strips 4) stacked wooden boards 5)
  strapped reinforced planks 6) complete barricade kit with visible nails
  and brackets 7) fortified wall assembly section 8) heavy defensive gate
  section. Each level must look materially more useful/valuable than the
  last - not the same drawing scaled up. Add subtle wear/dirt consistent
  with a weathered post-apocalyptic setting, more raw/damaged at level 1,
  more finished/deliberate at level 8.
- **Prohibited elements**: no readable text/branding on any wood grain or
  stamped marking, no photorealistic wood-grain texture (must stay
  painterly, not photo-collaged).
- **Required separated layers**: none required per item (each level is a
  single flat icon); keep each level as its own file for animation
  swapping.

## 8. Salvaged Tool Crate producer

Source: `data/items/tool_producer.tres`, `ART_ASSET_GUIDE.md` producer
section, brief Section 11.

- **Dimensions**: 512x512 or larger source, separate animated layers.
- **Background/transparency**: transparent PNG.
- **Camera angle**: three-quarter view, consistent with the item chain
  set above.
- **Lighting**: consistent single virtual light source, matching the item
  set.
- **Object details**: a battered wooden crate stencilled/painted with
  salvage markings (no readable text - use abstract paint-daub markings
  instead), visible hand tools inside (hammer, wrench, pliers) that shift
  position between states. Produce all required states on one sheet:
  normal, selected (subtle highlight/outline), activated (lid open, tools
  visible), low-charge (lid mostly closed, dimmer), empty (lid closed,
  no glow), recharge (a few sparkles/motion lines suggesting refill in
  progress). A small looping animation cue: the lid creaks open a few
  degrees and a tool shifts slightly - describe this as a 2-3 frame loop
  for the animator, not a single static image.
- **Prohibited elements**: no readable text on the crate, no modern
  power-tool designs (hand tools only, consistent with the setting).
- **Required separated layers**: crate body, lid (separate for the
  open/close animation), each visible tool as its own layer.

## 9. Window-boarding task graphics + animation

Source: `scripts/residence/hotspot_visual.gd`'s `kitchen_window` case
(current procedural before/after patch), brief Section 21's "boarding a
window" example sequence.

- **Dimensions**: hotspot art at roughly 256x256 (matches the in-scene
  hotspot tap-target size), matching the farmhouse exterior's own scale
  when composited.
- **Background/transparency**: transparent PNG, composited directly onto
  the farmhouse exterior background at the kitchen-window hotspot
  position.
- **Camera angle**: matches the farmhouse exterior's own three-quarter
  camera angle exactly (this asset is a patch onto that background, not a
  standalone illustration).
- **Lighting**: matches whichever farmhouse stage it's composited onto
  (Stage 1's cold grey light for the "before" state, Stage 2's onward
  warmer light for "after").
- **Object details / animation storyboard** (per brief section 21's
  10-step template, adapted to this specific task): 1) camera gently
  pushes toward the window 2) Mara or the active survivor approaches from
  frame edge 3) loose boards are carried into view 4) hammering begins,
  small motion lines 5) dust/wood-splinter particles appear 6) boards
  attach one at a time (3-4 boards, matching the current procedural
  version's board count) 7) survivor steps back, inspects the work 8) the
  completed boarded-window state snaps cleanly into place 9) a brief
  warm-toned reward-particle flourish 10) camera returns to the normal
  hotspot-overview framing. Produce this as a numbered storyboard panel
  set (10 small frames), not a single image - it's a sequence brief for
  an animator, per brief section 44's "do not leave essential animation
  as a written recommendation" (the storyboard itself IS the concrete
  deliverable this environment can produce; frame-by-frame final art
  requires the image-generation step this environment doesn't have).
- **Prohibited elements**: no readable text, no character redesign
  (survivor must match whichever character sheet is doing the repair).
- **Required separated layers**: boards (each board as its own layer, so
  the "attach one at a time" beat can animate independently), dust/
  splinter particles, survivor cutout (reuse the relevant character
  sheet's scavenging/action pose rather than drawing a new one).

## 10. Initial dialogue-scene design

Source: `scenes/dialogue/dialogue.gd`, `data/dialogue/intro_01.tres`-
`intro_03.tres` (the actual first dialogue content this design frames).

- **Dimensions**: 1080x2400 portrait background, character cut-outs at
  the same scale as their character-sheet dialogue-portrait crops.
- **Background/transparency**: background is opaque (full scene
  illustration); character cut-outs are transparent PNG, composited as
  separate layers over the background so per-character expression swaps
  don't require re-rendering the whole scene.
- **Camera angle**: three-quarter/eye-level view of the scene location
  (the farmhouse's front approach, matching `intro_01.tres`'s "sits quiet
  at the end of a long gravel drive" description), with a soft depth-of-
  field blur on the background so the foreground character cut-out and
  the dialogue box stay the clear focal point.
- **Lighting**: matches Stage 1 of the farmhouse exterior (grey, tense,
  no warmth yet) - the intro scene happens before any repairs.
- **Scene details**: gravel drive, boarded/broken windows visible in the
  distance, Mara Vale's cut-out (neutral pose, matching her character
  sheet) positioned lower-third-left, leaving the upper-right clear for
  the dialogue box per the existing `dialogue.tscn` layout. Include
  foreground depth elements (a fence post, overgrown grass) closer to
  camera than Mara, for parallax depth per brief section 30.
- **Prohibited elements**: no readable text baked into the illustration
  (dialogue text stays in the existing `Label`/dialogue-box UI, per
  brief section 30's own rule), no second character in this specific
  scene (intro_01-03 is Mara alone).
- **Required separated layers**: background (sky/drive/farmhouse-distant),
  foreground depth elements, Mara cut-out (separate from background so
  `DialogueEntry.expression_key` can swap her portrait without
  re-rendering the scene).

---

## What happens next

Every asset above is recorded in `assets/manifests/asset_manifest.json`
with `"status": "concept"` and a pointer back to its numbered section
here. When an image-generation tool becomes available in a future
session: generate this batch together (for style consistency), review
against brief Section 42's acceptance criteria, clean up per brief
Section 35's workflow (correct anatomy/perspective, remove artefacts,
separate layers, trim/optimise), then update each manifest entry's
`status` through `draft` -> `approved` -> `integrated` as it's actually
wired into its scene - never mark `final` before that wiring is done and
confirmed, per the brief's own Section 36 rule.
