extends Resource
class_name VehicleDefinition
## A discoverable/upgradeable vehicle (see section 13 of the design spec).
## Upgrade stages are ordered; stage index also selects which environment
## variant scene to show wherever the vehicle is visible.

@export var id: String
@export var display_name: String
@export var upgrade_stage_names: PackedStringArray = []
@export var current_stage: int = 0
@export var stage_scene_paths: Dictionary = {} # {stage_index: scene_path}
@export var stage_requirements: Dictionary = {} # {stage_index: {item_id: count}}

@export var fuel_use: float = 1.0
@export var reliability: float = 0.5
@export var storage_capacity: int = 4
@export var noise: float = 0.5
@export var protection: float = 0.2
@export var range_km: float = 10.0
@export var is_discovered: bool = false
