# Game data

Content lives here as data, not code, so writers/designers can add or edit
it without touching gameplay logic. Each subfolder holds instances of the
matching Resource class in `scripts/data_models/`.

| Folder | Resource | Populated in |
|---|---|---|
| `items/` | `ItemDefinition` | **Phase 2 - populated.** 101 items: 9 gameplay chains from the design spec (Construction/Tool/Food/Medical/Trap/Fuel/Vehicle Parts/Electronics/Clothing) + 4 reward chains (Energy/Coins/XP/Haven Tokens) |
| `chains/` | grouping metadata (item id order, producer id, task tags, reward-chain resource/value) | **Phase 2 - populated.** One `.json` per chain, 13 total |
| `quests/` | `QuestDefinition` | **Phase 3 - partially populated.** 9 residence-repair quests for Hollow Creek Farmhouse; other quest types (main story, daily, scavenging, etc.) land with their respective phases |
| `characters/` | `SurvivorDefinition` | Phase 6 |
| `residences/` | `ResidenceDefinition`, `ResidenceHotspot` | **Phase 3 - populated.** Hollow Creek Farmhouse (9 hotspots); Phase 8 adds Redwater and beyond |
| `dialogue/` | `DialogueEntry` | **Phase 4 - partially populated.** The Chapter 1 intro (3 entries) and the Chapter 2 Noah-rescue scene (3 entries, one branching) - later chapters' dialogue lands with the phases that unlock them (see DEVELOPMENT_LOG.md) |
| `scavenging/` | `ScavengingMission` | Phase 5 |
| `vehicles/` | `VehicleDefinition` | Phase 6 |

`items/`, `chains/`, `residences/`, `quests/` and `dialogue/` were each
generated once by a script run through the Godot binary (see
DEVELOPMENT_LOG.md Phase 2-4) and the generator was deleted afterward -
the `.tres`/`.json` files here are the real content now; edit them
directly (or write a new one-off script if you need to bulk-regenerate
after a schema change). Every other folder is still just the empty
structure until its phase lands.
