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
