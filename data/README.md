# Game data

Content lives here as data, not code, so writers/designers can add or edit
it without touching gameplay logic. Each subfolder holds instances of the
matching Resource class in `scripts/data_models/`.

| Folder | Resource | Populated in |
|---|---|---|
| `items/` | `ItemDefinition` | **Phase 2 - populated.** 101 items: 9 gameplay chains from the design spec (Construction/Tool/Food/Medical/Trap/Fuel/Vehicle Parts/Electronics/Clothing) + 4 reward chains (Energy/Coins/XP/Haven Tokens) |
| `chains/` | grouping metadata (item id order, producer id, task tags, reward-chain resource/value) | **Phase 2 - populated.** One `.json` per chain, 13 total |
| `quests/` | `QuestDefinition` | **Phase 3/6 - partially populated.** 9 residence-repair quests for Hollow Creek Farmhouse (Phase 3) + Noah's personal quest `pq_noah_workbench` (Phase 6, the first `SURVIVOR_PERSONAL`-type quest, not tied to a hotspot); other quest types (main story, daily, etc.) land with their respective phases |
| `characters/` | `SurvivorDefinition` | **Phase 6 - populated.** All 6 named survivors, fully written even though only Mara/Noah have an unlock path yet |
| `residences/` | `ResidenceDefinition`, `ResidenceHotspot` | **Phase 3 - populated.** Hollow Creek Farmhouse (9 hotspots); Phase 8 adds Redwater and beyond |
| `dialogue/` | `DialogueEntry` | **Phase 4 - partially populated.** The Chapter 1 intro (3 entries) and the Chapter 2 Noah-rescue scene (3 entries, one branching) - later chapters' dialogue lands with the phases that unlock them (see DEVELOPMENT_LOG.md) |
| `scavenging/` | `ScavengingMission` | **Phase 5 - populated.** 5 of the design spec's 10 initial locations (grocery store, petrol station, farm shed, roadside wreck, medical clinic); the schema also gained an `energy_cost` and `encounter_choices` field beyond spec section 31's literal list - see DEVELOPMENT_LOG.md Phase 5 |
| `vehicles/` | `VehicleDefinition` | **Phase 6 - populated.** The delivery van, 9 upgrade stages |

`items/`, `chains/`, `residences/`, `quests/`, `dialogue/`,
`scavenging/`, `characters/` and `vehicles/` were each generated once by a
script run through the Godot binary (see DEVELOPMENT_LOG.md Phase 2-6) and
the generator was deleted afterward - the `.tres`/`.json` files here are
the real content now; edit them directly (or write a new one-off script
if you need to bulk-regenerate after a schema change). Every other folder
is still just the empty structure until its phase lands.
