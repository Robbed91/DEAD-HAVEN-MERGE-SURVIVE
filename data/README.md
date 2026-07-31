# Game data

Content lives here as data, not code, so writers/designers can add or edit
it without touching gameplay logic. Each subfolder holds instances of the
matching Resource class in `scripts/data_models/`.

| Folder | Resource | Populated in |
|---|---|---|
| `items/` | `ItemDefinition` | **Phase 2 - populated.** 101 items: 9 gameplay chains from the design spec (Construction/Tool/Food/Medical/Trap/Fuel/Vehicle Parts/Electronics/Clothing) + 4 reward chains (Energy/Coins/XP/Haven Tokens) |
| `chains/` | grouping metadata (item id order, producer id, task tags, reward-chain resource/value) | **Phase 2 - populated.** One `.json` per chain, 13 total |
| `quests/` | `QuestDefinition` | **Phase 3/6/8/10/11/12 - populated for the current roster.** 9 residence-repair quests for Hollow Creek Farmhouse (Phase 3) + Noah's personal quest `pq_noah_workbench` (Phase 6, the first `SURVIVOR_PERSONAL`-type quest, not tied to a hotspot) + 8 residence-repair/rescue quests each for Redwater Service Station (Phase 8, `q_rescue_lena`), Greybridge School (Phase 10, `q_rescue_riley`), Saint Mercy Hospital (Phase 11, `q_rescue_imogen`), and Northgate Prison (Phase 12, `q_rescue_caleb`); other quest types (main story, daily, etc.) are still unbuilt |
| `characters/` | `SurvivorDefinition` | **Phase 6/12 - populated.** All 6 named survivors, and as of Phase 12 all 6 now have an unlock path (Mara always, the other 5 each rescued at a residence) |
| `residences/` | `ResidenceDefinition`, `ResidenceHotspot` | **Phase 3/8/10/11/12 - populated, current roster complete.** Hollow Creek Farmhouse (9 hotspots, Phase 3), Redwater Service Station (8 hotspots, Phase 8), Greybridge School (8 hotspots, Phase 10), Saint Mercy Hospital (8 hotspots, Phase 11), and Northgate Prison (8 hotspots, Phase 12) |
| `dialogue/` | `DialogueEntry` | **Phase 4/8/10/11/12 - populated for the current roster.** The Chapter 1 intro (3 entries), and one 3-entry rescue scene each for Noah (Ch.2, Phase 4), Lena (Ch.5, Phase 8), Riley (Ch.6, Phase 10), Imogen (Ch.7, Phase 11), and Caleb (Ch.8, Phase 12) - later main-story chapters' dialogue is still unbuilt (see DEVELOPMENT_LOG.md) |
| `scavenging/` | `ScavengingMission` | **Phase 5 - populated.** 5 of the design spec's 10 initial locations (grocery store, petrol station, farm shed, roadside wreck, medical clinic); the schema also gained an `energy_cost` and `encounter_choices` field beyond spec section 31's literal list - see DEVELOPMENT_LOG.md Phase 5 |
| `vehicles/` | `VehicleDefinition` | **Phase 6 - populated.** The delivery van, 9 upgrade stages |

`items/`, `chains/`, `residences/`, `quests/`, `dialogue/`,
`scavenging/`, `characters/` and `vehicles/` were each generated once by a
script run through the Godot binary (see DEVELOPMENT_LOG.md Phase 2-6) and
the generator was deleted afterward - the `.tres`/`.json` files here are
the real content now; edit them directly (or write a new one-off script
if you need to bulk-regenerate after a schema change). Redwater's Phase 8
content (`residences/redwater_service_station.tres`, its 8 quests, and
`dialogue/lena_*.tres`), Greybridge's Phase 10 content
(`residences/greybridge_school.tres`, its 8 quests, and
`dialogue/riley_*.tres`), Saint Mercy's Phase 11 content
(`residences/saint_mercy_hospital.tres`, its 8 quests, and
`dialogue/imogen_*.tres`), and Northgate's Phase 12 content
(`residences/northgate_prison.tres`, its 8 quests, and
`dialogue/caleb_*.tres`) were all hand-written directly rather than
through a generator script - a single residence's worth of content
doesn't justify one. Every other folder is still just the empty structure
until its phase lands.
