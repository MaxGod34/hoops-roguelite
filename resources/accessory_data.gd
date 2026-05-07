extends Resource
class_name AccessoryData

@export var item_name: String = "Unknown Item"
@export_enum("Mortal", "Heroic", "Divine", "Woven") var tier: String = "Mortal"
@export_enum("head", "outfit", "ball", "left_shoe", "right_shoe", "left_arm", "right_arm") var slot_type: String = "ball"
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
	
	return boosts
