extends Resource
class_name AccessoryData

@export var item_name: String = "Unknown Item"
@export_enum("Mortal", "Heroic", "Divine", "Woven") var tier: String = "Mortal"
@export_enum("Orbit", "Debris", "Combust") var primary_category: String = "Orbit"
@export var item_texture: Texture2D
@export_multiline var description: String = ""

# Potential Attribute Buffs
@export var shooting_bonus: int = 0
@export var finishing_bonus: int = 0
@export var handle_bonus: int = 0
@export var defense_bonus: int = 0
@export var speed_bonus: int = 0
@export var strength_bonus: int = 0
@export var all_attribute_bonus: int = 0

# SCRUBBING CATEGORY
@export_category("Scrubbing (The Wash)")
@export var scrub_on_game_end: int = 0
@export var scrub_on_block: int = 0
@export var scrub_on_steal: int = 0
@export var scrub_on_mach_dunk: int = 0

# OPPONENT DEBUFF CATEGORY
@export_category("Opponent Debuffs")
@export var opp_shooting_debuff: int = 0
@export var opp_finishing_debuff: int = 0
@export var opp_handle_debuff: int = 0
@export var opp_defense_debuff: int = 0
@export var opp_speed_debuff: int = 0
@export var opp_strength_debuff: int = 0

@export_category("End of Game Scaling (Compound)")
@export var compound_stat_target: String = "" # "shooting", "finishing" etc.
@export var compound_amount: int = 0
# Hidden variable tracks how many times this item has scaled
var current_compound_stacks: int = 0

@export_group("Special Synergies")
@export var energy_per_visit: int = 0
@export var double_dunk_points: bool = false
@export var bonus_max_mach: int = 0
@export var styx_multiplier_override: int = 0


# Unique Passive Effects (ID)
@export var passive_effect: String = ""

func get_boosts() -> Dictionary:
	var boosts = {}
	
	if shooting_bonus != 0: boosts["shooting"] = shooting_bonus
	if finishing_bonus != 0: boosts["finishing"] = finishing_bonus
	if handle_bonus != 0: boosts["handle"] = handle_bonus
	if defense_bonus != 0: boosts["defense"] = defense_bonus
	if speed_bonus != 0: boosts["speed"] = speed_bonus # Matches PlayerData name
	if strength_bonus != 0: boosts["strength"] = strength_bonus

	
	if all_attribute_bonus != 0:
		for stat in ["shooting", "finishing", "handle", 
						"defense", "speed", "strength"]:
			if boosts.has(stat):
				boosts[stat] += all_attribute_bonus
			else:
				boosts[stat] = all_attribute_bonus
	
	#----------------------------- COMPOUND MATH -------------------------------
	if compound_stat_target != "" and current_compound_stacks > 0:
		var total_bonus = compound_amount * current_compound_stacks
		if boosts.has(compound_stat_target):
			boosts[compound_stat_target] += total_bonus
		else:
			boosts[compound_stat_target] = total_bonus
	
	return boosts
