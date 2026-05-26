extends Control

@onready var kibisis_menu = $"."
@onready var btn_close = $Panel/Btn_Close

@onready var vbox_orbits_left = $Panel/HBoxContainer/VBox_OrbitsLeft
@onready var vbox_orbits_right = $Panel/HBoxContainer/VBox_OrbitsRight
@onready var vbox_storage_left = $Panel/HBoxContainer/VBox_StorageColLeft
@onready var vbox_storage_right = $Panel/HBoxContainer/VBox_StorageColRight

@onready var tooltip = $ItemTooltip

# Swap vars
var selected_type: String = "" # Orbit or Storage
var selected_index: int = -1

func _ready():
	kibisis_menu.visible = false
	btn_close.pressed.connect(close_menu)
	
	var orbit_buttons = vbox_orbits_left.get_children() + vbox_orbits_right.get_children()
	var storage_buttons = vbox_storage_left.get_children() + vbox_storage_right.get_children()
	
	# Orbit Buttons
	for i in range(orbit_buttons.size()):
		orbit_buttons[i].pressed.connect(_on_orbit_pressed.bind(i))
		# Hover signals
		orbit_buttons[i].mouse_entered.connect(_on_orbit_hovered.bind(i))
		orbit_buttons[i].mouse_exited.connect(_hide_tooltip)
		
	# Storage Buttons
	for i in range(storage_buttons.size()):
		storage_buttons[i].pressed.connect(_on_storage_pressed.bind(i))
		# Hover signals
		storage_buttons[i].mouse_entered.connect(_on_storage_hovered.bind(i))
		storage_buttons[i].mouse_exited.connect(_hide_tooltip)




# -- BUTTON ACTIONS --
func _on_orbit_pressed(index: int):
	_hide_tooltip()
	# 1. Is this a swap?
	if selected_type == "Storage":
		PlayerData.swap_items(index, selected_index)
		_clear_selection()
		_refresh_ui()
		return
	
	# 2. Otherwise, we clicked an orbit item
	var item = PlayerData.active_orbits[index]
	if item == null: return # Empty slot 
	
	# 3. Try to auto-send it to the first empty storage slot
	var empty_storage_idx = PlayerData.locker_storage.find(null)
	
	if empty_storage_idx != -1:
		# Auto-Transfer
		PlayerData.swap_items(index, empty_storage_idx)
		_clear_selection()
		_refresh_ui()
	
	else:
		# Storage is full. Select this item to prepare for a swap
		selected_type = "Orbit"
		selected_index = index
		_refresh_ui()
		
func _on_storage_pressed(index: int):
	_hide_tooltip()
	
	# 1. Is this a swap?
	if selected_type == "Orbit":
		PlayerData.swap_items(selected_index, index)
		_clear_selection()
		_refresh_ui()
		return
	
	# 2. Otherwise we clicked a Storage item
	var item = PlayerData.locker_storage[index]
	if item == null: return # Fallback Kick out
	
	# 3. Try to Auto-Send it to the first empty Orbit Slot
	var empty_orbit_idx = PlayerData.active_orbits.find(null)
	
	if empty_orbit_idx != -1:
		# Auto-transfer
		PlayerData.swap_items(empty_orbit_idx, index)
		_clear_selection()
		_refresh_ui()
	else:
		# Orbits are full. Select this item to prepare for a swap
		selected_type = "Storage"
		selected_index = index
		_refresh_ui()

func _clear_selection():
	selected_type = ""
	selected_index = -1

		
# -- UI --
func open_menu():
	kibisis_menu.visible = true
	_clear_selection()
	_refresh_ui()
	# Add freeze player logic later

func close_menu():
	_hide_tooltip()
	_clear_selection()
	kibisis_menu.visible = false
	# Add unfreeze logic later
	
func _refresh_ui():
	# Update equipped column text
	var orbit_buttons = vbox_orbits_left.get_children() + vbox_orbits_right.get_children()
	var storage_buttons = vbox_storage_left.get_children() + vbox_storage_right.get_children()
	
	# --- UPDATE ORBITS ---
	for i in range(orbit_buttons.size()):
		var item = PlayerData.active_orbits[i]
		
		if item != null:
			orbit_buttons[i].text = "Orbit " + str(i+1) + "\n" + item.item_name
			orbit_buttons[i].icon = item.item_texture
			orbit_buttons[i].disabled = false
			
			# Highlight if waiting for a swap
			if selected_type == "Orbit" and selected_index == i:
				orbit_buttons[i].modulate = Color(1.0, 1.0, 0.0)
			else:
				orbit_buttons[i].modulate = Color(1.0, 1.0, 1.0)
		else:
			orbit_buttons[i].text = "Orbit " + str(i+1) + "\n[ EMPTY ]"
			orbit_buttons[i].icon = null
			orbit_buttons[i].modulate = Color(0.4, 0.4, 0.4)
			orbit_buttons[i].disabled = (selected_type != "Storage")
			
	# --- Update storage ---
	for i in range(storage_buttons.size()):
		var item = PlayerData.locker_storage[i]
		if item != null:
			storage_buttons[i].text = "Storage " + str(i+1) + "\n" + item.item_name
			storage_buttons[i].icon = item.item_texture
			storage_buttons[i].disabled = false
			# Highlight if waiting for a swap
			if selected_type == "Storage" and selected_index == i:
				storage_buttons[i].modulate = Color(1.0, 1.0, 0.0)
			else:
				storage_buttons[i].modulate = Color(1.0, 1.0, 1.0)
				
		else:
			storage_buttons[i].text = "Storage " + str(i+1) + "\n[ Empty ]"
			storage_buttons[i].icon = null
			storage_buttons[i].modulate = Color(0.4, 0.4, 0.4)
			# Only allow clicking an empty slot if we have a storage item selected
			storage_buttons[i].disabled = (selected_type != "Orbit")



# --Tooltips & Zone Triggers --
func _on_orbit_hovered(index: int):
	# Only show tooltip if there is an item in the slot
	if PlayerData.active_orbits[index] != null:
		if tooltip:
			tooltip.display_item(PlayerData.active_orbits[index])
			
func _on_storage_hovered(index: int):
	# Only show if there is an item in this locker slot
	if PlayerData.locker_storage[index] != null:
		if tooltip:
			tooltip.display_item(PlayerData.locker_storage[index])
			
func _hide_tooltip():
	if tooltip:
		tooltip.hide_tooltip()
