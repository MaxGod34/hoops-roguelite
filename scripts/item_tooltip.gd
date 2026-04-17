extends PanelContainer
@onready var lbl_name = $VBox/Lbl_Name
@onready var lbl_slot = $VBox/Lbl_Slot
@onready var lbl_stats = $VBox/Lbl_Stats

func _ready():
	add_to_group("tooltip")
	hide()

func _process(_delta):
	# If tooltip is visible, follow the mouse
	if visible:
		var mouse_pos = get_global_mouse_position()
		var offset = Vector2.ZERO
		if mouse_pos.x < (get_viewport().size.x / 2.0) + 120:
			offset.x = 15
			#offset = Vector2(15, -size.y / 2.0)
		else:
			offset.x = -size.x - 15
			#offset = Vector2(-size.x - 15, -size.y / 2.0)
		
		if mouse_pos.y < (get_viewport().size.y / 2.0) + 80:
			offset.y = size.y / 2.0
		else:
			offset.y = -size.y * 1.5

		
		global_position = mouse_pos + offset
		

func display_item(item: AccessoryData):
	lbl_name.text = item.item_name
	lbl_slot.text = "Slot: " + item.slot_type.capitalize()
	
	# Build stat string
	var stat_text = ""
	#================================OFF=======================================
	if item.close_shot_bonus > 0: stat_text += "\n+" + str(item.close_shot_bonus) + " CLOSE SHOT "
	if item.mid_shot_bonus > 0: stat_text += "\n+" + str(item.mid_shot_bonus) + " MID SHOT "
	if item.three_pt_bonus > 0: stat_text += "\n+" + str(item.three_pt_bonus) + " 3PT "
	if item.layups_bonus > 0: stat_text += "\n+" + str(item.layups_bonus) + " LAYUP "
	if item.dunks_bonus > 0: stat_text += "\n+" + str(item.dunks_bonus) + " DUNK "
	if item.ball_handling_bonus > 0: stat_text += "\n+" + str(item.ball_handling_bonus) + " BALL HANDLE "
	#===============================DEF/REB/PHYS===============================
	if item.speed_bonus > 0: stat_text += "\n+" + str(item.speed_bonus) + " SPD/ACCEL "
	if item.strength_bonus > 0: stat_text += "\n+" + str(item.strength_bonus) + " STRENGTH "
	if item.vertical_bonus > 0: stat_text += "\n+" + str(item.vertical_bonus) + " VERTICAL "
	if item.steal_bonus > 0: stat_text += "\n+" + str(item.steal_bonus) + " STEAL "
	if item.block_bonus > 0: stat_text += "\n+" + str(item.block_bonus) + " BLOCK "
	if item.rebounding_bonus > 0: stat_text += "\n+" + str(item.rebounding_bonus) + " REBOUND "
	if item.all_attribute_bonus > 0: stat_text += "\n+" + str(item.all_attribute_bonus) + " ALL STATS "
	
	
	if stat_text == "":
		stat_text = "No raw stat bonuses"
	
	lbl_stats.text = stat_text
	

	
	show()
	
func hide_tooltip():
	hide()
