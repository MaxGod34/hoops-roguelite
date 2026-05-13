extends Node

# =================
# META PROGRESSION
# =================
var current_quarter: int = 1
var current_game: int = 1
var max_games_per_quarter: int = 5
var player_inventory: Array = []
var owned_items: Array[AccessoryData] = []
# =================
# THE GAUNTLET
#==================
var cumulative_opponent_score: int = 0
var max_allowable_score: int = 21


# ==================
# SCENE MANAGEMENT
# ==================
var court_scene: String = "res://scenes/MainCourt.tscn"
var locker_room_scene: String = "res://scenes/LockerRoom.tscn"

# ===============================
# LOCKER ROOM ECONOMY & MODIFIERS
# ===============================
var current_energy: int = 2
var banked_energy: int = 0

# Match Modifiers
var styx_ice_bath_active: bool = false
var apollo_chalk_active: bool = false
var is_scouted: bool = false

# Oceanus Bait Shop
var active_oceanus_buff: String = ""
var active_oceanus_debuff: String = ""
#=========================================
# THE LEDGER (Active Mutations)
# Stores Dicts {"bait": BaitData, "remaining": int}
var active_mutations: Array[Dictionary] = []


# Wheel Flags
var wheel_extra_thread_next_game: bool = false
var start_up_1_0: bool = false
var start_mach_3: bool = false
var threads_disabled_next_game: bool = false
var start_down_0_1: bool = false

# Altar
var aegis_charges: int = 0

# The Rewind
var rewind_base_cost: int = 5

# Phi's TAX
var fragments_disabled_duration: int = 0


func advance_progression():
	PlayerData.orbits_disabled_by_arena = false
	
	trigger_end_of_game_hook()
	
	
	if fragments_disabled_duration > 0:
		fragments_disabled_duration -= 1
	
	
	current_game += 1
	var is_quarter_ending = false
	
	if current_game > max_games_per_quarter:
		current_game = 1
		current_quarter += 1
		is_quarter_ending = true # Quarter-dependent Bait Flag
		
		if current_quarter == 3 or current_quarter == 4:
			max_games_per_quarter = 7
		else:
			max_games_per_quarter = 5
		
		
		# Eventually add final boss stuff here
	
	# Tick Ledger Down
	tick_mutations(is_quarter_ending)
	
	# Roll next enemy
	GlobalData.roll_next_opponent()
	

# -- TRANSITION FUNCTIONS --
func go_to_locker_room():
	get_tree().paused = false
	get_tree().change_scene_to_file(locker_room_scene)
	
func go_to_court():
	get_tree().paused = false
	get_tree().change_scene_to_file(court_scene)
	
func reset_run():
	max_games_per_quarter = 5
	current_quarter = 1
	current_game = 1
	player_inventory.clear()
	cumulative_opponent_score = 0
	current_energy = 2
	banked_energy = 0
	
	clear_match_modifiers()
	owned_items.clear()
	
	# --- Factory Reset All Scaling Fragments cuz Godot hates me <3 ---
	for item in LootManager.all_game_items:
		item.current_compound_stacks = 0
	#------------------------------------------------------------------
	
	# Enemy Vars
	fragments_disabled_duration = 0
	
	GlobalData.roll_next_opponent()
	go_to_court()
	
func prepare_locker_room():
	current_energy = 2 + banked_energy
	banked_energy = 0
	is_scouted = false
	
func clear_match_modifiers():
	styx_ice_bath_active = false
	apollo_chalk_active = false
	is_scouted = false
	
	active_oceanus_buff = ""
	active_oceanus_debuff = ""
	
	wheel_extra_thread_next_game = false
	start_up_1_0 = false
	start_mach_3 = false
	threads_disabled_next_game = false
	start_down_0_1 = false


#============================= BAIT/MUTATIONS ==================================
func process_bait_purchase(bait: BaitData):
	print("Processing Bait: ", bait.bait_name)
	
	
	# --- AEGIS CHECK ---
	var warded = false
	if aegis_charges > 0:
		warded = true
		aegis_charges -= 1
		print("AEGIS TRIGGERED! The curse of ", bait.bait_name, " is nullified!")
	#---------------------
	
	
	
	# Tick downs happen in advance_progression() NOT HERE
	
	# 1. Apply Permanent Scales Stats Instantly
	if bait.category == "The Scales":
		if bait.cap_boost > 0:
			PlayerData.attribute_cap += bait.cap_boost
		
		# Use "All" in Stat Target to apply to all stats
		if bait.stat_target == "All":
			if bait.stat_boost > 0:
				for stat in PlayerData.base_stats.keys():
					PlayerData.upgrade_stat(stat, bait.stat_boost)
			if bait.stat_penalty > 0:
				# WARD Intercept
				if warded:
					print("Aegis blocked permanent stat debuff!")
				else:
					for stat in PlayerData.base_stats.keys():
						# Add a subtraction bool to the upgrade_stats() later
						# Quick & Dirty Subtraction (Replace!)
						PlayerData.base_stats[stat] -= bait.stat_penalty
						PlayerData.base_stats[stat] = max(0, PlayerData.base_stats[stat])
		
		#====================STAT SPECIFIC TARGETS==============================
		elif bait.stat_target != "":
			if bait.stat_boost > 0:
				PlayerData.upgrade_stat(bait.stat_target, bait.stat_boost)
			if bait.stat_penalty > 0:
				# WARD Intercept
				if warded:
					print("Aegis blocked permanent ", bait.stat_target, " penalty!")
				else:
					if PlayerData.base_stats.has(bait.stat_target):
						PlayerData.base_stats[bait.stat_target] -= bait.stat_penalty
						PlayerData.base_stats[bait.stat_target] = max(0, PlayerData.base_stats[bait.stat_target])
		
	# 2. File Mutations INTO the LEDGER
	# Track durations and wacky hooks
	if bait.duration_type != "Permanent" or bait.unique_effect_id != "":
		active_mutations.append({
			"bait": bait,
			"remaining": bait.duration_value,
			"is_warded": warded
		})
		print(bait.bait_name, " added to the Ledger! Type: ", bait.duration_type, " Warded: ", warded)
	
	# 3. SPECIAL CASES (Make a new branch if more than 2 overlap)
	if bait.unique_effect_id == "the_leech":
		current_energy += 5
	
	if bait.unique_effect_id == "sirens_call":
		print("SIRENS CALL BELLOWS! Fast Forwarding to the Quarter Boss!")
		current_game = max_games_per_quarter
		# Immidiately overwrite next opponent that was queued
		GlobalData.roll_next_opponent()
		banked_energy += 10
		print("Sirens Call! 10 Energy banked for next visit!")
		

func tick_mutations(is_quarter_ending: bool):
	var mutations_to_keep: Array[Dictionary] = []
	
	for mutation in active_mutations:
		var bait = mutation["bait"]
		var type = bait.duration_type
		var keep = true
		
		if type == "Games":
			mutation["remaining"] -= 1
			if mutation["remaining"] <= 0:
				keep = false
				print(bait.bait_name, " has expired! Praise be!")
					
		
		elif type == "Quarter End" and is_quarter_ending:
			keep = false
			print("Quarter ended! ", bait.bait_name, " washed away!")
		
		# Finally, only keep non-expired mutations
		if keep:
			mutations_to_keep.append(mutation)
	
	active_mutations = mutations_to_keep

#===============================================================================
# MUTATION HELPERS
#===============================================================================

func has_active_mutation(effect_id: String) -> bool:
	for mutation in active_mutations:
		if mutation["bait"].unique_effect_id == effect_id:
			return true
	return false

func consume_charge(effect_id: String):
	# Loop backward to safely delete if it hits 0
	for i in range(active_mutations.size() -1, -1, -1):
		var mutation = active_mutations[i]
		
		if mutation["bait"].unique_effect_id == effect_id and mutation["bait"].duration_type == "Charges":
			mutation["remaining"] -= 1
			print(mutation["bait"].bait_name, " triggered! Charges left: ", mutation["remaining"])
		
			if mutation["remaining"] <= 0:
				print(mutation["bait"].bait_name, " charges depleted! Mutation washed away!")
				active_mutations.remove_at(i)

func is_mutation_warded(effect_id: String) -> bool:
	for mutation in active_mutations:
		if mutation["bait"].unique_effect_id == effect_id:
			return mutation.get("is_warded", false)
	return false


# --- REWIND TIME ---
func can_rewind() -> bool:
	if current_game <= 1: return false
	if current_energy < rewind_base_cost: return false
	return true

func execute_rewind():
	if can_rewind():
		print("THE THREADS OF TIME FOLD BACK 1 GAME!")
		current_game -= 1
		
		var nrg_snap = current_energy
		var diff = 0
		
		current_energy = 0 # Energy is always completely consumed no matter the excess
		diff = nrg_snap # 10-10, diff = 10
		RunTracker.track_energy_spent(diff)
		
		return true
		
	return false

func reduce_opponent_score(amount: int):
	var original_score = GameManager.cumulative_opponent_score
	var amount_reduced = 0
	
	GameManager.cumulative_opponent_score -= amount
	GameManager.cumulative_opponent_score = max(0, GameManager.cumulative_opponent_score)
	amount_reduced = original_score - GameManager.cumulative_opponent_score
	
	RunTracker.track_scrub(amount_reduced)

#===================================================================================================
# EVENT PIPELINE
#===================================================================================================
func trigger_pre_game_hook(current_bot_score: int) -> int:
	var modified_bot_score = current_bot_score
	if has_active_mutation("style_more"):
		modified_bot_score += 2
		print("Bait Debuff: Style More starts the bot up an additional 2 pts! Good grief!")
		
	return modified_bot_score

func trigger_pre_shot_hook(shooter: Node2D, attempted_points: int) -> int:
	var modified_points = attempted_points
	
	# Only affect the player's shots for Range Lure
	if shooter.name == "Player" and has_active_mutation("range_lure"):
		if attempted_points == 3:
			modified_points += 1
			print("Range Lure Active! 3-pter boosted by 1!")
		elif attempted_points == 2:
			modified_points -= 1
			print("Range Lure Active! 2-pter reduced by 1! AWUH SHUCKS!")
			
	return modified_points

func trigger_post_shot_hook(scorer: Node2D, is_dunk: bool, current_player_score: int, current_bot_score: int) -> Dictionary:
	var scores = {"player": current_player_score, "bot": current_bot_score}
	
	# ICARUS DELAY
	if scorer.name == "Player" and is_dunk and has_active_mutation("icarus_delay"):
		print("ICARUS DELAY! Flew too close to the sun...Score resets to 0!")
		scores["player"] = 0
		
	# Kinetic Potential
	if scorer.name != "Player" and has_active_mutation("kinetic_cannon"):
		print("KINETIC CANNON DEBUFF! Bot steals an extra point!")
		scores["bot"] += 1
	
	return scores

func trigger_turnover_hook(violator: Node2D, current_player_score: int) -> int:
	var new_score = current_player_score
	
	if violator.name == "Player" and has_active_mutation("relaxed_butter"):
		if is_mutation_warded("relaxed_butter"):
			print("Aegis protects your score! Turnovers still consume a charge!")
		else:
			print("Relaxed Butter Penalty! -2 pts!")
			new_score -= 2
			new_score = max(0, new_score)
			
		consume_charge("relaxed_butter")
		
	return new_score

#===============================================================================
# END OF GAME PIPELINE
#===============================================================================
func trigger_end_of_game_hook():
	print("--- RUNNING END OF GAME HOOKS ---")
	
	# 1. Check Active Orbit Slots (Valid only for Orbit and Combust Items)
	for item in PlayerData.active_orbits:
		if item != null and item.primary_category in ["Orbit", "Combust"]:
			_process_item_compound(item)
			
	# 2. Check Storage (Valid only for Debris Fragments)
	for item in PlayerData.locker_storage:
		if item != null and item.primary_category == "Debris":
			_process_item_compound(item)
	
	# Force a stat recalculation because base stats on items might have grown
	PlayerData.recalculate_thread_bonuses()

func _process_item_compound(item: AccessoryData):
	# Type 1: Instant Effects (Harvest/Scrubbing)
	if item.scrub_on_game_end > 0:
		reduce_opponent_score(item.scrub_on_game_end)
		print(item.item_name, " Harvest Triggered! Scrubbed ", item.scrub_on_game_end, " points!")
	
	# Type 2: Stat Scaling (Compound)
	if item.compound_stat_target != "":
		item.current_compound_stacks += 1
		var total_growth = item.compound_amount * item.current_compound_stacks
		print(item.item_name, " Compounded! (+", total_growth, " to ", item.compound_stat_target, ")")
