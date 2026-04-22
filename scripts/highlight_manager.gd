extends Node

const MAX_FRAMES = 300

var current_buffer: Array = []
var current_mach_gained: float = 0.0

var play_of_the_game: Array = []
var highest_mach_recorded: float = 0.0

var is_recording: bool = false

var frames_until_capture: int = 0


func start_recording():
	current_buffer.clear()
	play_of_the_game.clear()
	current_mach_gained = 0.0
	highest_mach_recorded = 0.0
	is_recording = true

func stop_recording():
	is_recording = false

func record_frame(player_node, bot_node, ball_node, p_score: int, b_score: int, current_mach: float, clock_time: float):
	if not is_recording: return
	
	# 1. Take the Snapshot of the exact physical state this frame
	var frame_data = {
		"player_pos": player_node.global_position,
		"player_z": player_node.jump_z,
		"bot_pos": bot_node.global_position,
		"bot_z": bot_node.jump_z,
		# Ball might be null if it's currently deleted/reparenting so use fallbacks
		"ball_pos": ball_node.global_position if ball_node else Vector2.ZERO,
		"ball_sprite_z": ball_node.get_node("Sprite2D").position.y if ball_node and ball_node.has_node("Sprite2D") else 0.0,
		"ball_scale": ball_node.get_node("Sprite2D").scale * 0.4 if ball_node and ball_node.has_node("Sprite2D") else Vector2.ONE,
		# Default 0.0, inject Mach into this specific frame later
		"mach_earned": 0.0,
		# HUD STATES
		"p_score": p_score,
		"b_score": b_score,
		"mach": current_mach,
		"clock": clock_time
	}
	
	# 2. Add it to the Ring Buffer
	current_buffer.append(frame_data)
	
	# 3. If we exceed 5 seconds, throw away the oldest frame
	if current_buffer.size() > MAX_FRAMES:
		var oldest_frame = current_buffer.pop_front()
		# If the oldest frame had Mach points attached, we subtract them from the running total
		current_mach_gained -= oldest_frame["mach_earned"]
	
	# 4. Judge the Buffer (Did we find the new best highlight?)
	# Only evaluate if the buffer is completely full (5 seconds)
	if current_buffer.size() == MAX_FRAMES:
		if current_mach_gained >= highest_mach_recorded:
			highest_mach_recorded = current_mach_gained
			frames_until_capture = 60 # Wait 1 second to capture the landing/swish
		
		if frames_until_capture > 0:
			frames_until_capture -= 1
			if frames_until_capture == 0:
				play_of_the_game = current_buffer.duplicate(true)
	
# Called from Court.gd whenever the player does something siiick
func inject_mach_to_current_frame(amount: float):
	if current_buffer.size() > 0:
		# Add Mach points to very last frame we just recorded
		current_buffer[-1]["mach_earned"] += amount
		current_mach_gained += amount


func force_pending_capture():
	if frames_until_capture > 0:
		play_of_the_game = current_buffer.duplicate(true)
		frames_until_capture = 0
