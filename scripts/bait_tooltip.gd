extends PanelContainer

@onready var lbl_name = $VBox/Lbl_Name
@onready var lbl_cost = $VBox/Lbl_Cost
@onready var lbl_duration = $VBox/Lbl_Duration
@onready var lbl_details = $VBox/Lbl_Details


func _ready():
	# Make sure to give it a unique group name
	add_to_group("bait_tooltip")
	hide()


func _process(_delta):
	if visible:
		var mouse_pos = get_global_mouse_position()
		var screen_size = get_viewport_rect().size
		var offset = Vector2.ZERO
#=====================================X=========================================
		if mouse_pos.x < screen_size.x / 2.0 + 128:
			offset.x = 15
		else:
			offset.x = -size.x - 15
#=====================================Y=========================================
		if mouse_pos.y < screen_size.y / 2.0 + 128:
			offset.y = 15
		else:
			offset.y = -size.y - 15

		global_position = mouse_pos + offset

func display_bait(bait: BaitData):
	lbl_name.text = bait.bait_name
	lbl_cost.text = "Cost: " + str(bait.cost) + " Energy"
	
	var duration_val = "" if bait.duration_value == 0 else str(bait.duration_value) + " "
	lbl_duration.text = "Term: " + duration_val + bait.duration_type
	
	lbl_details.text = "\n" + bait.description
	
	size = Vector2.ZERO
	show()

func hide_tooltip():
	hide()
