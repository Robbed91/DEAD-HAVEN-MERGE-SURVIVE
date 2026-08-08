extends Resource
class_name ScavengingMission
## One scavenging location/mission definition. Missions are choice-driven
## encounters (see section 10 of the design spec), not passive timers.

@export var id: String
@export var location_name: String
@export var danger_rating: int = 1 # 1-5
@export var duration_seconds: int = 300
@export var recommended_equipment: PackedStringArray = []
@export var loot_table: Dictionary = {}
@export var survivor_encounter_ids: PackedStringArray = []
@export var story_condition: String = ""
@export var zombie_threat: int = 1
@export var human_threat: int = 0
@export var noise_level: int = 1
@export var encounter_scene_path: String = ""

## Energy cost to launch this mission (spec: preparation/equipment cost -
## simplified to a flat energy spend since no inventory-loadout system
## exists yet; see DEVELOPMENT_LOG.md Phase 5).
@export var energy_cost: int = 10

## Phase 5 addition beyond the design spec's literal field list (spec
## section 31 predates the exact implementation): one choice-based
## encounter per mission. Each entry:
## {"text": String, "success_chance": float 0..1, "success_text": String,
##  "success_loot": Dictionary, "failure_text": String, "failure_penalty": Dictionary}
## success_loot/failure_penalty use the same {resource_or_item_id: amount}
## shape as QuestDefinition.rewards, plus item ids resolve through
## ItemDatabase/BoardState instead of GameManager when not a known resource key.
@export var encounter_choices: Array[Dictionary] = []
