extends Node2D

signal replay_finished
signal replay_tick(p_score, b_score, mach_val, clock_time)

var is_playing: bool = false
var current_frame: int = 0
var playback_data: Array = []

@onready var ghost_player = $GhostContainer/GhostPlayer
@onready var ghost_bot = $GhostContainer/GhostBot
@onready var ghost_ball = $GhostContainer/GhostBall
@onready var ui_layer = $UI

# UI References
@onready var lbl_mach = $UI/StatsContainer/Lbl_Mach
@onready var lbl_reward = $UI/StatsContainer/Lbl_Reward
@onready var lbl_bath_boost = $UI/StatsContainer/Lbl_IceBathBonus
@onready var stat_grid = $UI/StatsContainer/StatGrid
@onready var btn_next = $UI/Btn_Next

var time_passed: float = 0.0
const FPS: float = 60.0
const FRAME_TIME: float = 1.0 / FPS



func _ready():
	hide()
	ui_layer.hide()
	btn_next.pressed.connect(_on_next_pressed)

func start_replay(ending_mach: int):
	playback_data = HighlightManager.play_of_the_game
	
	if playback_data.size() == 0:
		print("No highlights recorded! Skipping to Victory Screen.")
		# Fallback just in case they won instantly with no Mach Generated
		return
	
	current_frame = 0
	is_playing = true
	show()
	ui_layer.show()
	
	# Reward Math
	var base_reward = 1
	var total_reward = base_reward * ending_mach
	
	#---STYX ICE BATH---
	var is_styx_active = GameManager.styx_ice_bath_active
	lbl_bath_boost.visible = is_styx_active
	
	var visual_total_reward = total_reward
	if is_styx_active:
		visual_total_reward *= 2
		lbl_bath_boost.text = "STYX ICE BATH X2"
	#--------------------
	
	lbl_mach.text = "ENDING MACH: x" + str(ending_mach)
	lbl_reward.text = "BASE REWARD +1 x " + str(ending_mach)
	
	# Clear out grid in case we replay multiple times
	for child in stat_grid.get_children():
		child.queue_free()
	
	# Create master Tween and tell it to run everything at the exact same time
	var ui_tween = create_tween()
	ui_tween.set_parallel(true)
	
	#===CASCADE VARIABLES===
	var cascade_delay: float = 1.0
	var animation_duration: float = 4.0
	
	# Dynamic Stat Generation
	for stat_key in PlayerData.base_stats.keys():
		var start_val = PlayerData.base_stats[stat_key]
		var end_val = start_val + visual_total_reward
		
		var custom_theme = load("res://scenes/lbl_theme_stats_replay.tres")
		
		# 1. Actually upgrade the true stats in the background
		PlayerData.upgrade_stat(stat_key, total_reward)
		
		# 2. Spawn the Name Label
		var name_lbl = Label.new()
		# Format dictionary key to look nice
		name_lbl.text = stat_key.capitalize().replace("_", " ") + ": "
		name_lbl.theme = custom_theme
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stat_grid.add_child(name_lbl)
		
		# Spawn a value label WRAPPER
		var val_wrapper = Control.new()
		val_wrapper.custom_minimum_size = Vector2(40, 30)
		stat_grid.add_child(val_wrapper)
		
		
		# 3. Spawn the Value Label
		var val_lbl = Label.new()
		val_lbl.text = str(start_val)
		val_lbl.theme = custom_theme
		
		val_lbl.pivot_offset = Vector2(12, 12)
		
		val_wrapper.add_child(val_lbl)
		
		var tick_func = func(value: int):
			var new_text = str(value)
			
			if val_lbl.text != new_text:
				val_lbl.text = new_text
			
				# Ignore first frame
				if value > start_val:
					# Micro pop
					var pop_tween = val_lbl.create_tween()
					pop_tween.set_parallel(true)
					
					# Instantly make it big and hype green
					val_lbl.scale = Vector2(1.5, 1.5)
					val_lbl.modulate = Color(0.2, 1.0, 0.2)
					val_lbl.position.y = -10.0
					
					# Snap back to normal after 0.2 sec
					pop_tween.tween_property(val_lbl, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_BOUNCE)
					pop_tween.tween_property(val_lbl, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE)
					pop_tween.tween_property(val_lbl, "modulate", Color.WHITE, 0.3)
		
		
		# 4. The Lambda Tween (Dopamine Magic)
		ui_tween.tween_method(
			tick_func,
			start_val,
			end_val,
			animation_duration
		).set_delay(cascade_delay).set_trans(Tween.TRANS_QUAD)
		
		cascade_delay += 0.15
	
	
	
	print("PLAY OF THE GAME: ", playback_data.size(), " frames loaded.")


func _process(delta: float):
	if not is_playing or playback_data.size() == 0: return
	
	time_passed += delta
	
	# Only advance the tape if enough time has passed to match 60 FPS
	while time_passed >= FRAME_TIME:
		time_passed -= FRAME_TIME
	
		# 1. Grab the snapshot for the current frame
		var data = playback_data[current_frame]
		
		# 2. Apply Coordinates (incorporating the fake Z-height)
		ghost_player.global_position = data["player_pos"]
		ghost_player.position.y -= data["player_z"]
		
		ghost_bot.global_position = data["bot_pos"]
		ghost_bot.position.y -= data["bot_z"]
		
		ghost_ball.global_position = data["ball_pos"]
		ghost_ball.position.y += data["ball_sprite_z"]
		ghost_ball.scale = data["ball_scale"]
		
		# Tell court about HUD elements
		replay_tick.emit(data["p_score"], data["b_score"], data["mach"], data["clock"])
		
		# 3. Advance the tape
		current_frame += 1
		
		# 4. Loop back to the start if we hit the end of the 5 seconds
		if current_frame >= playback_data.size():
			current_frame = 0
			
			


func _on_next_pressed():
	is_playing = false
	hide()
	ui_layer.hide()
	replay_finished.emit()
