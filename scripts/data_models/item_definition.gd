extends Resource
class_name ItemDefinition
## Static definition of one item in a merge chain (e.g. "Scrap Wood, level 1").
## BoardItem (see board_item.gd) is the runtime instance placed on the grid;
## ItemDefinition is the shared, never-mutated template it points to.

enum Rarity { COMMON, UNCOMMON, RARE, STORY }

@export var id: String
@export var display_name: String
@export var description: String
@export var chain_id: String
@export var level: int = 1
@export var max_level_in_chain: int = 7
@export var icon_path: String
@export var scene_path: String
@export var sell_value: int = 0
@export var rarity: Rarity = Rarity.COMMON

## If true this item is a producer: tapping it spawns items from
## produces_item_id at its current charge/cooldown rate.
@export var is_producer: bool = false
@export var produces_item_id: String = ""
@export var producer_charges: int = -1 # -1 == unlimited
@export var producer_cooldown_seconds: float = 0.0

## Free-form tags used by the quest system to match "any level-3 construction
## item" style requirements without hard-coding item ids into quest data.
@export var task_tags: PackedStringArray = []

## Coins/energy/tokens granted the first time this item is ever discovered.
@export var discovery_reward: Dictionary = {}
