extends Node

signal stats_updated

# 12 Attribute Matrix
var base_stats = {
	# Shooting
	"close_shot": 50,
	"mid_shot": 50,
	"three_pt": 50,
	# Finishing
	"layups": 50,
	"dunks": 50,
	# Handle/Rebound
	"ball_handling": 50,
	"rebounding": 50,
	# Defense
	"steal": 50,
	"block": 50,
	# Physicals
	"speed_accel": 50,
	"strength": 50,
	# Mach
	"mach": 50
}


var thread_bonuses = {
	# Shooting
	"close_shot": 0,
	"mid_shot": 0,
	"three_pt": 0,
	# Finishing
	"layups": 0,
	"dunks": 0,
	# Handle/Rebound
	"ball_handling": 0,
	"rebounding": 0,
	# Defense
	"steal": 0,
	"block": 0,
	# Physicals
	"speed_accel": 0,
	"strength": 0,
	# Mach
	"mach": 0
}


# Inventory
var equipment = {
	"left_shoe": null,
	"right_shoe": null,
	"left_arm": null,
	"right_arm": null,
	"head": null,
	"outfit": null,
	"ball": null
}



# -- STYX CONTRACTS --
var active_contracts = {}

func advance_game_state():
	var contracts_to_remove = []
	
	for contract in active_contracts:
		active_contracts[contract] -= 1
		if active_contracts[contract] <= 0:
			contracts_to_remove.append(contract)
			
	for contract in contracts_to_remove:
		active_contracts.erase(contract)
		print("Contract Expired: ", contract)


# -- HELPER FUNCTIONS --
func upgrade_stat(stat_name: String, amount: int):
	if base_stats.has(stat_name):
		base_stats[stat_name] += amount
		base_stats[stat_name] = clamp(base_stats[stat_name], 0, 100)
		print(stat_name + " upgraded to: " + str(base_stats[stat_name]))
		


func get_effective_stat(stat_name: String) -> int:
	var base = base_stats.get(stat_name, 0)
	var bonus = thread_bonuses.get(stat_name, 0)
	
	return base + bonus

func apply_thread_bonus(stat_name: String, amount: int):
	if thread_bonuses.has(stat_name):
		thread_bonuses[stat_name] += amount


func recalculate_thread_bonuses():
	# 1. Zero everything out to prevent ghost stats
	for stat in thread_bonuses.keys():
		thread_bonuses[stat] = 0
	
	# 2. Loop through only the items actively on your body
	for slot in equipment.keys():
		var item = equipment[slot]
		
		if item != null and item.has_method("get_boosts"):
			var item_boosts = item.get_boosts()
			
			for stat_name in item_boosts.keys():
				if thread_bonuses.has(stat_name):
					thread_bonuses[stat_name] += item_boosts[stat_name]
	
	# 3. Tell player script the math changed
	stats_updated.emit()


# -- THE STORAGE LCOKER --
var locker_storage = []
const MAX_LOCKER_SLOTS = 3

func stash_equipped_items(slot_name: String):
	
	# Check if there's room
	if locker_storage.size() >= MAX_LOCKER_SLOTS:
		print("Locker is full! Permanently discard something or equip it!")
		return false
	# Check if we have an item in the slot to take off
	if equipment.has(slot_name) and equipment[slot_name] != null:
		locker_storage.append(equipment[slot_name])
		# Remove the item from the player
		equipment[slot_name] = null
		recalculate_thread_bonuses()
		
		print("Item stashed successfully. Your ", slot_name, " slot is now empty.")
		return true
	else:
		print("You aren't wearing anything in that slot!")
		return false

func equip_from_locker(locker_index: int, target_slot: String):
	if locker_index >= 0 and locker_index < locker_storage.size():
		var item_to_equip = locker_storage[locker_index]
		
		# If player is already wearing something in that slot,
		# we have to automatically swap it back to the locker
		var item_taking_off = equipment[target_slot]
		
		# Put new item on player
		equipment[target_slot] = item_to_equip
		
		if item_taking_off != null:
			# Swap the old item into the exact same spot in the locker box
			locker_storage[locker_index] = item_taking_off
			print("Swapped ", target_slot, " with item from locker.")
		else:
			# Empty Handed, remove from locker array
			locker_storage.remove_at(locker_index)
			print("Equipped item from locker.")
		
	recalculate_thread_bonuses()

	
func receive_new_item(new_item: AccessoryData) -> bool:
	var slot = new_item.slot_type
	
	# If slot on your body is empty, auto-equip it
	if equipment.has(slot) and equipment[slot] == null:
		equipment[slot] = new_item
		print("Auto-equipped: ", new_item.item_name)
		recalculate_thread_bonuses()
		return true
	# If body slot is full, check if there is room
	elif locker_storage.size() < 3:
		locker_storage.append(new_item)
		print("Stashed in Kibisis: ", new_item.item_name)
		return true
	# If everything is full, they can't take it
	else:
		print("Inventory is completely full!")
		return false
