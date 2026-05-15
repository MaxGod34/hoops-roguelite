extends Control

@onready var wheel_rect = $WheelTexture
@onready var btn_spin = $HBoxContainer/Btn_Spin
@onready var btn_leave = $HBoxContainer/Btn_Leave
@onready var lbl_result = $Lbl_Result

#--------------------FOR IMPLEMENTATION, GUARANTEE SPIN-------------------------
@export_enum("+10 All Attributes", "+5 Energy", "+1 Fragment Next Game (MAX 1)",
	"Start Next Game Up 1-0", "Start Next Game at Mach 3",
	"NOTHING!", "Lose Random Fragment", "Fragments Disabled 1 Game", "Start Next Game Down 0-1",
	"Re-spin!", "N/A") var guaranteed_spin: String = "N/A"
#-------------------------------------------------------------------------------

var is_spinning: bool = false

# OFFICIAL WHEEL ROSTER (10 SLICES)
var wheel_rewards = [
	# POSITIVES
	"+10 All Attributes",
	"+5 Energy",
	"+1 Fragment Next Game (MAX 1)",
	"Start Next Game Up 1-0",
	"Start Next Game at Mach 3",
	# NEGATIVES
	"NOTHING!",
	"Lose Random Fragment",
	"Fragments Disabled 1 Game",
	"Start Next Game Down 0-1",
	# AGAIN!
	"Re-spin!"
]


func _ready():
	lbl_result.text = "Cost: 1 Energy"
	btn_spin.pressed.connect(_on_spin_pressed)
	btn_leave.pressed.connect(_on_leave_pressed)


func open_menu():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = false
		players[0].velocity = Vector2.ZERO
	
	if GameManager.current_energy > 0:
		btn_spin.disabled = false
	else:
		btn_spin.disabled = true
	
	# 1. Calculate the screen height to know exactly how far to hide it
	var screen_height = get_viewport_rect().size.y
	
	# 2. Snap it off-screen to the top, then turn visiblity on
	position.y = -screen_height
	visible = true
	
	# 3. Slide it down with a bounce
	var slide_tween = create_tween()
	slide_tween.tween_property(self, "position:y", 0.0, 0.75)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)



func _on_spin_pressed():
	if is_spinning: return
	
	# Add energy check here
	if GameManager.current_energy < 1: return
	
	GameManager.current_energy -= 1
	RunTracker.track_energy_spent(1)
	
	is_spinning = true
	lbl_result.text = "Spinning..."
	btn_spin.disabled = true
	
	spin_the_wheel()


func spin_the_wheel():
	var slice_count = wheel_rewards.size()
	var degrees_per_slice = 360.0 / slice_count
	
	# 1. Pick a random winner
	var winning_index = randi() % slice_count
	# Guarantee spin, if needed gets passed
	if guaranteed_spin != "N/A": winning_index = wheel_rewards.find(guaranteed_spin) 
	
	# 2. Calculate Target Angle
	# Because the image is mapped counter-clockwise, index * slice_degrees bring the winning slice to the top
	var target_angle = winning_index * degrees_per_slice
	
	# Add slight random offset so the pointer isn't always dead center
	var offset = randf_range(-degrees_per_slice / 2.5, degrees_per_slice / 2.5)
	
	# 3. Add 5 full extra roations for the "spin" visual effect
	var total_rotation = (5 * 360.0) + target_angle + offset
	
	# 4. Tween it bb
	var spin_tween = create_tween()
	spin_tween.tween_property(wheel_rect, "rotation_degrees", total_rotation, 4.0)\
		.set_trans(Tween.TRANS_QUART)\
		.set_ease(Tween.EASE_OUT)
	
	# 5. When the wheel stops, trigger results
	spin_tween.finished.connect(_on_spin_finished.bind(winning_index))

func _on_spin_finished(winning_index: int):
	var reward_text = wheel_rewards[winning_index]
	lbl_result.text = reward_text
	print("Wheel landed on: ", reward_text)
	
	# Reset rotation under the hood so it doesn't spin to infinity on multiple clicks
	wheel_rect.rotation_degrees = fmod(wheel_rect.rotation_degrees, 360.0)
	
	apply_reward(reward_text)
	
	# Only unlock button if it wasn't a respin
	if reward_text != "Re-spin!":
		is_spinning = false


func apply_reward(reward: String):
	match reward:
		"+10 All Attributes":
			print("JACKPOT! +10 to all stats!")
			for stat in PlayerData.base_stats.keys():
				PlayerData.upgrade_stat(stat, 10)
		
		"+5 Energy":
			GameManager.current_energy += 5
		
		"+1 Fragment Next Game (MAX 1)":
			print("Loot Incoming!")
			GameManager.wheel_extra_fragment_next_game = true # Re-name to fragment
		
		"Start Next Game Up 1-0":
			print("Spot me a point! Start up 1-0!")
			GameManager.start_up_1_0 = true
		
		"Start Next Game at Mach 3":
			print("Pre-game hype!")
			GameManager.start_mach_3 = true
		
		#====================================
		
		"NOTHING!":
			print("Tough break! Nothing happens.")
		
		"Lose Random Fragment":
			print("BRUTAL! Snatching a frag...")
			lose_random_fragment()
		
		"Fragments Disabled 1 Game":
			print("Naked run! Fragments disabled next match!")
			GameManager.fragments_disabled_next_game = true # Re-name
			# Force update so their UI instantly shows
			PlayerData.recalculate_fragment_bonuses()
		
		"Start Next Game Down 0-1":
			print("Get out of the hole! Start down 0-1")
			GameManager.start_down_0_1 = true
		
		"Re-spin!":
			print("Run it back!")
			await get_tree().create_timer(1.0).timeout
			spin_the_wheel()
			return #Exit so the spin button doesn't get enabled
	
	print("Reward applied!")
	if GameManager.current_energy > 0:
		btn_spin.disabled = false
		btn_spin.release_focus()
	else:
		btn_spin.disabled = true

func lose_random_fragment():
	var active_indexes = []
	
	# Find all slots that usually have an item in them
	for i in range(PlayerData.active_orbits.size()):
		if PlayerData.active_orbits[i] != null:
			active_indexes.append(i)
	
	if active_indexes.size() > 0:
		# Pick a random slot and destroy the item
		var slot_to_wipe = active_indexes.pick_random()
		var item_name = PlayerData.active_orbits[slot_to_wipe].item_name
		
		PlayerData.active_orbits[slot_to_wipe] = null
		PlayerData.recalculate_fragment_bonuses() # Update new stats + bonuses
		
		print("The wheel claimed your ", item_name, " from the ", slot_to_wipe, " slot!")
	else:
		print("You aren't wearing any fragments! The wheel shows mercy...this time...")


func _on_leave_pressed():
	if is_spinning: return
	
	var screen_height = get_viewport_rect().size.y
	
	# 1. Slide it back up to the ceiling
	var slide_tween = create_tween()
	slide_tween.tween_property(self, "position:y", -screen_height, 0.3)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
	
	# 2. Wait for it to fully disappear
	await slide_tween.finished
	
	visible = false
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = true
