extends Area2D

@export_enum("The Rewind", "Offer Libations", "Styx Ice Bath", "Exit to Court",
			"Apollo's Chalk", "Oceanus Bait Shop", "Forge", "Altar", "Kibisis",
			"Wheel of Fate", "The Showers", "Scouting Board", 
			"Bargain with the Abyss") var station_type: String

var player_in_zone: bool = false


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta):
	if station_type == "Exit to Court":
		return
	
	if player_in_zone and Input.is_action_just_pressed("interact"):
		
		if GameManager.has_active_mutation("the_leech"):
			# Check if this is blocked
			if station_type == "The Showers" or station_type == "Styx Ice Bath" or station_type == "Altar":
				print("The Leech has drained this station! Cannot use until the end of this Quarter!")
				return # Stop interaction immidiately
		#------------------------------KIBISIS----------------------------------
		if station_type == "Kibisis":
			var kibisis_menu = get_tree().get_first_node_in_group("kibisis_menu")
			if kibisis_menu:
				kibisis_menu.open_menu()
			return
		#-----------------------------------------------------------------------
		#-----------------------------BAIT SHOP---------------------------------
		if station_type == "Oceanus Bait Shop":
			var bait_menu = get_tree().get_first_node_in_group("bait_shop")
			if bait_menu:
				bait_menu.open_menu()
			return
		#-----------------------------------------------------------------------
		#--------------------------------WHEEL----------------------------------
		if station_type == "Wheel of Fate":
			# Find wheel in the scene and open it
			var wheel_menu = get_tree().get_first_node_in_group("locker_wheel")
			if wheel_menu:
				wheel_menu.open_menu()
			return
		#-----------------------------------------------------------------------
		#-----------------------------SCOUTING BOARD----------------------------
		if station_type == "Scouting Board":
			var scout_board = get_tree().get_first_node_in_group("scout_board")
			if scout_board:
				# If already paid, view for free
				if GameManager.is_scouted:
					scout_board.open_menu()
				# If not paid, check energy
				elif GameManager.current_energy >= 2:
					GameManager.current_energy -= 2
					RunTracker.track_energy_spent(2)
					GameManager.is_scouted = true
					print("Scouting Report Purchased!")
					scout_board.open_menu()
				else:
					print("Not enough energy to scout! Cost: 2 energy")
			return
		#-----------------------------------------------------------------------
		#---------------------------THE ALTAR-----------------------------------
		if station_type == "Altar":
			var altar_menu = get_tree().get_first_node_in_group("altar_menu")
			if altar_menu:
				altar_menu.open_menu()
				return
		#-----------------------------------------------------------------------
		#--------------------------THE REWIND-----------------------------------
		if station_type == "The Rewind":
			var rewind_menu = get_tree().get_first_node_in_group("rewind_menu")
			if rewind_menu:
				rewind_menu.open_menu()
				return
		#-----------------------------------------------------------------------
		#----------------------------THE FERRYMAN-------------------------------
		if station_type == "Bargain with the Abyss":
			var bargain_menu = get_tree().get_first_node_in_group("bargain_menu")
			if bargain_menu:
				bargain_menu.open_menu(self)
				return
		#-----------------------------------------------------------------------
		
		
		# Standard Stations (Yes/No Prompt)
		var prompts = get_tree().get_nodes_in_group("station_prompt")
		if prompts.size() > 0 and not prompts[0].visible:
			request_prompt(prompts[0])

func request_prompt(prompt_ui):
	var flavor_text = ""
	var cost = 1
	
	match station_type:
		"Offer Libations":
			flavor_text = "A drink for the divine.\nBank +2 energy next locker room visit"
		"Styx Ice Bath":
			flavor_text = "Numb the body, focus the mind.\nDouble attribute gain next game"
		"Apollo's Chalk":
			flavor_text = "Dust from the sun chariot.\nFirst unblocked shot is guaranteed to go in"
		"Forge":
			flavor_text = "Out of order!\nObtain your lightning bolt to access!"
		"The Showers":
			flavor_text = "Scrub yourself clean.\nScrub 5 off the opponent's score."
	
	prompt_ui.open_prompt(self, flavor_text, cost)

		
func execute_purchase():
	if station_type == "Exit to Court":
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			players[0].walk_through_door(global_position)
		
		# MachMeter, add carryover logic later
		MachManager.reset_to_base()
		TransitionManager.transition_to_scene("res://scenes/MainCourt.tscn")
		return
	
	if GameManager.current_energy >= 1:
		GameManager.current_energy -= 1
		RunTracker.track_energy_spent(1)
		apply_station_effect()
		# This way they can't buy the same station twice in a single visit
		$CollisionShape2D.set_deferred("disabled", true)
		print(station_type + " purchased! Remaining Energy: ", GameManager.current_energy)
	else:
		print("Not enough energy! You need 1 Energy to use this.")
		
func apply_station_effect():
	match station_type:
		
		"Offer Libations":
			GameManager.banked_energy += 2
			print("Meditated! +2 energy next locker room visit")
			
		"Styx Ice Bath":
			GameManager.styx_ice_bath_active = true
			print("Well Recovered! Attribute gain will be doubled next match!")
			
		"Apollo's Chalk":
			GameManager.apollo_chalk_active = true
			print("Chalked: First unblocked shot is a guaranteed perfect release.")
		
		"The Showers":
			GameManager.reduce_opponent_score(5)
			print("Opponent's Score Reduced by 5! Current Opp. Score: ", GameManager.cumulative_opponent_score)
			
func _on_body_entered(body):
	if body.name == "Player":
		player_in_zone = true
		
		# AUTO DOOR
		if station_type == "Exit to Court":
			execute_purchase()
		
		print("Press Interact to use " + station_type + " (Cost: 1 Energy)")
		
func _on_body_exited(body):
	if body.name == "Player":
		player_in_zone = false
