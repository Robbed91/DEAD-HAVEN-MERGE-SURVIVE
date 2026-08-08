# Dead Haven Character Visual Production

## Scope and invariants

This production pass replaces the geometric `SurvivorSilhouette` rendering for all six implemented survivors and supplies the implemented Drifter Hollow. It does not modify `data/characters`, survivor statistics, skills, relationships, dialogue entries, quest IDs, save fields, progression, or outcome logic. The historical class name remains in place so existing scene references remain valid.

## Delivered characters

| Character | Identity source | Runtime directory | Portraits | Poses/outfits | Rig layers |
|---|---|---|---:|---:|---:|
| Mara Vale | `assets/art/characters/source/mara_vale_sheet.png` | `assets/art/characters/mara_vale` | 8 | 6 | 8 |
| Noah Vance | `assets/art/characters/source/noah_vance_sheet.png` | `assets/art/characters/noah_vance` | 8 | 6 | 8 |
| Lena Ortiz | `assets/art/characters/source/lena_ortiz_sheet.png` | `assets/art/characters/lena_ortiz` | 8 | 6 | 8 |
| Dr Imogen Shaw | `assets/art/characters/source/imogen_shaw_sheet.png` | `assets/art/characters/imogen_shaw` | 8 | 6 | 8 |
| Riley Chen | `assets/art/characters/source/riley_chen_sheet.png` | `assets/art/characters/riley_chen` | 8 | 6 | 8 |
| Caleb Rusk | `assets/art/characters/source/caleb_rusk_sheet.png` | `assets/art/characters/caleb_rusk` | 8 | 6 | 8 |
| Drifter Hollow | `assets/art/enemies/source/drifter_hollow_sheet.png` | `assets/art/enemies/drifter_hollow` | n/a | 12 states | 8 |

Each survivor has `neutral`, `front_three_quarter`, `reverse_three_quarter`, `back`, `residence`, and `scavenging` pose assets; portraits cover neutral, concerned, angry, afraid, relieved, injured, exhausted, and determined. Separated runtime-source layers are head, torso, left/right arms, left/right legs, and left/right feet.

## Runtime presentation

- `scripts/ui/survivor_silhouette.gd` now displays authored portraits for every implemented survivor. Locked cards darken the real art and use the final lock plate; no geometric head/circle/capsule drawing remains.
- Dialogue chooses an authored expression from the existing line and plays `speaking`, `fear`, or `injured` portrait motion. Dialogue content and branching are unchanged.
- `scripts/ui/layered_character_rig.gd` provides a reusable AnimationPlayer-based sprite rig, a Skeleton2D refinement scaffold, separated layer nodes, and clean composite rendering at mobile size.
- Hollow Creek connects its existing ambient actor state to Mara/Noah `idle_breathing` and Drifter `distant_wandering`/`idle_sway`. No new gameplay state is introduced.

Survivor animation names: `idle_breathing`, `blink`, `look_around`, `speaking`, `walking`, `running`, `carrying`, `hammering`, `sawing`, `searching`, `using_radio`, `treating_injury`, `entering_vehicle`, `celebration`, `fear`, `injured_idle`, `defensive_action`.

Drifter animation names: `idle_sway`, `slow_walk`, `detect_target`, `attack_barricade`, `hit_reaction`, `trap_reaction`, `collapse`, `distant_wandering`.

## Image-generation record

Mode: generation for Lena, Imogen, Riley, and Caleb; identity-preserving reference generation for Drifter; approved existing project concepts reused for Mara and Noah. Source sheets are excluded from Godot import with `.gdignore`; runtime exports are imported normally.

Final prompt pattern used for the survivors:

> Production character identity and animation reference sheet for an original Dead Haven survivor. Premium painterly 2.5D mobile-game stylised realism, clean readable silhouette, controlled charcoal edges, warm amber rim light against cool storm blue-grey, consistent face/proportions/clothes/equipment in every panel. Show full-body neutral front, front three-quarter, reverse three-quarter and back; residence and scavenging outfits; relevant action poses; eight expression portraits: neutral, concerned, angry, afraid, relieved, injured, exhausted, determined. No text, logos, watermark, copied characters, photography, emoji, pixel art, or flat vector art.

Character-specific identity clauses fixed role, age, ethnicity, face, hair, costume palette and equipment: Lena is a compact Latina mechanic in rust workwear; Imogen is a Black British field physician in weathered teal; Riley is a Chinese-British nonbinary radio technician in storm-blue technical layers; Caleb is a broad Black security specialist in battered olive gear.

Final Drifter prompt:

> Preserve the exact identity and costume of the supplied original Drifter Hollow reference. Create a premium painterly 2.5D mobile-game production sheet with neutral/front three-quarter/reverse/back views, idle sway, slow walk, detect target, attack barricade, hit reaction, trap reaction, collapse and distant wandering, plus separable head/torso/arms/legs. Cool corpse blue-grey lighting, readable silhouette, restrained non-gory decay. No text, logos, watermark, copied media character, emoji, pixel art, or flat vector art.

## Verification

- Godot 4.3 imported every runtime texture.
- All fourteen existing smoke-test scenes pass.
- Running-game roster capture: `docs/character-captures/survivor_roster_final.png`.
- Running-game dialogue capture: `docs/character-captures/mara_dialogue_final.png`.
- Hollow Creek capture with rigged Mara, Noah and Drifter: `docs/vertical-slice-captures/hollow_creek_final_running.png`.
