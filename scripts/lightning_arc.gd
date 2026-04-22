extends Line2D

@export var start_pos: Vector2 = Vector2.ZERO
# Default fallback, 200 pixels to the right
@export var end_pos: Vector2 = Vector2(200.0, 0.0)

@export var segments: int = 0
@export var jitter_amount: float = 25.0 # How far sideways it can snap
@export var update_rate: float = 0.05 # How fast it wiggles

@onready var core_line = $CoreLine

var time_since_last_update: float = 0.0

func _ready():
	_generate_lightning()

func _process(delta: float):
	time_since_last_update += delta
	
	var random_alpha = randf_range(0.3, 1.0)
	modulate.a = random_alpha
	core_line.modulate.a = random_alpha
	
	# Only redraw the lightning every 0.05 seconds
	if time_since_last_update >= update_rate:
		time_since_last_update = 0.0
		_generate_lightning()
		


func _generate_lightning():
	clear_points()
	core_line.clear_points()
	
	# 1. Lock in starting point
	add_point(start_pos)
	core_line.add_point(start_pos)
	
	# 2. Get the directional math between the two coils
	var dir = (end_pos - start_pos).normalized()
	var perp = Vector2(-dir.y, dir.x) # Perpendicular angle
	var dist = start_pos.distance_to(end_pos)
	var segment_length = dist / float(segments)
	
	# 3. Generate the jagged middle points
	for i in range(1, segments):
		# Find where the point WOULD be on a straight line
		var base_point = start_pos + (dir * (segment_length * i))
		
		# Shove it violently sideways using perpendicular angle
		var random_jitter = randf_range(-jitter_amount, jitter_amount)
		var jagged_point = base_point + (perp * random_jitter)
		
		add_point(jagged_point)
		core_line.add_point(jagged_point)
	
	# 4. Lock in the ending point
	add_point(end_pos)
	core_line.add_point(end_pos)
