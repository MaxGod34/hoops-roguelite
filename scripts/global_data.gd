extends Node

# Current enemy for the match
var current_enemy_id: String = ""
var defeated_enemies: Array[String] = []

# The Encounters Deck
var pools = {
	"LARRY": ["larry_1", "larry_2"],
	"Q1_REGULAR": ["mu_slick", "phi_taxman", "lambda_root"],
	"Q1_BOSS": ["ms_never", "sammy_spice"]
}

# Master Database
var enemy_database = {
	"larry_1": preload("res://resources/enemies/larry_1.tres"),
	"larry_2": preload("res://resources/enemies/larry_2.tres"),
	
	"mu_slick": preload("res://resources/enemies/Q1&Q3Rand/mu_slick.tres"),
	"phi_taxman": preload("res://resources/enemies/Q1&Q3Rand/phi_taxman.tres"),
	"lambda_root": preload("res://resources/enemies/Q1&Q3Rand/lambda_root.tres"),
	
	"ms_never": preload("res://resources/enemies/ms_never.tres"),
	"sammy_spice": preload("res://resources/enemies/sammy_spice.tres")
}


var upgraded_arena_rules = [
	"10_SEC_CLOCK",
	"MAKE_IT_TAKE_IT",
	"NO_TAKEBACKS",
	"LOSE_ON_9",
	"ICE_SKATES"
]


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
		return ""
		
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
	var pool_to_pull = "Q1_REGULAR"
	
	if GameManager.current_game == 1:
		pool_to_pull = "LARRY"
	
	if GameManager.current_game == GameManager.max_games_per_quarter:
		pool_to_pull = "Q1_BOSS"
	
	var next_enemy = GlobalData.pick_random_enemy(pool_to_pull)
	
	if next_enemy == "":
		print("Pool empty!")
		return
	
	current_enemy_id = next_enemy
	print("Scouting report updated: Next opponent is: ", current_enemy_id)
