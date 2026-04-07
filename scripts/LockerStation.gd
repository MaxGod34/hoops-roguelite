extends Area2D

@export_enum("Oracle Film Room", "Offer Libations", "Styx Ice Bath", "Exit to Court",
				"Apollo's Chalk", "Oceanus Bait Shop", "Forge", "Altar") var station_type: String

var player_in_zone: bool = false


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta):
	if player_in_zone and Input.is_action_just_pressed("interact"):
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
		"Exit to Court":
			flavor_text = "Ready to ball?"
			cost = 0
			
	prompt_ui.open_prompt(self, flavor_text, cost)

		
func execute_purchase():
	if station_type == "Exit to Court":
		GameManager.advance_progression()
		GameManager.go_to_court()
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
			
func _on_body_entered(body):
	if body.name == "Player":
		player_in_zone = true
		print("Press Interact to use " + station_type + " (Cost: 1 Energy)")
		
func _on_body_exited(body):
	if body.name == "Player":
		player_in_zone = false
