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
	
	var enemy_name = "the Opponent"
	
	
	var enemy_stats = GlobalData.get_current_enemy_data()
	enemy_name = enemy_stats.defender_name
	lbl_name.text = "You defeated " + enemy_name
	
	
	# Start invisible
	modulate.a = 0.0
	show()
	
	# Create Tween
	var fade_tween = create_tween()
	# Tell Tween to keep running even though game is paused
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# Fade in over 1 second smoothly
	fade_tween.tween_property(self, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_item_claimed(item: AccessoryData):
	# Pipe directly into PlayerData
	PlayerData.receive_new_item(item)
	

func _on_btn_proceed_pressed() -> void:
	get_tree().paused = false
	
	#LockerRoomResets
	GameManager.styx_ice_bath_active = false
	
	#--- Remove Curse(s) ---
	if GameManager.fragments_disabled_next_game:
		GameManager.fragments_disabled_next_game = false
		PlayerData.recalculate_fragment_bonuses() # Give em their bonuses back
	#-----------------------
	GameManager.advance_progression()
	GameManager.prepare_locker_room()
	TransitionManager.transition_to_scene("res://scenes/LockerRoom.tscn")
