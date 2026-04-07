extends CanvasLayer

@onready var lbl_name = $MainBox/HBoxContainer/Lbl_ItemName
@onready var lbl_slot_type = $MainBox/HBoxContainer/Lbl_ItemSlot
@onready var lbl_item_stats = $MainBox/Lbl_ItemStats
@onready var btn_take = $MainBox/ButtonBox/Btn_TakeIt
@onready var btn_leave = $MainBox/ButtonBox/Btn_LeaveIt
@onready var icon_rect = $MainBox/IconRect_Reward

var current_reward: Dictionary = {}
var pending_reward: AccessoryData = null


func _ready():
	hide()
	btn_take.pressed.connect(_on_take_pressed)
	btn_leave.pressed.connect(_on_leave_pressed)
	
func show_victory(reward: AccessoryData):
	pending_reward = reward
	# Null Check
	if reward == null:
		print("Error: No reward generated!")
		show()
		return
	
	lbl_name.text = reward.item_name
	lbl_slot_type.text = "Slot: " + reward.slot_type.capitalize()
	if reward.item_texture != null:
		icon_rect.texture = reward.item_texture
	
	var stat_text = ""
	#================================OFF=======================================
	if reward.close_shot_bonus > 0:
		stat_text += "+" + str(reward.close_shot_bonus) + " CLOSE SHOT "
	if reward.mid_shot_bonus > 0:
		stat_text += "+" + str(reward.mid_shot_bonus) + " MID SHOT "
	if reward.three_pt_bonus > 0:
		stat_text += "+" + str(reward.three_pt_bonus) + " 3PT "
	if reward.layups_bonus > 0:
		stat_text += "+" + str(reward.layups_bonus) + " LAYUP "
	if reward.dunks_bonus > 0:
		stat_text += "+" + str(reward.dunks_bonus) + " DUNK "
	if reward.ball_handling_bonus > 0:
		stat_text += "+" + str(reward.ball_handling_bonus) + " BALL HANDLE "
	#===============================DEF/REB/PHYS===============================
	if reward.speed_bonus > 0:
		stat_text += "+" + str(reward.speed_bonus) + " SPD/ACCEL "
	if reward.strength_bonus > 0:
		stat_text += "+" + str(reward.strength_bonus) + " STRENGTH "
	if reward.vertical_bonus > 0:
		stat_text += "+" + str(reward.vertical_bonus) + " VERTICAL "
	if reward.steal_bonus > 0:
		stat_text += "+" + str(reward.steal_bonus) + " STEAL "
	if reward.block_bonus > 0:
		stat_text += "+" + str(reward.block_bonus) + " BLOCK "
	if reward.rebounding_bonus > 0:
		stat_text += "+" + str(reward.rebounding_bonus) + " REBOUND "
		
	if stat_text == "":
		stat_text = "No raw stat bonuses"
		
	
	lbl_item_stats.text = stat_text
	
	# Change color for tier later here
	
	
	# FIANLLY, show screen
	show()

func _on_take_pressed():
	if GameManager.player_inventory.size() < 7:
		GameManager.owned_items.append(pending_reward)
		PlayerData.receive_new_item(pending_reward)
		print("Item Taken! Inventory size: ", GameManager.player_inventory.size())
		print("Item added to inventory: ", pending_reward.item_name)
	else:
		print("Inventory full! Dropping item!")
		
	GameManager.go_to_locker_room()
	
func _on_leave_pressed():
	print("Item left behind.")
	GameManager.go_to_locker_room()
