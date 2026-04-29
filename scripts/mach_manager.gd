extends Node

signal mach_generated(amount_earned)
signal mach_level_changed(new_level)

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



#===============================================================================
# CORE FUNCTIONS
#===============================================================================

func add_mach(amount: float):
	# Turbo Mach Modifier
	if GameManager.has_active_mutation("turbo_mach"):
		amount *= 0.5
	
	
	current_mach += amount
	# GHOST BUFFER
	current_mach = clamp(current_mach, 1.0, get_max_mach())
	_update_visuals()
	
	mach_generated.emit(amount)
	
	# Feed the DVR
	if HighlightManager.is_recording:
		HighlightManager.inject_mach_to_current_frame(amount)
	
	print("Mach Gained! Gained: ", amount, " Mach now at ", current_mach)

func reduce_mach(amount: float):
	current_mach -= amount
	current_mach = clamp(current_mach, 1.0, get_max_mach())
	_update_visuals()

func reset_to_base():
	current_mach = 1.0
	_update_visuals()

func _update_visuals():
	var new_visual = floori(current_mach)
	
	if new_visual != visual_mach:
		visual_mach = new_visual
		print("MACH LEVEL CHANGED! X", visual_mach, " ACHIEVED!")
		
		mach_level_changed.emit(visual_mach)


#===============================================================================
# BAIT SHOP MODIFIERS
#===============================================================================
func get_max_mach() -> float:
	# Deep Cap Curse Overrides everything and locks it to 3
	if GameManager.has_active_mutation("deep_cap"):
		return 3.99
	
	# Standard Ceiling
	var ceiling = 4.99
	
	# Turbo Mach Buff
	if GameManager.has_active_mutation("turbo_mach"):
		ceiling += 1.0
	
	return ceiling
	
	
	
