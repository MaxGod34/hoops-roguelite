extends Node

# Current enemy for the match
var current_enemy_id: String = ""
var defeated_enemies: Array[String] = []

# The Encounters Deck
var pools = {
	"Q1": ["tree_mcgee", "speed_glove", "ms_never"]
}

# Master Database
var enemy_database = {
	"tree_mcgee": preload("res://enemies/tree_mcgee.tres"),
	"speed_glove": preload("res://enemies/speed_glove.tres"),
	"ms_never": preload("res://enemies/ms_never.tres")
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
