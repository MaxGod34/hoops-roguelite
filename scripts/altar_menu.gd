extends Control

@onready var lbl_energy = $MainLayout/Lbl_Energy
@onready var hbox_orbits = $MainLayout/HBox_Orbits
@onready var hbox_storage = $MainLayout/HBox_Storage
@onready var lbl_selection_info = $MainLayout/Lbl_SelectionInfo

@onready var btn_tithe = $MainLayout/ActionRow/Btn_Tithe
@onready var btn_aegis = $MainLayout/ActionRow/Btn_Aegis
@onready var btn_attonement = $MainLayout/ActionRow/Btn_Atonement
@onready var btn_leave = $MainLayout/ActionRow/Btn_Leave

var selected_source: String = "" # Orbit or Storage
var selected_index: int = -1


func _ready():
	hide()
	btn_leave.pressed.connect(_on_leave_pressed)
	btn_tithe.pressed.connect(_on_tithe_pressed)
	btn_aegis.pressed.connect(_on_aegis_pressed)
	btn_attonement.pressed.connect(_on_attonement_pressed)


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
	selected_source = ""
	selected_index = -1
	lbl_selection_info.text = "Select a Fragment to sacrifice..."
	btn_tithe.disabled = true
	btn_tithe.release_focus()
	btn_aegis.disabled = true
	btn_aegis.release_focus()
	btn_attonement.disabled = true
	btn_attonement.release_focus()
	
	
	lbl_energy.text = "Energy: " + str(GameManager.current_energy)
	
	# Clear old buttons
	for child in hbox_orbits.get_children():
		child.queue_free()
	for child in hbox_storage.get_children():
		child.queue_free()
	
	# Build the 4 Orbit Buttons
	for i in range(PlayerData.active_orbits.size()):
		var item = PlayerData.active_orbits[i]
		var btn = _create_inventory_button(item, "Orbit", i)
		hbox_orbits.add_child(btn)
		
	# Build the 6 Storage Buttons
	for i in range(PlayerData.locker_storage.size()):
		var item = PlayerData.locker_storage[i]
		var btn = _create_inventory_button(item, "Storage", i)
		hbox_storage.add_child(btn)

func _create_inventory_button(item: AccessoryData, source: String, index: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(128, 128)
	btn.flat = true
	btn.theme = load("res://scenes/lbl_theme_stats_replay.tres")
	
	if item != null:
		btn.icon = item.item_texture
		btn.expand_icon = false
		btn.pressed.connect(_on_item_selected.bind(source, index, item))
		btn.mouse_entered.connect(_on_item_hovered.bind(item))
		btn.mouse_exited.connect(_on_item_mouse_exit)
	else:
		btn.text = source + "\nEMPTY"
		btn.disabled = true
		btn.modulate = Color(0.3, 0.3, 0.3)
	
	return btn

func _on_item_hovered(item: AccessoryData):
	$ItemTooltip.display_item(item)
	
func _on_item_mouse_exit():
	$ItemTooltip.hide()

func _on_item_selected(source: String, index: int, item: AccessoryData):
	selected_source = source
	selected_index = index
	
	# Update the middle info so they know which item they are burning!
	lbl_selection_info.text = "Selected: " + item.item_name + "\n(Clicking a ritual will DESTROY this fragment forever)"
	
	btn_tithe.disabled = false
	btn_aegis.disabled = GameManager.current_energy < 1
	btn_attonement.disabled = GameManager.cumulative_opponent_score <= 0
	

#=========================================================
# RITUAL EXECUTIONS
#=========================================================
func _on_tithe_pressed():
	if selected_source == "": return
	
	print("THE TITHE: Burned fragment from ", selected_source, " ", selected_index, " for 1 Energy!")
	GameManager.current_energy += 1
	RunTracker.add_fragment_burned("Tithe") 
	_execute_sacrifice()

func _on_aegis_pressed():
	if selected_source == "" or GameManager.current_energy < 1: return
	
	print("THE AEGIS: Burned fragment from ", selected_source, " ", selected_index, " and spent 1 Energy to gain a Ward!")
	GameManager.current_energy -= 1
	RunTracker.track_energy_spent(1)
	RunTracker.add_fragment_burned("Aegis") 
	GameManager.aegis_charges += 1
	_execute_sacrifice()

func _on_attonement_pressed():
	if selected_source == "": return
	
	print("ATTONEMENT: Burned fragment from ", selected_source, " ", selected_index, " to scrub 3 points!")
	
	GameManager.reduce_opponent_score(3)
	RunTracker.add_fragment_burned("Attonement") 
	_execute_sacrifice()


func _execute_sacrifice():
	# 1. Delete the item from the correct array
	if selected_source == "Orbit":
		PlayerData.active_orbits[selected_index] = null
	elif selected_source == "Storage":
		PlayerData.locker_storage[selected_index] = null
	
	# 2. Tell PlayerData to recalculate stats since a fragment has been taken off
	PlayerData.recalculate_fragment_bonuses()
	
	# 3. Refresh Altar UI
	_refresh_ui()
#=========================================================

func _on_leave_pressed():
	hide()
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = true
