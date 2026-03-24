extends CharacterBody2D
@onready var ball_sprite = $Sprite2D

@export var base_throw_speed = 700.0
@export var roll_friction: float = 400.0

var is_held = false
var player = null
var can_be_picked_up = true # Cooldown Flag

var pending_throw = false
var throw_aim = Vector2.ZERO
var throw_vel = Vector2.ZERO
var throw_start_pos = Vector2.ZERO

# Visual Illusion Vars
var z_height: float = 0.0
var state: String = "LOOSE" # LOOSE, HELD, SHOOTING, REBOUNDING

# Tween Tracking
var active_move_tween: Tween
var active_z_tween: Tween

# When player touches ball
func pickup(new_player):
	# Ignore pickup if we just threw it
	if not can_be_picked_up:
		return
	
	state = "HELD"
	is_held = true
	player = new_player
	
	velocity = Vector2.ZERO	

	$CollisionShape2D.set_deferred("disabled", true)


func _physics_process(delta: float) -> void:
	if state == "LOOSE":
		velocity = velocity.move_toward(Vector2.ZERO, roll_friction * delta)
		
		# Snapshot of speed before Godot tries to kill it
		var pre_collision_velocity = velocity
		
		if move_and_slide():
			# Get data of of wall just hit
			var collision = get_last_slide_collision()
			if collision:
				# Reflect velocity off wall's angle
				# Use 0.8 to reduce speed off wall slightly
				velocity = pre_collision_velocity.bounce(collision.get_normal()) * 0.8
	
	
	elif state == "HELD" and player != null:
		global_position = player.global_position + Vector2(30, 0)
		
	elif state == "SHOOTING" or state == "REBOUNDING":
		# Airbourne State
		pass

func throw(aim_direction: Vector2, player_velocity: Vector2):
	# Stand-Still Fix
	# If standing still, default to throwing "up" the court 
	# so it doesn't spawn inside chest
	if aim_direction == Vector2.ZERO:
		aim_direction = Vector2.UP 
	
	state = "LOOSE"
	is_held = false
	

	global_position = player.global_position + (aim_direction * 80)
	
	velocity = (aim_direction * base_throw_speed) + player_velocity
	
	player = null
	
	$CollisionShape2D.set_deferred("disabled", false)
	
	# Anti-Self-Pass Fix
	can_be_picked_up = false
	await get_tree().create_timer(0.2).timeout
	can_be_picked_up = true
	


func shoot_ball(target_pos: Vector2, arc_height: float = 1.5, flight_time: float = 1.0):

	stop_tweens() # Leftover bounces
	state = "SHOOTING"
	is_held = false
	player = null
	$CollisionShape2D.set_deferred("disabled", false)
	
	set_collision_mask_value(1, false)
	set_collision_layer_value(1, false)
	
	# X/Y movement (Across floor to hoop)
	active_move_tween = create_tween()
	active_move_tween.tween_property(self, "global_position", target_pos, flight_time)
	
	# Z axis (fake height and scale)
	active_z_tween = create_tween()
	
	# Going up
	active_z_tween.tween_property(ball_sprite, "scale", Vector2(arc_height, arc_height), flight_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Track actual variable for mechanical checks
	active_z_tween.parallel().tween_property(self, "z_height", 10.0, flight_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Coming down
	active_z_tween.tween_property(ball_sprite, "scale", Vector2(1.0, 1.0), flight_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	active_z_tween.parallel().tween_property(self, "z_height", 0.0, flight_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	can_be_picked_up = false
	await get_tree().create_timer(0.4).timeout
	can_be_picked_up = true


		
func bounce_vertical(normal: Vector2):
	
	# Calculate a random spot on the floor nearby based on bounce angle
	var bounce_target = global_position + (normal * randf_range(50.0, 150.0))
	var flight_time = randf_range(0.6, 0.8)
	var arc_height = randf_range(1.0, 1.2)
	
	# Run the exact same Tween logic from the shoot() function
	# X/Y movement (Across floor to hoop)
	active_move_tween = create_tween()
	active_move_tween.tween_property(self, "global_position", bounce_target, flight_time)
	
	# Z axis (fake height and scale)
	active_z_tween = create_tween()
	
	# Going up
	active_z_tween.tween_property(ball_sprite, "scale", Vector2(arc_height, arc_height), flight_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Track actual variable for mechanical checks
	active_z_tween.parallel().tween_property(self, "z_height", 10.0, flight_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Coming down
	active_z_tween.tween_property(ball_sprite, "scale", Vector2(1.0, 1.0), flight_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	active_z_tween.parallel().tween_property(self, "z_height", 0.0, flight_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	active_z_tween.finished.connect(_on_bounce_landed)


func bounce_flat(normal: Vector2):
	# Snap faked Z-axis and visual scale back to the floor instantly
	z_height = 0
	ball_sprite.scale = Vector2(1.0, 1.0)
	# Hand control back to the physics engine
	state = "LOOSE"
	
	set_collision_mask_value(1, true)
	set_collision_layer_value(1, true)
	
	# Calculate a fast, random kick-out speed
	var kick_speed = randf_range(300.0, 500.0)
	
	# Apply velocity pushing exactly away fom rim's collision point
	velocity = normal * kick_speed

func _on_bounce_landed():
	# Only if ball was actually rebounding
	if state == "REBOUNDING":
		state = "LOOSE"
		z_height = 0.0
		set_collision_mask_value(1, true) # Turn it back on
		set_collision_layer_value(1, true)
		
		# Random roll to it
		var random_angle = randf_range(0, TAU)
		velocity = Vector2(cos(random_angle), sin(random_angle)) * 100

func swish(net_center: Vector2):
	stop_tweens()
	
	state = "REBOUNDING"
	
	# Magnet pull the ball and snap to the center of the net
	global_position = net_center
	
	active_z_tween = create_tween()
	active_z_tween.tween_property(ball_sprite, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	active_z_tween.parallel().tween_property(self, "z_height", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Turn layers back on
	active_z_tween.finished.connect(_on_bounce_landed)

func stop_tweens():
	if active_move_tween and active_move_tween.is_valid():
		active_move_tween.kill()
	if active_z_tween and active_z_tween.is_valid():
		active_z_tween.kill()
	ball_sprite.scale = Vector2(1.0, 1.0)
