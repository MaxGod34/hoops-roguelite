extends Node

# =================
# META PROGRESSION
# =================
var current_olympus_tier: int = 1
var player_inventory: Array = []

# Base Attributes
var player_3pt_rating: int = 50
var player_layup_rating: int = 50
var player_speed: float = 500.0

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


# -- TRANSITION FUNCTIONS --
func go_to_locker_room():
	get_tree().paused = false
	get_tree().change_scene_to_file(locker_room_scene)
	
func go_to_court():
	get_tree().paused = false
	get_tree().change_scene_to_file(court_scene)
	
func reset_run():
	current_olympus_tier = 1
	player_inventory.clear()
	player_3pt_rating = 50
	player_layup_rating = 50
	player_speed = 500.0
	
	current_energy = 2
	banked_energy = 0
	
	clear_match_modifiers()
	
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
