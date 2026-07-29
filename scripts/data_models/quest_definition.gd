extends Resource
class_name QuestDefinition
## A single task/quest. Covers main-story beats, residence repairs,
## personal survivor quests, dailies and tutorial steps through one shape.

enum QuestType {
	MAIN_STORY, RESIDENCE_REPAIR, SURVIVOR_PERSONAL, DAILY_TASK,
	SCAVENGING_OBJECTIVE, VEHICLE_REPAIR, DEFENCE_PREPARATION,
	COLLECTION_TASK, TUTORIAL_TASK,
}

@export var id: String
@export var title: String
@export var description: String
@export var quest_type: QuestType = QuestType.MAIN_STORY

## Item requirements as {item_id: count}, matched against the player's
## storage/board by the (Phase 2) merge system.
@export var requirements: Dictionary = {}
@export var prerequisite_quest_ids: PackedStringArray = []
@export var rewards: Dictionary = {}
@export var is_complete: bool = false
@export var dialogue_trigger_id: String = ""
@export var residence_hotspot_id: String = ""
@export var time_condition: String = "" # e.g. "day", "night"; empty == no condition
