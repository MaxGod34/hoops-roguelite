extends Node

# Math
var current_mach: float = 1.0
# UI & reward
var visual_mach: int = 1
# Decay setting
var decay_timer: float = 0.0
var decay_interval: float = 6.0
var decay_amount: float = 0.1

# Flag so the meter doesn't decay when the game isn't going
var is_game_active: bool = false


func _process(delta: float):
	if not is_game_active: return
	
	decay_timer += delta
	if decay_timer >= decay_interval:
		decay_timer = 0.0
		reduce_mach(decay_amount)
		print("Mach Decayed. Current: ", current_mach)

func add_mach(amount: float):
	current_mach += amount
	# GHOST BUFFER
	current_mach = clamp(current_mach, 1.0, 4.99)
	_update_visuals()
	
	# Feed the DVR
	if HighlightManager.is_recording:
		HighlightManager.inject_mach_to_current_frame(amount)

func reduce_mach(amount: float):
	current_mach -= amount
	current_mach = clamp(current_mach, 1.0, 4.99)
	_update_visuals()

func reset_to_base():
	current_mach = 1.0
	_update_visuals()

func _update_visuals():
	var new_visual = floori(current_mach)
	
	if new_visual != visual_mach:
		visual_mach = new_visual
		print("MACH LEVEL CHANGED! X", visual_mach, " ACHIEVED!")
