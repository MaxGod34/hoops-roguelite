extends PanelContainer
@onready var lbl_name = $VBox/Lbl_Name
@onready var lbl_slot = $VBox/Lbl_Slot
@onready var lbl_stats = $VBox/Lbl_Stats
@onready var lbl_description = $VBox/Lbl_Description

var resize_frames_left: int = 0

func _ready():
	add_to_group("tooltip")
	hide()

func _process(_delta):
	# If tooltip is visible, follow the mouse
	if visible:
		if resize_frames_left > 0:
			size = Vector2.ZERO
			resize_frames_left -= 1
			
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
	var stat_text = "[center]"
	var green_hex = "[color=#32ff7e][tornado radius=3.0 freq=8.0]"
	var end_color = "[/tornado][/color]"
	#================================OFF=======================================
	if item.close_shot_bonus > 0: stat_text += "\n" + green_hex + "+" + str(item.close_shot_bonus) + " CLOSE SHOT" + end_color
	if item.mid_shot_bonus > 0: stat_text += "\n" + green_hex + "+" + str(item.mid_shot_bonus) + " MID SHOT" + end_color
	if item.three_pt_bonus > 0: stat_text += "\n" + green_hex + "+" + str(item.three_pt_bonus) + " 3PT" + end_color
	if item.layups_bonus > 0: stat_text += "\n" + green_hex + "+" + str(item.layups_bonus) + " LAYUP" + end_color
	if item.dunks_bonus > 0: stat_text += "\n" + green_hex + "+" + str(item.dunks_bonus) + " DUNK" + end_color
	if item.ball_handling_bonus > 0: stat_text += "\n" + green_hex + "+" + str(item.ball_handling_bonus) + " BALL HANDLE" + end_color
	#===============================DEF/REB/PHYS===============================
	if item.speed_bonus > 0: stat_text += "\n" + green_hex + "+" + str(item.speed_bonus) + " SPD/ACCEL" + end_color
	if item.strength_bonus > 0: stat_text += "\n" + green_hex + "+" + str(item.strength_bonus) + " STRENGTH" + end_color
	if item.mach_bonus > 0: stat_text += "\n"  + green_hex + "+" + str(item.vertical_bonus) + " MACH" + end_color
	if item.steal_bonus > 0: stat_text += "\n"  + green_hex + "+" + str(item.steal_bonus) + " STEAL" + end_color
	if item.block_bonus > 0: stat_text += "\n" + green_hex + "+" + str(item.block_bonus) + " BLOCK" + end_color
	if item.rebounding_bonus > 0: stat_text += "\n" + green_hex + "+" + str(item.rebounding_bonus) + " REBOUND" + end_color
	if item.all_attribute_bonus > 0: stat_text += "\n" + green_hex + "+" + str(item.all_attribute_bonus) + " ALL STATS" + end_color
	
	stat_text += "[/center]"
	
	if stat_text == "[center][/center]":
		stat_text = "[center][color=#aaaaaa]No raw stat bonuses[/color][/center]"
	
	lbl_stats.text = stat_text
	
	if item.description != "":
		var magical_wrapper = "[center][color=#f1c40f][wave amp=20.0 freq=5.0]%s[/wave][/color][/center]"
		lbl_description.text = magical_wrapper % item.description
		lbl_description.show()
	else:
		lbl_description.hide()
	
	size = Vector2.ZERO
	
	resize_frames_left = 3
	
	show()
	
func hide_tooltip():
	hide()
