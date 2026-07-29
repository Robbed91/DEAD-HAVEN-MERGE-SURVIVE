extends Resource
class_name ResidenceHotspot
## One repairable/interactive area within a ResidenceDefinition's scene,
## e.g. "kitchen_windows". The Haven screen renders hotspots by state and
## the quest system flips their state when its required tasks complete.

enum State { DESTROYED, PARTIALLY_CLEARED, UNDER_REPAIR, COMPLETED, UPGRADED }

@export var id: String
@export var display_name: String
@export var area_position: Vector2 = Vector2.ZERO
@export var state: State = State.DESTROYED

## Task ids (see quest_definition.gd) that must complete, in order, to
## advance this hotspot from DESTROYED all the way to UPGRADED.
@export var required_task_ids: PackedStringArray = []

## One scene/animation-set path per State value, so the environment art
## actually changes rather than just a label or icon.
@export var visual_variant_scenes: Dictionary = {}
@export var transition_animation: String = ""
@export var completion_reward: Dictionary = {}
