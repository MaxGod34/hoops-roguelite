extends Control

@export_category("Bait Pools")
@export var scales_pool: Array[BaitData] = []
@export var deep_pool: Array[BaitData] = []
@export var undercurrent_pool: Array[BaitData] = []

@onready var lbl_energy = $CenterContainer/MainPanel/VBoxContainer/Lbl_Energy
@onready var btn_leave = $CenterContainer/MainPanel/VBoxContainer/Btn_Leave

@onready var row_scales = $CenterContainer/MainPanel/VBoxContainer/Row_Scales
@onready var row_deep = $CenterContainer/MainPanel/VBoxContainer/Row_Deep
@onready var row_undercurrent = $CenterContainer/MainPanel/VBoxContainer/Row_Undercurrent

var shop_generated: bool = false


func _ready():
	visible = false
	btn_leave.pressed.connect(_on_leave_pressed)



func open_menu():
	# 1. Update Energy Display
	lbl_energy.text = "Energy: " + str(GameManager.current_energy)
	
	# 2. Freeze the player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = false
		players[0].velocity = Vector2.ZERO
	
	# Generate the bait once per visit
	if not shop_generated:
		generate_shop()
		shop_generated = true
	
	
	# 3. Start it completely off-screen at the BOTTOM
	var screen_height = get_viewport_rect().size.y
	position.y = screen_height
	visible = true
	
	# 4. Rise from the deep!
	var slide_tween = create_tween()
	slide_tween.tween_property(self, "position:y", 0.0, 0.6)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)


#================================================
# SHOP GENERATION & DRAFTING
#================================================
func generate_shop():
	_populate_row(row_scales, scales_pool)
	_populate_row(row_deep, deep_pool)
	_populate_row(row_undercurrent, undercurrent_pool)


func _populate_row(row_node: HBoxContainer, pool: Array[BaitData]):
	# --- HIGHLANDER RULE ---
	# Only allow Permanent baits OR temp baits that aren't currently active
	var valid_pool = pool.filter(func(b):
		return b.duration_type == "Permanent" or not GameManager.has_active_mutation(b.unique_effect_id)
	)
	#------------------------
	
	# 1. Separate Pool By Cost
	var cost_1_baits = valid_pool.filter(func(b): return b.cost == 1)
	var cost_2_baits = valid_pool.filter(func(b): return b.cost == 2)
	
	# 2. Shuffle em up bb
	cost_1_baits.shuffle()
	cost_2_baits.shuffle()
	
	# 3. Strict Slot Assignment [1-Cost] [1-Cost] [2-Cost]
	var slot_assignments = [null, null, null]
	
	if cost_1_baits.size() > 0: slot_assignments[0] = cost_1_baits[0]
	if cost_1_baits.size() > 1: slot_assignments[1] = cost_1_baits[1]
	if cost_2_baits.size() > 0: slot_assignments[2] = cost_2_baits[0]
	
	# 4. Assign them to the physical UI buttons
	var buttons = row_node.get_children()
	for i in range(buttons.size()):
		var btn = buttons[i]
		
		# Disconnect old signals so clicking a button doesn't buy 5 things at once
		_disconnect_all_signals(btn)
		
		var assigned_bait = slot_assignments[i]
		
		if assigned_bait != null:
			# Valid items go here
			btn.disabled = false
			btn.modulate = Color(1, 1, 1, 1)
			btn.visible = true
			btn.text = ""
			setup_bait_button(btn, assigned_bait)
		
		else:
			# --- UI CONSISTENCY IN CASE OF SUPPLY ISSUES ---
			btn.visible = true # Hide the button if out of test data
			btn.disabled = true
			btn.text = "OUT OF STOCK" # YOU BOUGHT IT ALL lol
			btn.icon = null
			btn.modulate = Color(0.3, 0.3, 0.3, 1)
			#------------------------------------------------



func setup_bait_button(button_node: Button, bait: BaitData):
	# Set texture
	button_node.icon = bait.sprite
	
	# Hover on
	button_node.mouse_entered.connect(func():
		$BaitTooltip.display_bait(bait)
	)
	
	# Hover off
	button_node.mouse_exited.connect(func():
		$BaitTooltip.hide_tooltip()	
	)
	
	# Purchase Logic
	button_node.pressed.connect(_on_bait_purchased.bind(bait, button_node))


#======================================================
# PURCHASE LOGIC
#======================================================
func _on_bait_purchased(bait: BaitData, button_node: Button):
	if GameManager.current_energy >= bait.cost:
		GameManager.current_energy -= bait.cost
		RunTracker.track_energy_spent(bait.cost)
		
		print("Purchased Bait: ", bait.bait_name)
		
		# Send to GameManager LEDGER
		GameManager.process_bait_purchase(bait)
		
		# Update Lbl
		lbl_energy.text = "Energy: " + str(GameManager.current_energy)
		
		# Mark as sold out
		button_node.disabled = true
		button_node.text = "SOLD OUT!"
		button_node.modulate = Color(0.3, 0.3, 0.3, 1)
		$BaitTooltip.hide_tooltip()
	
	else:
		print("Not enough energy for ", bait.bait_name, "!")




# Helpers

func _disconnect_all_signals(node: Node):
	for sig in ["pressed", "mouse_entered", "mouse_exited"]:
		for connection in node.get_signal_connection_list(sig):
			node.disconnect(sig, connection.callable)


func _on_leave_pressed():
	var screen_height = get_viewport_rect().size.y
	
	# 1. Sink Back Into THE DEEP
	var slide_tween = create_tween()
	slide_tween.tween_property(self, "position:y", screen_height, 0.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
	
	await slide_tween.finished
	visible = false
	
	# 2. Unfreeze Player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = true
