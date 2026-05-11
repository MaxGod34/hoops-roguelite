# hoop.gd
extends Node2D

@export var rim_height: float = 45.0 #ball has to be at this z_height to interact

@onready var zone_backboard = $Zone_Backboard
@onready var zone_rim = $Zone_Rim
@onready var zone_net = $Zone_Net

signal basket_scored(points, scorer)



func _ready():
	$AnimationPlayer.play("rim_rotation")
	zone_backboard.body_entered.connect(_on_backboard_hit)
	zone_rim.body_entered.connect(_on_rim_collision)


func _physics_process(_delta):
	var bodies = zone_net.get_overlapping_bodies()
	# ONLY SWISH IF IT'S NOT A MISS
	for body in bodies:
		if body.is_in_group("ball") and not body.is_miss and (body.state == "SHOOTING" or body.state == "LAYUP"):
			if body.z_height >= (rim_height - 10.0) and body.z_height <= (rim_height + 50.0):
				print("SWISH! Security Cam Caught It!")
				get_tree().call_group("shot_clock", "reset_clock")
				body.swish(zone_net.global_position)
				var shooter = get_parent().last_shooter
				$GPUParticles2D.restart()
				basket_scored.emit(body.point_value, shooter)


func _on_backboard_hit(body):
	if body.is_in_group("ball") and body.is_miss and (body.state == "SHOOTING" or body.state == "LAYUP"):
		if body.z_height >= rim_height:
			get_tree().call_group("shot_clock", "reset_clock")
			# Calc the normal (pushing straight away from the glass)
			var bounce_normal = Vector2(0, 1) # Facing down
			_trigger_brick(body, bounce_normal)
			
func _on_rim_collision(body):
	if body.is_in_group("ball") and body.is_miss and (body.state == "SHOOTING" or body.state == "LAYUP"):
		if body.z_height >= (rim_height - 5.0) and body.z_height <= (rim_height + 15.0):
			
			get_tree().call_group("shot_clock", "reset_clock")
			
			# Calc normal pushing away from exact center of the hoop
			var bounce_normal = (body.global_position - global_position).normalized()
			_trigger_brick(body, bounce_normal)
			
func _trigger_brick(ball, normal: Vector2):
	ball.state = "REBOUNDING"
	# Kill shot arc
	ball.stop_tweens()
		
	# Randomize a brick and a pop up
	var bounce_type = randi() % 100
	if bounce_type < 40:
		ball.bounce_flat(normal)
	else:
		ball.bounce_vertical(normal)
	
	trigger_rim_shudder()

func trigger_rim_shudder():
	$AnimationPlayer.pause()
	
	var rim_sprite = $RimSprite
	#var original_pos = rim_sprite.position <- Prolly not needed unless rim actually moves
	var original_scale = rim_sprite.scale
	
	var shudder_tween = create_tween()
	
	shudder_tween.tween_property(rim_sprite, "scale", Vector2(1.3, 0.7), 0.05).set_trans(Tween.TRANS_BOUNCE)
	shudder_tween.tween_property(rim_sprite, "scale", Vector2(0.8, 1.2), 0.05).set_trans(Tween.TRANS_BOUNCE)
	
	shudder_tween.tween_property(rim_sprite, "scale", original_scale, 0.1).set_trans(Tween.TRANS_SPRING)
	
	var original_color = rim_sprite.modulate
	rim_sprite.modulate = Color(2.0, 0.0, 0.0, 1.0)
	var color_tween = create_tween()
	color_tween.tween_property(rim_sprite, "modulate", original_color, 0.2)
	
	await color_tween.finished
	$AnimationPlayer.play("rim_rotation")
			
