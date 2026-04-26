extends Node2D

@onready var left_coil = $LeftCoil
@onready var right_coil = $RightCoil
@onready var arc_container = $ArcContainer
@onready var left_sparks = $LeftCoil/LeftSparks
@onready var right_sparks = $RightCoil/RightSparks

@export var lightning_scene: PackedScene

var current_arc_count: int = 0
var active_arcs: Array = []

# Sparks
var sputter_timer: float = 0.0
var next_sputter: float = 1.0


func _ready():
	MachManager.mach_generated.connect(_on_mach_generated)



func _process(delta: float):
	var target_mach = MachManager.visual_mach
	
	# Calculate how many beams we should have (Mach 2 = 1, Mach 4 = 3)
	var desired_arcs = max(0, floor(target_mach) - 1)
	
	# Do we need more lightning
	while current_arc_count < desired_arcs:
		spawn_arc()
	
	# Do we need to kill lightning because we got stripped/turned over?
	while current_arc_count > desired_arcs:
		kill_arc()
	
	
	if target_mach < 2.0:
		sputter_timer += delta
		if sputter_timer >= next_sputter:
			sputter_timer = 0.0
			next_sputter = randf_range(2.5, 4.0)
			
			if randi() % 2 == 0:
				left_sparks.restart()
			else:
				right_sparks.restart()
		
	
	
	
	# Apply Color and Chaos based on current Mach
	update_coil_visuals(target_mach)
	

func spawn_arc():
	var new_arc = lightning_scene.instantiate()
	arc_container.add_child(new_arc)
	active_arcs.append(new_arc)
	current_arc_count += 1
	
	# Tell them where to attach
	new_arc.start_pos = Vector2(left_coil.position.x, left_coil.position.y - 40)
	new_arc.end_pos = Vector2(right_coil.position.x, right_coil.position.y - 40)

func kill_arc():
	if arc_container.get_child_count() > 0:
		var arc = arc_container.get_child(0)
		active_arcs.erase(arc)
		arc.queue_free()
		current_arc_count -= 1

func update_coil_visuals(mach_level: float):
	# Default Ozone Blue
	var target_color = Color(0.5, 0.8, 1.0, 1.0) * 2.0
	var target_jitter = 25.0
	
	# Overclocked 
	if mach_level >= 5.0:
		target_color = Color(1.0, 0.2, 0.2, 1.0) * 4.0
		target_jitter = 60.0
	# Golden Radiance Mach 4
	elif mach_level >= 4.0:
		target_color = Color(1.0, 0.8, 0.2, 1.0) * 3.0
		target_jitter = 45.0
	# Volatile Purple Mach 3
	elif mach_level >= 3.0:
		target_color = Color(0.8, 0.2, 1.0, 1.0) * 2.5
		target_jitter = 35.0
	
	# Apply to all current arcs
	for arc in active_arcs:
		arc.modulate = target_color
		arc.jitter_amount = target_jitter

func _on_mach_generated(_amount_earned: float):
	# Fire both particle cannons simulatneously
	left_sparks.restart()
	right_sparks.restart()
	
	# Physical Shake
	var shake_tween = create_tween()
	shake_tween.set_parallel(true)
	
	# Wiggle them outwards aggressively over 0.05 sec
	shake_tween.tween_property(left_coil, "rotation_degrees", 4.0, 0.05)
	shake_tween.tween_property(right_coil, "rotation_degrees", -4.0, 0.05)
	
	# Create a tiny sequence gap
	shake_tween.chain().tween_interval(0.01)
	
	# Snap them back to 0.0 with a heavy metallic bounce over 0.2 sec
	shake_tween.chain().tween_property(left_coil, "rotation_degrees", 0.0, 0.2).set_trans(Tween.TRANS_BOUNCE)
	shake_tween.chain().tween_property(right_coil, "rotation_degrees", 0.0, 0.2).set_trans(Tween.TRANS_BOUNCE)
