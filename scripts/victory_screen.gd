extends Control

@onready var lbl_name = $MainBox/Lbl_Title
@onready var btn_proceed = $MainBox/Btn_Proceed
@onready var reward_container = $MainBox/RewardContainer

@export var reward_button_scene: PackedScene

var current_reward: Dictionary = {}
var pending_reward: AccessoryData = null


func _ready():
	hide()

	
func show_victory(rewards: Array[AccessoryData]):
	# Clear old buttons
	for child in reward_container.get_children():
		child.queue_free()
		
	# Generate a button for every item passed in
	for item in rewards:
		if item != null:
			var new_btn = reward_button_scene.instantiate()
			reward_container.add_child(new_btn)
			new_btn.setup(item)
			
			# Listen for if player takes the item
			new_btn.item_claimed.connect(_on_item_claimed)

	# FIANLLY, show screen
	show()

func _on_item_claimed(item: AccessoryData):
	# Pipe directly into PlayerData
	PlayerData.receive_new_item(item)
	

func _on_btn_proceed_pressed() -> void:
	get_tree().paused = false
	GameManager.go_to_locker_room()
