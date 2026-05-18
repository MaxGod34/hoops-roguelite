extends Node

# Current enemy for the match
var current_enemy_id: String = ""
var defeated_enemies: Array[String] = []

# The Encounters Deck
var pools = {
	"LARRY": ["larry_1", "larry_2"],
	"Q1Q3_RANDOM": ["epsilon_error", "eta_siphon", "gamma_well", "kappa_dampener", "lambda_root", "mu_slick", "omicron_blur", "phi_taxman", "tau_anchor"],
	"Q1_BOSS": ["the_broker", "the_monolith", "the_warden"],
	"Q2Q4_RANDOM": ["beta_decay", "nu_tar", "omega_limit", "theta_eraser", "xi_auditor", "zeta_blitz"],
	"Q2_BOSS": ["hash_grid", "hourglass_pendulum", "the_infinite"]
}

# Master Database
var enemy_database = {
	# Larrys (2)
	"larry_1": preload("res://resources/enemies/Larrys/larry_1.tres"), # N/A
	"larry_2": preload("res://resources/enemies/Larrys/larry_2.tres"), # N/A
	# Q1/Q3 Rand Pool (9/12)
	"epsilon_error": preload("res://resources/enemies/Q1&Q3Rand/epsilon_error.tres"), # MARGIN_OF_ERROR, FATAL_ERROR
	"eta_siphon": preload("res://resources/enemies/Q1&Q3Rand/eta_siphon.tres"), #ENERGY_SAP, ENTROPIC_ETA
	"gamma_well": preload("res://resources/enemies/Q1&Q3Rand/gamma_well.tres"), # HIGH_GRAVITY, EVENT_HORIZON
	"kappa_dampener": preload("res://resources/enemies/Q1&Q3Rand/kappa_dampener.tres"), # STIFF_AIR, RIGID_AIR
	"lambda_root": preload("res://resources/enemies/Q1&Q3Rand/lambda_root.tres"), #DISABLE_CROSSOVERS, DEEP_ROOT
	"mu_slick": preload("res://resources/enemies/Q1&Q3Rand/mu_slick.tres"), #SLIPPERY_FLOOR, ABSOLUTE_MU
	"omicron_blur": preload("res://resources/enemies/Q1&Q3Rand/omicron_blur.tres"), # BLURRED_VISION, MYOPIA
	"phi_taxman": preload("res://resources/enemies/Q1&Q3Rand/phi_taxman.tres"), #NO_FRAGMENTS, BANKRUPT_PHI
	"tau_anchor": preload("res://resources/enemies/Q1&Q3Rand/tau_anchor.tres"), # ANCHORED_BALL, LEAD_BALL
	# Q1 Bosses (3)
	"the_broker": preload("res://resources/enemies/Q1Boss/diamond_the_broker.tres"), # HIGH_STAKES
	"the_monolith": preload("res://resources/enemies/Q1Boss/rectangle_the_monolith.tres"), # CRUSHING_MASS
	"the_warden": preload("res://resources/enemies/Q1Boss/eye_the_warden.tres"), # NO_BLINDSPOTS
	# Q2/Q4 Rand Pool (6/12)
	"beta_decay": preload("res://resources/enemies/Q2&Q4Rand/beta_decay.tres"), # BETA_DECAY, CHAIN_REACTION
	"nu_tar": preload("res://resources/enemies/Q2&Q4Rand/nu_tar.tres"), # ABSOLUTE_VISCOCITY, # FOSSILIZED
	"omega_limit": preload("res://resources/enemies/Q2&Q4Rand/omega_limit.tres"), # TERMINAL_VELOCITY, DEFINED_LIMIT
	"theta_eraser": preload("res://resources/enemies/Q2&Q4Rand/theta_the_eraser.tres"), # SCRUB_ALL, ASYMMETRIC_VOID
	"xi_auditor": preload("res://resources/enemies/Q2&Q4Rand/xi_the_auditor.tres"), # ORBITS_DISABLED 
	"zeta_blitz": preload("res://resources/enemies/Q2&Q4Rand/zeta_the_blitz.tres"), # HALF_Shot_Clock, THIRD_SHOT_CLOCK
	# Q2 Bosses (3)
	"hash_grid": preload("res://resources/enemies/Q2Boss/hash_the_grid.tres"), # DAMPENED_OUTPUT
	"hourglass_pendulum": preload("res://resources/enemies/Q2Boss/hourglass_the_pendulum.tres"), # VALUE_INVERSION
	"the_infinite": preload("res://resources/enemies/Q2Boss/the_infinite.tres") # MAKE_IT_TAKE_IT
	# Campe/Kampe (0/3)
	# Cronus (0/6)
	# Larry100 (0/1)
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
