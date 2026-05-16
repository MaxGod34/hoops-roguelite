extends Node

# Current enemy for the match
var current_enemy_id: String = ""
var defeated_enemies: Array[String] = []

# The Encounters Deck
var pools = {
	"LARRY": ["larry_1", "larry_2"],
	"Q1Q3_RANDOM": ["eta_siphon", "lambda_root", "mu_slick", "phi_taxman"],
	"Q1_BOSS": ["the_broker", "the_monolith", "the_warden"],
	"Q2Q4_RANDOM": ["theta_eraser", "xi_auditor", "zeta_blitz"],
	"Q2_BOSS": ["hash_grid", "hourglass_pendulum", "the_infinite"]
}

# Master Database
var enemy_database = {
	# Larrys
	"larry_1": preload("res://resources/enemies/Larrys/larry_1.tres"),
	"larry_2": preload("res://resources/enemies/Larrys/larry_2.tres"),
	# Q1/Q3 Rand Pool
	"eta_siphon": preload("res://resources/enemies/Q1&Q3Rand/eta_siphon.tres"),
	"lambda_root": preload("res://resources/enemies/Q1&Q3Rand/lambda_root.tres"),
	"mu_slick": preload("res://resources/enemies/Q1&Q3Rand/mu_slick.tres"),
	"phi_taxman": preload("res://resources/enemies/Q1&Q3Rand/phi_taxman.tres"),
	# Q1 Bosses
	"the_broker": preload("res://resources/enemies/Q1Boss/diamond_the_broker.tres"),
	"the_monolith": preload("res://resources/enemies/Q1Boss/rectangle_the_monolith.tres"),
	"the_warden": preload("res://resources/enemies/Q1Boss/eye_the_warden.tres"),
	# Q2/Q4 Rand Pool
	"theta_eraser": preload("res://resources/enemies/Q2&Q4Rand/theta_the_eraser.tres"), # All_Points_Scrub
	"xi_auditor": preload("res://resources/enemies/Q2&Q4Rand/xi_the_auditor.tres"), # Orbits_Disabled
	"zeta_blitz": preload("res://resources/enemies/Q2&Q4Rand/zeta_the_blitz.tres"), # 1/2_Shot_Clock
	# Q2 Bosses
	"hash_grid": preload("res://resources/enemies/Q2Boss/hash_the_grid.tres"), # 1/2_Shooting_Finishing
	"hourglass_pendulum": preload("res://resources/enemies/Q2Boss/hourglass_the_pendulum.tres"), # Clock_Pendulum
	"the_infinite": preload("res://resources/enemies/Q2Boss/the_infinite.tres") # Make_It_Take_It
	# Campe/Kampe
	# Cronus
	# Larry100
}



func _ready():
	randomize()

func pick_random_enemy(pool_name: String) -> String:
	if not pools.has(pool_name):
		push_error("ERROR: Pool '" + pool_name + "' does not exist!")
		return ""
	
	var available_enemies = []
	
	# Filter out the enemies already beaten
	for enemy_id in pools[pool_name]:
		if not defeated_enemies.has(enemy_id):
			available_enemies.append(enemy_id)
	
	# Safety Net: If you beat them all?
	if available_enemies.size() == 0:
		print("WARNING: All enemies in ", pool_name, " defeated! Resetting pool!")
		for enemy_id in pools[pool_name]:
			defeated_enemies.erase(enemy_id)
		available_enemies = pools[pool_name].duplicate()
		
	return available_enemies.pick_random()


func mark_current_enemy_defeated():
	if current_enemy_id != "" and not defeated_enemies.has(current_enemy_id):
		defeated_enemies.append(current_enemy_id)
		print(current_enemy_id, " has been added to the graveyard!")


func get_current_enemy_data() -> DefenderStats:
	if enemy_database.has(current_enemy_id):
		return enemy_database[current_enemy_id]
	return null

func roll_next_opponent():
	var quarter = GameManager.current_quarter
	var game = GameManager.current_game
	var max_games = GameManager.max_games_per_quarter
	var pool_to_pull = ""
	
	# 1. Larry Check
	if game == 1:
		pool_to_pull = "LARRY"
	
	# 2. Boss Check
	elif game == max_games:
		match quarter:
			1: pool_to_pull = "Q1_BOSS"
			2: pool_to_pull = "Q2_BOSS"
			3: pool_to_pull = "Q1_BOSS" # Campe Placeholder
			4: pool_to_pull = "Q2_BOSS" # Cronus Placeholder
			_: pool_to_pull = "Q2_BOSS" # Safety Fallback
			
	# 3. The Random Encounters
	else:
		if quarter == 1 or quarter == 3:
			pool_to_pull = "Q1Q3_RANDOM"
		else:
			pool_to_pull = "Q2Q4_RANDOM"
	
	# Execute
	var next_enemy = pick_random_enemy(pool_to_pull)
	
	if next_enemy == "":
		print("CRITICAL ERROR: Failed to pull an enemy!")
		return
	
	current_enemy_id = next_enemy
	print("Scouting report updated: Q", quarter, " Game ", game, " is against: ", current_enemy_id)
