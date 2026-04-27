extends Node2D
# ---------------- UI REFERENCES ------------------
@onready var upgrade_menu = $UpgradeMenu
@onready var lbl_energy_wall = $Lbl_EnergyWall

var player_in_zone = false


func _ready() -> void:
	# Old whiteboard
	upgrade_menu.visible = false
	lbl_energy_wall.text = "ENERGY: " + str(GameManager.current_energy)




func _on_zone_upgrades_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_zone = true
		# Add a prompt later


func _on_zone_upgrades_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_zone = false

# Interaction Logic
func _process(_delta: float) -> void:
	lbl_energy_wall.text = "ENERGY: " + str(GameManager.current_energy)
	
	if player_in_zone and not upgrade_menu.visible and Input.is_action_just_pressed("interact"):
		open_menu()
		
func open_menu():
	upgrade_menu.visible = true
	# Find player and freeze them
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = false
		
func _on_close_button_pressed():
	upgrade_menu.visible = false
	
	# Find player unfreeze them
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = true
