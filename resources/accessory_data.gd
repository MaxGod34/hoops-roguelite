extends Resource
class_name AccessoryData

@export var item_name: String = "Unknown Item"
@export_enum("Mortal", "Heroic", "Divine", "Woven") var tier: String = "Mortal"
@export_enum("head", "outfit", "ball", "left_shoe", "right_shoe", "left_arm", "right_arm") var slot_type: String = "ball"
@export var item_texture: Texture2D

# Potential Attribute Buffs
@export var close_shot_bonus: int = 0
@export var mid_shot_bonus: int = 0
@export var three_pt_bonus: int = 0
@export var layups_bonus: int = 0
@export var dunks_bonus: int = 0
@export var ball_handling_bonus: int = 0
@export var speed_bonus: int = 0
@export var strength_bonus: int = 0
@export var steal_bonus: int = 0
@export var block_bonus: int = 0
@export var rebounding_bonus: int = 0
@export var mach_bonus: int = 0
@export var all_attribute_bonus: int = 0

# Unique Passive Effects (ID)
@export var passive_effect: String = ""

func get_boosts() -> Dictionary:
	var boosts = {}
	
	if close_shot_bonus != 0: boosts["close_shot"] = close_shot_bonus
	if mid_shot_bonus != 0: boosts["mid_shot"] = mid_shot_bonus
	if three_pt_bonus != 0: boosts["three_pt"] = three_pt_bonus
	if layups_bonus != 0: boosts["layups"] = layups_bonus
	if dunks_bonus != 0: boosts["dunks"] = dunks_bonus
	if ball_handling_bonus != 0: boosts["ball_handling"] = ball_handling_bonus
	if speed_bonus != 0: boosts["speed_accel"] = speed_bonus # Matches PlayerData name
	if strength_bonus != 0: boosts["strength"] = strength_bonus
	if steal_bonus != 0: boosts["steal"] = steal_bonus
	if block_bonus != 0: boosts["block"] = block_bonus
	if rebounding_bonus != 0: boosts["rebounding"] = rebounding_bonus
	if mach_bonus != 0: boosts["mach"] = mach_bonus
	
	if all_attribute_bonus != 0:
		for stat in ["close_shot", "mid_shot", "three_pt", "layups", "dunks", 
		"ball_handling", "speed_accel", "strength", "steal", "block", "rebounding"]:
			if boosts.has(stat):
				boosts[stat] += all_attribute_bonus
			else:
				boosts[stat] = all_attribute_bonus
	
	return boosts
