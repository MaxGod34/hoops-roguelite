extends PanelContainer

@onready var lbl_name = $VBox/Lbl_Name
@onready var lbl_cost = $VBox/Lbl_Cost
@onready var lbl_duration = $VBox/Lbl_Duration
@onready var lbl_catch = $VBox/Lbl_Catch
@onready var lbl_hook = $VBox/Lbl_Hook

var resize_frames_left: int = 0

func _ready():
	# Make sure to give it a unique group name
	add_to_group("bait_tooltip")
	hide()


func _process(_delta):

	if visible:
		
		if resize_frames_left > 0:
			size = Vector2.ZERO
			resize_frames_left -= 1
		
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

func display_bait(bait: BaitData, in_shop: bool = true):
	lbl_name.text = bait.bait_name
	lbl_cost.text = "Cost: " + str(bait.cost) + " Energy"
	
	var duration_val = "" if bait.duration_value == 0 else str(bait.duration_value) + " "
	lbl_duration.text = "Term: " + duration_val + bait.duration_type
	

	var catch_text = "[pulse color=#55ff55 height=0.0 freq=2]Catch: %s[/pulse]" % bait.catch_description
	
	var hook_text = ""
	
	# Check for wards FIRST, reset flag
	var shows_warded = false
	
	if in_shop and GameManager.aegis_charges > 0:
		shows_warded = true
	elif not in_shop and GameManager.is_mutation_warded(bait.unique_effect_id):
		shows_warded = true
	
	if shows_warded:
		hook_text = "[rainbow freq=0.5 sat=0.6 val=0.8]Hook: %s (WARDED)[/rainbow]" % bait.hook_description
	else:
		hook_text = "[shake rate=20.0 level=5 connected=1][color=#ff4444]Hook: %s[/color][/shake]" % bait.hook_description
	
	lbl_catch.text = catch_text
	lbl_hook.text = hook_text
	
	resize_frames_left = 3

	show()


func hide_tooltip():
	hide()
