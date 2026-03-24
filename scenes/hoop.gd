extends Node2D

@export var rim_height: float = 0.0 #ball has to be at this z_height to interact

@onready var zone_backboard = $Zone_Backboard
@onready var zone_rim = $Zone_Rim
@onready var zone_net = $Zone_Net




func _ready():
	zone_backboard.body_entered.connect(_on_backboard_hit)
	zone_rim.body_entered.connect(_on_rim_collision)
	zone_net.body_entered.connect(_on_net_entered)




func _on_backboard_hit(body):
	if body.is_in_group("ball") and body.state == "SHOOTING":
		if body.z_height >= rim_height:
			# Calc the normal (pushing straight away from the glass)
			var bounce_normal = Vector2(0, 1) # Facing down
			_trigger_brick(body, bounce_normal)
			
func _on_rim_collision(body):
	if body.is_in_group("ball") and body.state == "SHOOTING":
		if body.z_height >= rim_height:
			# Calc normal pushing away from exact center of the hoop
			var bounce_normal = (body.global_position - global_position).normalized()
			_trigger_brick(body, bounce_normal)
			
func _trigger_brick(ball, normal: Vector2):
	# Kill shot arc
	ball.stop_tweens()
		
	# Randomize a brick and a pop up
	var bounce_type = randi() % 100
	if bounce_type < 40:
		ball.bounce_flat(normal)
	else:
		ball.bounce_vertical(normal)
		
func _on_net_entered(body):
	# Swish
	if body.is_in_group("ball") and body.state == "SHOOTING":
		if body.z_height >= rim_height:
			print("SWISH! Nice one!")
			
			body.swish(zone_net.global_position)
			
			
