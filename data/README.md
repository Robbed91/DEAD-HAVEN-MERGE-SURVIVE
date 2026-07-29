# Game data

Content lives here as data, not code, so writers/designers can add or edit
it without touching gameplay logic. Each subfolder holds instances of the
matching Resource class in `scripts/data_models/`.

| Folder | Resource | Populated in |
|---|---|---|
| `items/` | `ItemDefinition` | Phase 2 (merge board) |
| `chains/` | grouping data for the 9 merge chains in the design spec | Phase 2 |
| `quests/` | `QuestDefinition` | Phase 3 onward |
| `characters/` | `SurvivorDefinition` | Phase 6 |
| `residences/` | `ResidenceDefinition`, `ResidenceHotspot` | Phase 3 (Hollow Creek Farmhouse), Phase 8 (Redwater and beyond) |
| `dialogue/` | `DialogueEntry` | Phase 4 |
| `scavenging/` | `ScavengingMission` | Phase 5 |
| `vehicles/` | `VehicleDefinition` | Phase 6 |

Phase 1 only establishes the folder structure and the Resource classes
themselves; these folders are intentionally empty until their phase lands.
