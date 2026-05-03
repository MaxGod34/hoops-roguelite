extends Control

@onready var lbl_energy = $MainLayout/Lbl_Energy
@onready var threads_grid = $MainLayout/ThreadsGrid
@onready var lbl_selection_info = $MainLayout/Lbl_SelectionInfo

@onready var btn_tithe = $MainLayout/ActionRow/Btn_Tithe
@onready var btn_aegis = $MainLayout/ActionRow/Btn_Aegis
@onready var btn_leave = $MainLayout/ActionRow/Btn_Leave

var currently_selected_slot: String = ""


func _ready():
	hide()
	btn_leave.pressed.connect(_on_leave_pressed)
	btn_tithe.pressed.connect(_on_tithe_pressed)
	btn_aegis.pressed.connect(_on_aegis_pressed)


func open_menu():
	# Freeze player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = false
		players[0].velocity = Vector2.ZERO
		
	_refresh_ui()
	show()


func _refresh_ui():
	# Reset selection
	currently_selected_slot = ""
	lbl_selection_info.text = "Select  Thread to sacrifice..."
	btn_tithe.disabled = true
	btn_aegis.disabled = true
	
	lbl_energy.text = "Energy: " + str(GameManager.current_energy)
	
	# Clear old buttons
	for child in threads_grid.get_children():
		child.queue_free()
	
	# Build the 7 top-row inventory buttons
	for slot in PlayerData.equipment.keys():
		var item = PlayerData.equipment[slot]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(128, 128)
		btn.flat = true
		btn.theme = load("res://scenes/lbl_theme_stats_replay.tres")
		
		if item != null:
			btn.icon = item.item_texture
			btn.expand_icon = false
			btn.pressed.connect(_on_item_selected.bind(slot, item))
		else:
			btn.text = "EMPTY"
			btn.disabled = true
			btn.modulate = Color(0.3, 0.3, 0.3)
		
		threads_grid.add_child(btn)


func _on_item_selected(slot_name: String, item: AccessoryData):
	currently_selected_slot = slot_name
	
	# Update the middle info so they know which item they are burning!
	lbl_selection_info.text = "Selected: " + item.item_name + "\n(Clicking a ritual will DESTROY this item forever)"
	
	btn_tithe.disabled = false
	
	if GameManager.current_energy >= 1:
		btn_aegis.disabled = false
	else:
		btn_aegis.disabled = true
	

#=========================================================
# RITUAL EXECUTIONS
#=========================================================
func _on_tithe_pressed():
	if currently_selected_slot == "": return
	
	print("THE TITHE: Burned ", currently_selected_slot, " for 1 Energy!")
	GameManager.current_energy += 1
	_execute_sacrifice()

func _on_aegis_pressed():
	if currently_selected_slot == "" or GameManager.current_energy < 1: return
	
	print("THE AEGIS: Burned", currently_selected_slot, " and spent 1 Energy to gain a Ward!")
	GameManager.current_energy -= 1
	GameManager.aegis_charges += 1
	_execute_sacrifice()

func _execute_sacrifice():
	# 1. Delete the item from the player's body
	PlayerData.equipment[currently_selected_slot] = null
	
	# 2. Tell PlayerData to recalculate stats since a thread has been taken off
	PlayerData.recalculate_thread_bonuses()
	
	# 3. Refresh Altar UI
	_refresh_ui()
#=========================================================

func _on_leave_pressed():
	hide()
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = true
