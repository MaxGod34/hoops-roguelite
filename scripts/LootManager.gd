extends Node

@export var all_game_items: Array[AccessoryData] = []

func _ready() -> void:
	randomize()

func roll_for_loot():
	var roll = randi() % 100 + 1
	var selected_tier = ""
	
	if roll <= 50:
		selected_tier = "Mortal"
	elif roll <= 80:
		selected_tier = "Heroic"
	else:
		selected_tier = "Divine"
		
	return _get_random_item_from_tier(selected_tier)
	
func _get_random_item_from_tier(target_tier: String):
	var possible_items: Array[AccessoryData] = []
	
	# Search through all resources
	for item in all_game_items:
		if item.tier == target_tier and not GameManager.owned_items.has(item):
			possible_items.append(item)
			
	# Pick a random one
	if possible_items.size() > 0:
		var dropped_item = possible_items.pick_random()
		print("Dropped a " + target_tier + " item: " + dropped_item.item_name)
		return dropped_item
		
	print("Error: No items found in tier " + target_tier)
	return null
