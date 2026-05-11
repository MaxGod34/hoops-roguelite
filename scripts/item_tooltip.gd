extends PanelContainer
@onready var lbl_name = $VBox/Lbl_Name
@onready var lbl_type = $VBox/Lbl_Type
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
	lbl_type.text = "Type: " + item.primary_category
	
	# Build stat string
	var stat_text = "[center]"
	var green_hex = "[color=#32ff7e][tornado radius=3.0 freq=8.0]"
	var end_color = "[/tornado][/color]"
	#================================OFF=======================================
	if item.shooting_bonus > 0: stat_text += "\n" + green_hex + "+" + str(item.shooting_bonus) + " SHOOTING" + end_color
	if item.finishing_bonus > 0: stat_text += "\n" + green_hex + "+" + str(item.finishing_bonus) + " FINISHING" + end_color
	if item.handle_bonus > 0: stat_text += "\n" + green_hex + "+" + str(item.handle_bonus) + " HANDLE" + end_color
	#===============================DEF/PHYS====================================
	if item.defense_bonus > 0: stat_text += "\n" + green_hex + "+" + str(item.defense_bonus) + " DEFENSE" + end_color
	if item.speed_bonus > 0: stat_text += "\n" + green_hex + "+" + str(item.speed_bonus) + " SPD/ACCEL" + end_color
	if item.strength_bonus > 0: stat_text += "\n" + green_hex + "+" + str(item.strength_bonus) + " STRENGTH" + end_color
	
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
