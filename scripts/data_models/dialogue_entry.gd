extends Resource
class_name DialogueEntry
## One line/beat of data-driven story dialogue, optionally branching.

@export var id: String
@export var speaker_id: String # SurvivorDefinition id, or "" for narration
@export var portrait_key: String
@export var expression_key: String = "neutral"
@export var text: String
@export var background_scene_path: String = ""
@export var animation: String = ""
@export var sound_cue: String = ""

## Each option: {"text": String, "next_id": String, "condition": String,
## "reward": Dictionary, "relationship_changes": Dictionary, "quest_trigger": String}
@export var branching_options: Array[Dictionary] = []
@export var next_id: String = "" # used when there are no branching_options
