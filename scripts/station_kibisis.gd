extends Area2D

@onready var kibisis_menu = $CanvasLayer/KibisisMenu
@onready var btn_close = $CanvasLayer/KibisisMenu/Panel/Btn_Close

@onready var vbox_equipped_head_outfit_ball = $CanvasLayer/KibisisMenu/Panel/HBoxContainer/VBox_Equipped_Head_Oufit_Ball
@onready var vbox_equipped_arms = $CanvasLayer/KibisisMenu/Panel/HBoxContainer/VBox_Equipped_Arms
@onready var vbox_equipped_shoes = $CanvasLayer/KibisisMenu/Panel/HBoxContainer/VBox_Equipped_Shoes
@onready var vbox_storage = $CanvasLayer/KibisisMenu/Panel/HBoxContainer/VBox_Storage

var is_player_near = false

func _ready():
	kibisis_menu.visible = false
	btn_close.pressed.connect(_close_menu)
	
	var equip_buttons = vbox_equipped_head_outfit_ball.get_children() + vbox_equipped_shoes.get_children() + vbox_equipped_arms.get_children()
	
	var slot_names = ["head", "outfit", "ball", "left_shoe", "right_shoe", "left_arm", "right_arm"]
	
	for i in range(equip_buttons.size()):
		equip_buttons[i].pressed.connect(_on_stash_pressed.bind(slot_names[i]))
		
	var storage_buttons = vbox_storage.get_children()
	for i in range(storage_buttons.size()):
		storage_buttons[i].pressed.connect(_on_retrieve_pressed.bind(i))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	if is_player_near and Input.is_action_just_pressed("interact"):
		if not kibisis_menu.visible:
			_open_menu()


# -- BUTTON ACTIONS --
func _on_stash_pressed(slot_name: String):
	# Try to put item in box using Autoload logic
	var success = PlayerData.stash_equipped_items(slot_name)
	if success:
		_refresh_ui()
		
func _on_retrieve_pressed(locker_index: int):
	# Check if there's actually an item in this slot before trying to equip it
	if locker_index < PlayerData.locker_storage.size():
		var item = PlayerData.locker_storage[locker_index]
		# Need item's dictionary to tell what slot it belongs to
		var target_slot = item["slot_type"]
		
		PlayerData.equip_from_locker(locker_index, target_slot)
		_refresh_ui()
		
# -- UI --
func _open_menu():
	kibisis_menu.visible = true
	_refresh_ui()
	# Add freeze player logic later

func _close_menu():
	kibisis_menu.visible = false
	# Add unfreeze logic later
	
func _refresh_ui():
	# Update equipped column text
	var equip_buttons = vbox_equipped_head_outfit_ball.get_children() + vbox_equipped_shoes.get_children() + vbox_equipped_arms.get_children()
	var slot_names = ["head", "outfit", "ball", "left_shoe", "right_shoe", "left_arm", "right_arm"]
	
	for i in range(equip_buttons.size()):
		var slot = slot_names[i]
		
		if PlayerData.equipment.has(slot) and PlayerData.equipment[slot] != null:
			equip_buttons[i].text = "Stash " + PlayerData.equipment[slot].item_name
			equip_buttons[i].icon = PlayerData.equipment[slot].item_texture
			equip_buttons[i].disabled = false
			
		else:
			equip_buttons[i].text = slot.capitalize() + " (Empty)"
			equip_buttons[i].icon = null
			equip_buttons[i].disabled = true
			
	# Update storage column text
	var storage_buttons = vbox_storage.get_children()
	for i in range(storage_buttons.size()):
		if i < PlayerData.locker_storage.size():
			storage_buttons[i].text = "Equip " + PlayerData.locker_storage[i].item_name
			storage_buttons[i].icon = PlayerData.locker_storage[i].item_texture
			storage_buttons[i].disabled = false
		else:
			storage_buttons[i].text = "[ Empty Slot ]"
			storage_buttons[i].icon = null
			storage_buttons[i].disabled = true
			
	# -- Zone Triggers --
	
	

func _on_body_entered(body):
	if body.is_in_group("player"): is_player_near = true
	



func _on_body_exited(body):
	if body.is_in_group("player"):
		is_player_near = false
		_close_menu()
