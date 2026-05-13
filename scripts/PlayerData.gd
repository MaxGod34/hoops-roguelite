extends Node

signal stats_updated

# 12 Attribute Matrix
var base_stats = {
	"shooting": 50,
	"finishing": 50,
	"handle": 50,
	"defense": 50,
	"speed": 50,
	"strength": 50
}


var thread_bonuses = {
	"shooting": 0,
	"finishing": 0,
	"handle": 0,
	"defense": 0,
	"speed": 0,
	"strength": 0
}


# Inventory (4 orbits | 6 storage)
var active_orbits: Array = [null, null, null, null]
var locker_storage: Array = [null, null, null, null, null, null]

# -- STYX CONTRACTS --
var active_contracts = {}

var orbits_disabled_by_arena: bool = false

func _ready():
	RunTracker.block_achieved.connect(_on_block_achieved)




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
		print(stat_name + " upgraded to: " + str(base_stats[stat_name]))
		stats_updated.emit()
		

func apply_post_game_mach_stats(stat_name: String, amount: int):
	var actual_gain = amount
	
	if GameManager.styx_ice_bath_active:
		actual_gain *= 2
		print("STYX ICE BATH ACTIVE! Post-game gain doubled from ", amount, " to ", actual_gain, "!")
	
	# Route safely back through the normal pipeline
	upgrade_stat(stat_name, actual_gain)

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
	
	
	#--- Wheel Curse Intercept ---
	if GameManager.threads_disabled_next_game: # Update name
		print("Curse active! Thread bonuses are null! NULL!")
		stats_updated.emit()
		return # Exit so it doesn't execute any of the bonuses
	#-----------------------------
	
	# --- ARENA RULE INTERCEPT --- Update later for storage bonuses
	if orbits_disabled_by_arena:
		print("ARENA RULE ACTIVE: Orbits Disabled!")
		stats_updated.emit()
		return
	
	# 2. Loop through only the items actively on your body
	for item in active_orbits:
		
		if item != null and item.has_method("get_boosts"):
			var item_boosts = item.get_boosts()
			
			for stat_name in item_boosts.keys():
				if thread_bonuses.has(stat_name):
					thread_bonuses[stat_name] += item_boosts[stat_name]
	
	# Add here for locker storage buffs ("Combust")
	
	# 3. Tell player script the math changed
	stats_updated.emit()


# -- THE STORAGE LCOKER --
const MAX_LOCKER_SLOTS = 6

	
func receive_new_item(new_item: AccessoryData) -> bool:
	# 1. Check for empty Orbit slot first
	for i in range(active_orbits.size()):
		if active_orbits[i] == null:
			active_orbits[i] = new_item
			print("Auto-equipped to Orbit: ", i, ": ", new_item.item_name)
			recalculate_thread_bonuses()
			return true
	# 2. Orbits full, check empty storage slot
	for i in range(locker_storage.size()):
		if locker_storage[i] == null:
			locker_storage[i] = new_item
			print("Stashed in Kibisis: |", i, "|: ", new_item.item_name)
			return true
	# 3. Everything is full
	print("Inventory is completely full!")
	return false

func swap_items(orbit_index: int, storage_index: int):
	# Swaps item between active and storage
	var temp = active_orbits[orbit_index]
	active_orbits[orbit_index] = locker_storage[storage_index]
	locker_storage[storage_index] = temp
	
	print("Swapped Orbit ", orbit_index, " with Storage", storage_index)
	recalculate_thread_bonuses()


func _on_block_achieved():
	var total_scrub = 0
	
	for item in active_orbits:
		if item != null and "scrub_on_block" in item:
			total_scrub += item.scrub_on_block
	
	if total_scrub > 0:
		GameManager.reduce_opponent_score(total_scrub)
		# RunTracker.track_scrub(total_scrub) Moved to reduce function
		print("SCRUB SUCCESSFUL! Scrubbed: ", total_scrub, " points off the opponent!")
