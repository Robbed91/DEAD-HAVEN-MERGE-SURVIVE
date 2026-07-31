# Dead Haven: Merge & Survive - Illustration Checklist

A flat, hand-off-ready list of every illustration this project needs,
for whoever/whatever actually generates the art (this environment has no
image-generation tool - see `ART_ASSET_GUIDE.md`). Cross-referenced to
`ART_GENERATION_PROMPTS.md` (full generation-ready prompts) and
`assets/manifests/asset_manifest.json` (machine-readable status) where
those exist. This file is kept up to date as later build phases add more
residences/items/content - check back before handing it off if more work
has landed since you copied it.

**How to use this with another Claude/Codex session**: paste
`ART_GENERATION_PROMPTS.md`'s shared style header + negative prompt once,
then work down this list - the 10 items marked "prompt ready" already
have a full detailed prompt written; everything else needs one written
first (same format: dimensions, background/transparency, camera angle,
lighting, object details, prohibited elements, separated layers) before
generating, following that document's own pattern.

## Already done (no illustration needed)

Logo (5 variants), app icon, notification icon, splash screen - all real
original vector art, not placeholders. See `ART_STYLE_GUIDE.md` section 4.

---

## 1. Characters - 6 full survivor sheets

Each needs: front/three-quarter/side/back turnaround, neutral/action/
scavenging/injured poses, 12-expression sheet (neutral, happy, relieved,
concerned, afraid, angry, suspicious, sad, injured, exhausted, determined,
shocked), separated layers for rigging, and 3 equipment-progression notes
(early/mid/late game).

- [ ] **Mara Vale** (protagonist) - *prompt ready*, `ART_GENERATION_PROMPTS.md` #1
- [ ] **Noah Vance** (carpenter, rescued Ch.2) - *prompt ready*, `ART_GENERATION_PROMPTS.md` #2
- [ ] **Lena Ortiz** (mechanic, rescued Ch.5) - not yet prompted; source: `data/characters/lena_ortiz.tres`, `data/dialogue/lena_01-03.tres` (defensive/guarded intro, grease-marked clothing, rolled sleeves, tool pouch, protective eyewear, rust-orange accent, confident posture)
- [ ] **Dr Imogen Shaw** (former ER doctor, rescued Ch.7, Phase 11) - not yet prompted; source: `data/characters/imogen_shaw.tres`, `data/dialogue/imogen_01-03.tres` (guarded, demands proof of health before opening the isolation ward's sealed doors); brief section 17: practical field-medical clothing, medical bag, clean but worn coat, calm expression, green/teal accent
- [ ] **Riley Chen** (radio technician, rescued Ch.6, Phase 10) - not yet prompted; source: `data/characters/riley_chen.tres`, `data/dialogue/riley_01-03.tres` (defensive about the signal at first, found behind a wedged-shut stairwell); brief section 17: electronics pack, headset, layered clothing, improvised antenna tools, blue accent, alert/analytical posture
- [ ] **Caleb Rusk** (former security officer, rescued Ch.8, Phase 12, has a hidden Ashborn tie) - not yet prompted; source: `data/characters/caleb_rusk.tres`, `data/dialogue/caleb_01-03.tres` (openly hostile at first - the first rescue who's actually dangerous to approach - with a seeded, unexplained scrap of unfamiliar insignia under his jacket); brief section 17: heavy jacket, protective vest, restrained tactical gear, hidden Ashborn visual clue, suspicious expression

## 2. The Hollow - 6 enemy concept sheets + production sprites

Each needs a concept sheet (front/side/distant-silhouette) then, once
approved, idle/walk(or crawl)/attack/hit/collapse sprite frames (see
`assets/manifests/animation_manifest.json`'s `hollow_animation_set`).

- [ ] **Drifter** - *prompt ready* (concept sheet only), `ART_GENERATION_PROMPTS.md` #3
- [ ] **Screecher** - not yet prompted; thin frame, expanded chest posture, distinctive jaw/neck silhouette
- [ ] **Breaker** - not yet prompted; large body, heavy arms, damaged industrial clothing
- [ ] **Lurker** - not yet prompted; low crouched silhouette, debris/dirt-covered clothing
- [ ] **Runner** - not yet prompted; lean frame, forward posture, torn athletic clothing
- [ ] **Bloater** - not yet prompted; heavy unstable body, sickly gas particles, avoid excessive anatomical detail

## 3. Hollow Creek Farmhouse - exterior progression (5 stages)

- [ ] **Stage 1 - recently discovered** - *prompt ready*, `ART_GENERATION_PROMPTS.md` #4
- [ ] **Stage 2 - temporarily secured** - *prompt ready*, `ART_GENERATION_PROMPTS.md` #5
- [ ] **Stage 3 - habitable** (warm interior lights, fence repaired, smoke from chimney, cleared vegetable beds, survivors visible)
- [ ] **Stage 4 - defended** (traps installed, gate reinforced, watch position, warning lines, escape route visible) - this is the state during the "First Wave" defence event
- [ ] **Stage 5 - fully upgraded** (strong perimeter, functional barn, rain collector, generator lighting, vehicle parking, lookout platform, multiple survivors)

## 4. Hollow Creek Farmhouse - interiors (6 rooms x their own progression)

None prompted yet. Each should follow the same layered
background/structure/damage/foreground approach as the exterior prompts.

- [ ] Kitchen (linked to the `kitchen_window` hotspot)
- [ ] Living room (linked to the `living_room` hotspot)
- [ ] Bedroom (linked to the `upstairs_bedroom` hotspot - this is also Noah's rescue location)
- [ ] Pantry (linked to the `pantry` hotspot)
- [ ] Storm cellar
- [ ] Workshop area (linked to the `barn` hotspot / Noah's personal quest "Noah's Workbench")

## 5. Redwater Service Station - exterior states

- [ ] **Initial/abandoned state** - not yet prompted; source: `scenes/redwater/redwater_background.gd` (current procedural version - dusk canopy/pumps/store/garage composition), brief section 14: damaged canopy, broken shop windows, rusting pumps, garage door partly open, disabled delivery van, overgrown road, Ashborn faction markings, Hollow near abandoned cars
- [ ] **Upgraded state** - not yet prompted; brief section 14: reinforced shop, secured garage, fuel storage, functional workshop, repaired van, road barriers, rooftop lookout, warning lights, drainage escape tunnel, survivor activity

## 5b. Greybridge School - exterior states (Phase 10)

- [ ] **Current state** - not yet prompted; source: `scenes/greybridge/greybridge_background.gd` (current procedural version - flat cold overcast daylight, brick main building, gymnasium wing, rooftop radio tower, playground fence). No "upgraded" state designed yet in-game (unlike Hollow Creek/Redwater, Greybridge doesn't yet have a post-defence visual change) - add one if/when that's built.

## 5c. Saint Mercy Hospital - exterior states (Phase 11)

- [ ] **Current state** - not yet prompted; source: `scenes/saint_mercy/saint_mercy_background.gd` (current procedural version - full night, sickly green-white emergency-lit windows, main hospital block, ambulance bay wing, a parked ambulance). No "upgraded" state designed yet in-game, same as Greybridge - add one if/when that's built.

## 5d. Northgate Prison - exterior states (Phase 12)

- [ ] **Current state** - not yet prompted; source: `scenes/northgate/northgate_background.gd` (current procedural version - early dawn, concrete perimeter wall, stilted guard tower, barred cell block windows, sally port gate, razor wire fence). No "upgraded" state designed yet in-game, same as Greybridge/Saint Mercy - add one if/when that's built.

## 6. Remaining residences

None - all 5 residences in the current design roster (Hollow Creek
Farmhouse, Redwater Service Station, Greybridge School, Saint Mercy
Hospital, Northgate Prison) are built as of Phase 12. Any further
residences would be new scope beyond the original spec's list, not a
backlog item.

## 7. Merge board & UI

- [ ] **Merge board frame/background + 12 cell-state overlays** (empty, occupied, selected, valid-target, invalid-target, locked, cobweb, reward, bubble, task-required, rare, max-level) - *prompt ready*, `ART_GENERATION_PROMPTS.md` #6
- [ ] **Full UI component sheet** - not yet prompted as image assets (the component *behavior* already exists in code via `scripts/ui/theme_factory.gd`): primary/secondary/destructive/disabled/icon buttons in all states (normal/pressed/focused/disabled/loading), task card, dialogue panel, item info panel, resource bar, nav bar, quest panel, reward panel, character card, vehicle card, residence progress card, scavenging mission card, confirmation modal, tooltip, notification badge, progress/energy/health bars, morale indicator, locked-content overlay, tutorial highlight
- [ ] **Bottom navigation icons** (Haven, Merge, Map, Survivors, Inventory) - normal/selected/notification/locked states each
- [ ] **Full resource/status icon set** (~34 icons per brief section 27: energy, coins, Haven Tokens, food, medicine, fuel, morale, health, defence, noise, storage, survivor, vehicle, map, quest, story, repair, construction, locked, completed, warning, injury, radio, horde, Ashborn faction, settings, audio, vibration, accessibility, save, delete, undo, information, timer)

## 8. Merge item chains (101 items across 13 chains)

- [ ] **Construction (8 levels)** - *prompt ready as the template chain*, `ART_GENERATION_PROMPTS.md` #7 - use its structure for every chain below
- [ ] Tool (7 levels)
- [ ] Food (7 levels)
- [ ] Medical (7 levels)
- [ ] Trap (7 levels)
- [ ] Fuel (7 levels)
- [ ] Vehicle Parts (7 levels)
- [ ] Electronics (7 levels)
- [ ] Clothing (7 levels)
- [ ] Energy reward chain (7 levels)
- [ ] Coins reward chain (7 levels)
- [ ] XP reward chain (7 levels)
- [ ] Haven Tokens reward chain (7 levels)

Exact level names/descriptions for all 101 items already exist as data in
`data/items/*.tres` - pull display names/descriptions straight from there
when writing each chain's prompt so art matches what's already live in
game text.

## 9. Producers (9 total)

Each needs: normal/selected/activated/low-charge/empty/recharge states
+ a short looping animation note (per `ART_GENERATION_PROMPTS.md` #8's
Tool Crate as the template).

- [ ] **Salvaged Tool Crate** - *prompt ready*, `ART_GENERATION_PROMPTS.md` #8
- [ ] Damaged Workshop Bench (construction producer)
- [ ] Abandoned Pantry (food producer)
- [ ] Field Medical Bag (medical producer)
- [ ] Security Locker (trap producer)
- [ ] Fuel Shed (fuel producer)
- [ ] Mechanic's Trolley (vehicle parts producer)
- [ ] Broken Radio Desk (electronics producer)
- [ ] Abandoned Wardrobe (clothing producer)

## 10. Vehicle - delivery van (9 upgrade stages)

Source: `data/vehicles/delivery_van.tres` for each stage's exact
requirements/description. None prompted yet.

- [ ] Stage 1 - abandoned and damaged
- [ ] Stage 2 - engine repaired
- [ ] Stage 3 - new tyres
- [ ] Stage 4 - fuel system restored
- [ ] Stage 5 - storage racks installed
- [ ] Stage 6 - windows reinforced
- [ ] Stage 7 - front ram installed
- [ ] Stage 8 - roof storage installed
- [ ] Stage 9 - expedition-ready version

## 11. Scavenging locations (all 10 built as of Phase 13)

Each needs arrival/exploration/threat/loot/escape illustrated states.
None have any illustration at all currently - the scavenging screen is
plain text/UI, no background of any kind (unlike every residence, which
at least has a procedural placeholder) - the single largest "zero art
exists here" gap left in the project.

- [ ] Abandoned grocery store (`data/scavenging/abandoned_grocery_store.tres`)
- [ ] Petrol station (`data/scavenging/petrol_station.tres`)
- [ ] Farm shed (`data/scavenging/farm_shed.tres`)
- [ ] Roadside wreck (`data/scavenging/roadside_wreck.tres`)
- [ ] Medical clinic (`data/scavenging/medical_clinic.tres`)
- [ ] Police checkpoint (`data/scavenging/police_checkpoint.tres`) - human-threat-heavy, an "arranged, not overrun" detail hinting at the Ashborn
- [ ] Electronics workshop (`data/scavenging/electronics_workshop.tres`)
- [ ] Clothing outlet (`data/scavenging/clothing_outlet.tres`)
- [ ] Warehouse depot (`data/scavenging/warehouse_depot.tres`)
- [ ] Radio relay station (`data/scavenging/radio_relay_station.tres`) - only reachable once `saint_mercy_unlocked` is set; ties into the Signal Keeper capstone's Haven Line theme

## 12. Dialogue scene backgrounds

- [ ] **Intro scene** (farmhouse approach) - *prompt ready*, `ART_GENERATION_PROMPTS.md` #10
- [ ] Noah rescue scene (upstairs bedroom interior - see checklist item 4)
- [ ] Lena rescue scene (garage workshop interior)
- [ ] Riley rescue scene (Greybridge stairwell/radio tower)
- [ ] Imogen rescue scene (Saint Mercy isolation ward)
- [ ] Caleb rescue scene (Northgate warden's office, bunkered)
- [ ] **Signal Keeper capstone scene** (Phase 13, Hollow Creek kitchen at night, radio close-up) - the main-story climax of the current content roster; no illustration or portrait exists for the "signal_keeper" speaker itself, which is deliberately a voice without a face at this point in the story
- [ ] Future dialogue scenes as later chapters are built

## 13. World map

- [ ] Full illustrated regional map (roads, rivers, forests, settlements, residence markers, scavenging markers) - source: `scenes/world_map/world_map_background.gd` for the current procedural composition/marker positions to match

## 14. Effects (currently generic, need per-theme variants)

- [ ] Chain-themed merge particles (wood splinters/sparks/dust/fabric fibres/metal fragments/medical cross/fuel droplets/radio pulses - currently one generic expanding-ring burst for every chain, see `animation_manifest.json`'s `merge_success_burst`)
- [ ] Environment effects (rain, dust, fog, wind-blown leaves, smoke, embers, sparks)
- [ ] Danger effects (red warning pulse, screen-edge threat indicator, gas cloud)

---

## Priority order if generating in batches

1. Vertical slice (the 10 "prompt ready" items above) - proves the art direction works before mass production
2. Remaining 4 survivor sheets (Lena, Riley, Imogen, Caleb - all recruitable in-game as of Phase 12, none prompted yet) + remaining 5 Hollow types - characters are seen constantly and currently have zero unique art
3. Construction chain's 7 sibling chains (item art is the single most-seen asset category)
4. Farmhouse stages 3-5 + 6 interiors, Redwater's 2 states
5. Producers, vehicle stages, UI component sheet, icon set
6. Scavenging locations, world map, effects, remaining residences (build-gated)
