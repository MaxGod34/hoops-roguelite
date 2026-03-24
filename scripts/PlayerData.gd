extends Node

# 12 Attribute Matrix
var stats = {
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
	"vertical": 50
}

# Inventory
var equipment = {
	"left_shoe": null,
	"right_shoe": null,
	"left_arm": null,
	"right_arm": null,
	"headwear": null,
	"outfit": null,
	"ball": null
}

# Stat Upgrade Currency (Placeholder name)
var amps = 500

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
	if stats.has(stat_name):
		stats[stat_name] += amount
		stats[stat_name] = clamp(stats[stat_name], 0, 100)
		print(stat_name + " upgraded to: " + str(stats[stat_name]))
		
		
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
		
		
func _ready():
	equipment["left_shoe"] = load("res://items/shoes/stone_sandal.tres")
	equipment["ball"] = load("res://items/balls/eight_ball.tres")
	equipment["left_arm"] = load("res://items/arms/mummy_wrap.tres")
