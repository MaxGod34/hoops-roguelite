extends Control

@onready var lbl_title = $MainBox/Lbl_PromptTitle
@onready var lbl_cost = $MainBox/Lbl_EnergyCost
@onready var btn_accept = $MainBox/ButtonBox/Btn_Accept
@onready var btn_refuse = $MainBox/ButtonBox/Btn_Refuse

var active_station: Area2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("station_prompt")
	hide()
	
	btn_accept.pressed.connect(_on_accept_pressed)
	btn_refuse.pressed.connect(_on_refuse_pressed)


func open_prompt(station: Area2D, flavor_text: String, energy_cost: int):
	active_station = station
	lbl_title.text = flavor_text
	
	if energy_cost > 0:
		lbl_cost.text = "Cost: " + str(energy_cost) + " Energy"
	else:
		lbl_cost.text = "Cost: FREE"
		
	show()
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = false
		
func _on_accept_pressed():
	if active_station:
		active_station.execute_purchase()
	close_prompt()
	
func _on_refuse_pressed():
	close_prompt()
	
func close_prompt():
	active_station = null
	hide()
	
	if not is_inside_tree(): return
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = true
	
