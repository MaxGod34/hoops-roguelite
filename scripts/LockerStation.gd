extends Area2D

@export_enum("Oracle Film Room", "Offer Libations", "Styx Ice Bath", "Exit to Court",
			"Apollo's Chalk", "Oceanus Bait Shop", "Forge", "Altar", 
			"Wheel of Fate", "The Showers", "Scouting Board") var station_type: String

var player_in_zone: bool = false


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta):
	if station_type == "Exit to Court":
		return
	
	if player_in_zone and Input.is_action_just_pressed("interact"):
		#-----------------------------------WHEEL-------------------------------
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
					GameManager.is_scouted = true
					print("Scouting Report Purchased!")
					scout_board.open_menu()
				else:
					print("Not enough energy to scout! Cost: 2 energy")
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
		"Oracle Film Room":
			flavor_text = "You watch yourself on camera, man?\nNegates enemy abilities for 2 possessions"
		"Offer Libations":
			flavor_text = "A drink for the divine.\nBank +2 energy next locker room visit"
		"Styx Ice Bath":
			flavor_text = "Numb the body, focus the mind.\nDouble attribute gain next game"
		"Apollo's Chalk":
			flavor_text = "Dust from the sun chariot.\nFirst unblocked shot is guaranteed to go in"
		"Oceanus Bait Shop":
			flavor_text = "Take the bait\nVoluntary difficulty spikes for targeted stat buffs"
		"Forge":
			flavor_text = "Out of order!\nObtain your lightning bolt to access!"
		"The Showers":
			flavor_text = "Embrace the dark and decompress.\nRaise attribute cap by 5."
			
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
		apply_station_effect()
		# This way they can't buy the same station twice in a single visit
		$CollisionShape2D.set_deferred("disabled", true)
		print(station_type + " purchased! Remaining Energy: ", GameManager.current_energy)
	else:
		print("Not enough energy! You need 1 Energy to use this.")
		
func apply_station_effect():
	match station_type:
		"Oracle Film Room":
			GameManager.oracle_scourt_active = true
			print("Scouted: Enemy abilities negated for 2 possessions")
		
		"Offer Libations":
			GameManager.banked_energy += 2
			print("Meditated! +2 energy next locker room visit")
			
		"Styx Ice Bath":
			GameManager.styx_ice_bath_active = true
			print("Well Recovered! Attribute gain will be doubled next match!")
			
		"Apollo's Chalk":
			GameManager.apollo_chalk_active = true
			print("Chalked: First unblocked shot is a guaranteed perfect release.")
			
		"Oceanus Bait Shop":
			GameManager.active_oceanus_buff = "+15 3pt Rating"
			GameManager.active_oceanus_debuff = "-10 Speed"
			print("Took the bait! Gained 3pt rating, but lost speed")
		
		"The Showers":
			PlayerData.attribute_cap += 5
			print("Attribute Cap raised by 5 to a cap of: ", PlayerData.attribute_cap)
			
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
