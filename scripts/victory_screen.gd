extends CanvasLayer

@onready var item_desc = $MainBox/Lbl_ItemDesc
@onready var btn_take = $MainBox/ButtonBox/Btn_TakeIt
@onready var btn_leave = $MainBox/ButtonBox/Btn_LeaveIt

var current_reward: Dictionary = {}


func _ready():
	hide()
	btn_take.pressed.connect(_on_take_pressed)
	btn_leave.pressed.connect(_on_leave_pressed)
	
func show_victory(reward_data: Dictionary):
	current_reward = reward_data
	
	item_desc.text = reward_data["name"] + "\n" + reward_data["description"]
	
	show()

func _on_take_pressed():
	if GameManager.player_inventory.size() < 3:
		GameManager.player_inventory.append(current_reward)
		print("Item Taken! Inventory size: ", GameManager.player_inventory.size())
	else:
		print("Inventory full! Dropping item!")
		
	GameManager.go_to_locker_room()
	
func _on_leave_pressed():
	print("Item left behind.")
	GameManager.go_to_locker_room()
