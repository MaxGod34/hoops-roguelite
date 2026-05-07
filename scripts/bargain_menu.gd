extends Control

@onready var panel_hidden = $MainPanel/Panel_Hidden
@onready var panel_revealed = $MainPanel/Panel_Revealed

@onready var lbl_hidden_title = $MainPanel/Panel_Hidden/VBoxHidden/Lbl_Hidden_Title

@onready var lbl_revealed_title = $MainPanel/Panel_Revealed/VBoxRevealed/Lbl_Revealed_Title
@onready var lbl_curse_title = $MainPanel/Panel_Revealed/VBoxRevealed/Lbl_Curse_Title
@onready var lbl_curse_desc = $MainPanel/Panel_Revealed/VBoxRevealed/Lbl_Curse_Desc

@onready var btn_reveal = $MainPanel/Panel_Hidden/VBoxHidden/BtnRow/Btn_Reveal
@onready var btn_leave = $MainPanel/Panel_Hidden/VBoxHidden/BtnRow/Btn_Leave

@onready var btn_accept = $MainPanel/Panel_Revealed/VBoxRevealed/BtnRow/Btn_Accept
@onready var btn_decline = $MainPanel/Panel_Revealed/VBoxRevealed/BtnRow/Btn_Decline

# Load curse pool to the ferryman
var curse_pool: Array = [	# Glued Shoes, Scrubless, Threadless
	preload("res://resources/StyxCurses/glued_shoes.tres"),
	preload("res://resources/StyxCurses/scrubless.tres"),
	preload("res://resources/StyxCurses/threadless.tres")
]

var contract_state: String = "HIDDEN" # HIDDEN, REVEALED, RESOLVED
var current_curse: BaitData = null
var current_station: Area2D = null



func _ready() -> void:
	hide()
	btn_reveal.pressed.connect(_on_reveal_pressed)
	btn_leave.pressed.connect(_on_decline_pressed)
	btn_accept.pressed.connect(_on_accept_pressed)
	btn_decline.pressed.connect(_on_decline_pressed)


func open_menu(station: Area2D):
	current_station = station
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = false
		players[0].velocity = Vector2.ZERO
	
	# Reset state for this specific visit
	contract_state = "HIDDEN"
	current_curse = null
	
	_refresh_ui()
	show()

func _refresh_ui():
	if contract_state == "HIDDEN":
		panel_revealed.hide()
		panel_hidden.show()
		
		# Energy check for the toll
		if GameManager.current_energy >= 1:
			btn_reveal.disabled = false
			lbl_hidden_title.text = "Pay 1 Energy\nto Reveal Contract"
		else:
			btn_reveal.disabled = true
			lbl_hidden_title.text = "Not Enough Energy (1)"
	
	elif contract_state == "REVEALED":
		panel_hidden.hide()
		panel_revealed.show()
		var duration = current_curse.duration_value
		
		lbl_curse_title.text = "CURSE: " + current_curse.bait_name
		lbl_curse_desc.text = current_curse.hook_description + "\n(" + str(duration) + " GAMES)"
		

func _on_reveal_pressed():
	if GameManager.current_energy > 1: 
		GameManager.current_energy -= 1
		RunTracker.track_energy_spent(1)
		
		# Generate deal
		current_curse = curse_pool.pick_random()
		contract_state = "REVEALED"
		
		# Add effects here latah
		_refresh_ui()

func _on_accept_pressed():
	print("The Ferryman laughs! CONTRACT SIGNED IN BLOOOOD!")
	
	# 1. The Reward: Clear Opp Score to 0 (Guaranteed)
	var amount_scrubbed = GameManager.cumulative_opponent_score
	GameManager.reduce_opponent_score(amount_scrubbed)
	
	# 2. Add to the Ledger
	GameManager.process_bait_purchase(current_curse)
	
	contract_state = "RESOLVED"
	_close_and_disable()

func _on_decline_pressed():
	print("You walked away from the Ferryman...")
	contract_state = "RESOLVED"
	_close_and_disable()

func _close_and_disable():
	hide()
	
	# Turn off station so they can't return this visit
	if current_station != null:
		current_station.get_node("CollisionShape2D").set_deferred("disabled", true)
	
	# Unfreeze player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = true
	
