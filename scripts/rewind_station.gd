extends Control

@onready var lbl_title = $VBox/Lbl_Title
@onready var lbl_warning = $VBox/Lbl_Warning
@onready var btn_rewind = $VBox/ButtonRow/Btn_Rewind
@onready var btn_leave = $VBox/ButtonRow/Btn_Leave

func _ready():
	hide()
	btn_leave.pressed.connect(_on_leave_pressed)
	btn_rewind.pressed.connect(_on_rewind_pressed)


func open_menu():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = false
		players[0].velocity = Vector2.ZERO
	
	_refresh_ui()
	show()

func _refresh_ui():
	# 1. Safety Check
	if GameManager.current_game <= 1:
		lbl_warning.text = "The timeline is sealed. You cannot rewind Game 1 of a Quarter."
		lbl_warning.modulate = Color(1.0, 0.2, 0.2)
		btn_rewind.disabled = true
		btn_rewind.text = "SEALED"
	
	# 2. Affordability Check
	elif GameManager.current_energy < GameManager.rewind_base_cost:
		lbl_warning.text = "Requires at least " + str(GameManager.rewind_base_cost) + " Energy to tear the fabric of time!"
		lbl_warning.modulate = Color(0.5, 0.5, 0.5) # Grey
		btn_rewind.disabled = true
		btn_rewind.text = "INSUFFICIENT ENERGY"
	
	# 3. Ready to Rewind
	else:
		lbl_warning.text = "WARNING: Activating the portal consumes ALL remaining energy!"
		lbl_warning.modulate = Color(1.0, 0.8, 0.2) # Golden-ish
		btn_rewind.disabled = false
		btn_rewind.text = "REWIND 1 Game\n(DRAIN ALL ENERGY)"

func _on_rewind_pressed():
	if GameManager.execute_rewind():
		# Add sound effect here later
		_refresh_ui()
		# Update game counters like PauseMenu Run Tracker stuff eventually

func _on_leave_pressed():
	hide()
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = true
		
