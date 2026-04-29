extends Resource
class_name BaitData

@export_category("Bait Identity")
@export var bait_name: String = "Unknown Lure"
@export_enum("The Scales", "The Deep", "The Undercurrent") var category: String = "The Scales"
@export var cost: int = 1
@export_multiline var description: String = "What does this do?"

@export_category("The Scales (Stat Mods)")
# Leave 0 if it doesn't affect stats
@export var stat_target: String = "" # Strength, ThreePt
@export var stat_boost: int = 0
@export var cap_boost: int = 0
@export var stat_penalty: int = 0 # -9 all stats would be 9

@export_category("Duration Mechanics")
@export_enum("Permanent", "Games", "Charges", "Quarter End") var duration_type: String = "Permanent"
# Only for games or charges (Leave 0 Otherwise)
@export var duration_value: int = 0

@export_category("Custom Logic Hooks")
# Magic key
# Unique string IDs so GameManager or Court can look for it
@export var unique_effect_id: String = "" # e.g. "range_lure", "sirens_call", etc.
