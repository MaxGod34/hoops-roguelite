extends Area2D

# -- UI References --
@onready var contract_menu = $"../PopUps/ContractMenu"
@onready var lbl_buff = $"../PopUps/ContractMenu/Panel/VBoxContainer/Lbl_Buff"
@onready var lbl_curse = $"../PopUps/ContractMenu/Panel/VBoxContainer/Lbl_Curse"
@onready var btn_sign = $"../PopUps/ContractMenu/Panel/VBoxContainer/HBoxContainer/Btn_Sign"
@onready var btn_refuse = $"../PopUps/ContractMenu/Panel/VBoxContainer/HBoxContainer/Btn_Refuse"

var is_player_near = false
var contract_revealed = false
var current_offer = {}

# Effect Pool
var possible_stats = [
	"close_shot", "mid_shot", "three_pt", "dunks", "layups", "ball_handling",
	"steal", "block", "rebounding","speed_accel", "vertical", "strength"
	]

var possible_curses = [
	{"id": "sisyphus", "desc": "Sisyphus: -50% Speed when holding the ball for 2 games", "duration": 2},
	{"id": "tartarus_anvil", "desc": "Tartarus Anvil: Lose 9 Amps on missed shots for 1 game", "duration": 1},
	{"id": "glass_ankles", "desc": "Glass Ankles: Getting bumped stuns you for 2 games", "duration": 2}
	
]

func _ready():
	contract_menu.visible = false
	
	btn_sign.pressed.connect(_on_sign_pressed)
	btn_refuse.pressed.connect(_on_refuse_pressed)




func _process(_delta: float):
	if is_player_near and Input.is_action_just_pressed("interact") and not contract_menu.visible:
		generate_contract()
			
func generate_contract():
	var reveal_cost = 100
	
	if PlayerData.amps >= reveal_cost:
		PlayerData.amps -= reveal_cost
		
		# Randomly select a buff and a curse
		var chosen_stat = possible_stats.pick_random()
		var chosen_curse = possible_curses.pick_random()
		
		current_offer = {"stat": chosen_stat, "curse": chosen_curse}
		contract_revealed = true
		
		# Update UI
		lbl_buff.text = "OFFERING: +9 to " + chosen_stat.capitalize()
		lbl_curse.text = "CURSE: " + chosen_curse["desc"]
		
		contract_menu.visible = true
		var players = get_tree().get_nodes_in_group("players")
		if players.size() > 0:
			players[0].has_control = false
	else:
		print("Not enough Amps to boogie!")
		
		
func _on_sign_pressed():
	PlayerData.upgrade_stat(current_offer["stat"], 9)
	
	var curse_id = current_offer["curse"]["id"]
	var duration = current_offer["curse"]["duration"]
	PlayerData.active_contracts[curse_id] = duration
	
	print("CONTRACT SIGNED IN BLOOOOOD!")
	close_menu()
	
func _on_refuse_pressed():
	close_menu()
	
func close_menu():
	contract_menu.visible = false
	contract_revealed = false
	current_offer = {}
	
	# UNFREEZE PLAYER
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		players[0].has_control = true
		
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"): is_player_near = true
	


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"): is_player_near = false
