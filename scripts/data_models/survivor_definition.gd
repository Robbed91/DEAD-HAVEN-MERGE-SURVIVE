extends Resource
class_name SurvivorDefinition
## A recruitable/companion character. Kept data-only so writers can add
## survivors without touching gameplay code.

@export var id: String
@export var display_name: String
@export var role: String
@export var biography: String
@export var personality_traits: PackedStringArray = []
@export var skills: PackedStringArray = []

## Portrait/expression keys map to scene or texture paths; see
## ART_ASSET_GUIDE.md (added in a later phase) for the full required set
## (neutral, speaking, concerned, angry, happy, injured, scavenging outfit,
## residence outfit).
@export var portraits: Dictionary = {}
@export var expressions: Dictionary = {}

@export var personal_quest_id: String = ""
@export var relationship_links: PackedStringArray = [] # ids of survivors this one has an authored relationship with

@export var trust: int = 0
@export var health: int = 100
@export var morale: int = 70
@export var is_recruited: bool = false
@export var assigned_residence_id: String = ""
@export var injury_state: String = "healthy"
