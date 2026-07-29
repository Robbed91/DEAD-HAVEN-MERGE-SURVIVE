extends Resource
class_name ResidenceDefinition
## A single survival residence (Hollow Creek Farmhouse, Redwater Service
## Station, ...) - one explorable Haven scene with its own hotspots and
## chapter content.

@export var id: String
@export var display_name: String
@export var description: String
@export var environment_scene_path: String
@export var hotspots: Array[ResidenceHotspot] = []
@export var chapter_ids: PackedStringArray = []
@export var unlock_requirements: Dictionary = {}
@export var completion_rewards: Dictionary = {}
