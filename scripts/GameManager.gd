extends Node

# =================
# META PROGRESSION
# =================
var current_quarter: int = 1
var current_game: int = 1
var max_games_per_quarter: int = 7
var player_inventory: Array = []
var owned_items: Array[AccessoryData] = []


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
var oracle_scourt_active: bool = false
var styx_ice_bath_active: bool = false
var apollo_chalk_active: bool = false


# Oceanus Bait Shop
var active_oceanus_buff: String = ""
var active_oceanus_debuff: String = ""

# Wheel Flags
var wheel_extra_thread_next_game: bool = false
var start_up_1_0: bool = false
var start_mach_3: bool = false
var threads_disabled_next_game: bool = false
var start_down_0_1: bool = false


func advance_progression():
	current_game += 1
	if current_game > max_games_per_quarter:
		current_game = 1
		current_quarter += 1
		
		# Eventually add final boss stuff here

# -- TRANSITION FUNCTIONS --
func go_to_locker_room():
	get_tree().paused = false
	get_tree().change_scene_to_file(locker_room_scene)
	
func go_to_court():
	get_tree().paused = false
	get_tree().change_scene_to_file(court_scene)
	
func reset_run():
	current_quarter = 1
	current_game = 1
	player_inventory.clear()

	
	current_energy = 2
	banked_energy = 0
	
	clear_match_modifiers()
	
	owned_items.clear()
	
	go_to_court()
	
func prepare_locker_room():
	current_energy = 2 + banked_energy
	banked_energy = 0
	
func clear_match_modifiers():
	oracle_scourt_active = false
	styx_ice_bath_active = false
	apollo_chalk_active = false
	
	active_oceanus_buff = ""
	active_oceanus_debuff = ""
	
	wheel_extra_thread_next_game = false
	start_up_1_0 = false
	start_mach_3 = false
	threads_disabled_next_game = false
	start_down_0_1 = false
