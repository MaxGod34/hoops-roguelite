extends CharacterBody2D

@onready var ball_sprite = $Sprite2D
@onready var collision = $CollisionShape2D

@export var base_throw_speed = 700.0
@export var roll_friction: float = 400.0

var is_held: bool = false
var is_dribbling: bool = false

var player = null
var can_be_picked_up = true # Cooldown Flag

# Dribble math variables
var time_passed: float = 0.0
@export var bounce_height: float = 15.0
@export var bounce_speed: float = 8.0

# Standard gravity
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Visual Illusion Vars
var z_height: float = 0.0
var state: String = "LOOSE" # LOOSE, HELD, SHOOTING, REBOUNDING

# Tween Tracking
var active_move_tween: Tween
var active_z_tween: Tween

# Scoring
var point_value: int = 2 # Default 2 pter
@onready var court_node: Node2D = get_parent()

# When player touches ball
func pickup(new_player):
	if new_player == null:
		push_error("ERROR: Tried to pick up ball, but the player variable was null!")
		return
	# Ignore pickup if we just threw it
	if not can_be_picked_up:
		return
	
	state = "HELD"
	is_held = true
	player = new_player

	$CollisionShape2D.set_deferred("disabled", true)
	
	call_deferred("_deferred_pickup_reparent", new_player)


func _physics_process(delta: float) -> void:
	if state == "LOOSE":
		ball_sprite.position.y = 0
		velocity = velocity.move_toward(Vector2.ZERO, roll_friction * delta)
		
		# Snapshot of speed before Godot tries to kill it
		var pre_collision_velocity = velocity
		
		if move_and_slide():
			# Get data of of wall just hit
			var collision_last = get_last_slide_collision()
			if collision_last:
				# Reflect velocity off wall's angle
				# Use 0.8 to reduce speed off wall slightly
				velocity = pre_collision_velocity.bounce(collision_last.get_normal()) * 0.8
	
	
	elif state == "HELD" and player != null:
		if is_dribbling:
			time_passed += delta
			var bounce_offset = abs(sin(time_passed * bounce_speed)) * -bounce_height
			ball_sprite.position.y = bounce_offset
		else:
			ball_sprite.position.y = 0
			time_passed = 0.0
			
	elif state == "SHOOTING" or state == "REBOUNDING":
		# Airbourne State
		pass

func throw(aim_direction: Vector2, player_velocity: Vector2, speed_modifier: float = 1.0):
	if player == null:
		push_error("ERROR: Tried to throw the ball, but the player variable was null! (ball.gd throw())")
		return
	
	# Stand-Still Fix
	# If standing still, default to throwing "up" the court 
	# so it doesn't spawn inside chest
	if aim_direction == Vector2.ZERO:
		aim_direction = Vector2.UP 
	
	state = "LOOSE"
	is_held = false
	is_dribbling = false
	
	# Snapshots the math before we delete the player ref
	var spawn_position = player.global_position + (aim_direction * 80)
	var throw_velocity = (aim_direction * base_throw_speed * speed_modifier) + player_velocity
	
	# Clear player
	player = null
	
	# Move the ball to the Court FIRST
	get_parent().remove_child(self)
	court_node.add_child(self)
	
	# Now apply the corrdinates so Godot can know where the ball goes
	global_position = spawn_position
	velocity = throw_velocity
	
	$CollisionShape2D.set_deferred("disabled", false)
	
	# Anti-Self-Pass Fix
	can_be_picked_up = false
	await get_tree().create_timer(0.1).timeout
	can_be_picked_up = true
	


func shoot_ball(target_pos: Vector2, arc_height: float = 1.5, flight_time: float = 1.0):
	
	var hoop = court_node.get_node("Hoop")
	var peak_z = hoop.rim_height + (arc_height * 20)
	
	stop_tweens() # Leftover bounces
	state = "SHOOTING"
	is_held = false
	
	# Snapshot the position while still attached to the player
	var start_pos = global_position
	
	player = null
	
	# Move to the court
	get_parent().remove_child(self)
	court_node.add_child(self)
	
	# Reapply snapshot so Tween start from shooter's hands
	global_position = start_pos
	
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
	active_z_tween.parallel().tween_property(self, "z_height", peak_z, flight_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Coming down
	active_z_tween.tween_property(ball_sprite, "scale", Vector2(1.0, 1.0), flight_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	active_z_tween.parallel().tween_property(self, "z_height", hoop.rim_height + 10.0, flight_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	can_be_picked_up = false
	await get_tree().create_timer(flight_time).timeout
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	can_be_picked_up = true
	
	# Safety net
	if state == "SHOOTING":
		state = "REBOUNDING"
		set_collision_mask_value(1, true)
		set_collision_layer_value(1, true)
		
		var drop_tween = create_tween()
		drop_tween.tween_property(self, "z_height", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		# Anti stuck fix
		var random_angle = randf_range(0, TAU)
		velocity = Vector2(cos(random_angle), sin(random_angle)) * randf_range(50.0, 100.0)
		
		print("CLANK! Brick kicked out ball is live!")

func layup_ball(target_pos: Vector2):
	# Set state so rim ignores
	state = "LAYUP"
	# Detach from player
	is_held = false
	z_height = 2.0
	
	# Snapshot
	var start_pos = global_position
	
	# Reparent
	get_parent().remove_child(self)
	court_node.add_child(self)
	player = null
	
	# REAPPLY snapshot
	global_position = start_pos
	
	$CollisionShape2D.set_deferred("disabled", false)
	set_collision_mask_value(1, false)
	set_collision_layer_value(1, false)
	
	# Calculate a much faster, flatter flight time
	var dist = global_position.distance_to(target_pos)
	var fast_flight_time = clamp(dist / (base_throw_speed * 0.5), 0.2, 0.5)
	var arc_height = 1.4 # Lower arc for a layup
	
	
	# ------------------------ TWEEEEEEEEEEEN ----------------------------
	active_move_tween = create_tween()
	active_z_tween = create_tween()
	
	# X/Y movement (Across floor to hoop)
	active_move_tween.tween_property(self, "global_position", target_pos, fast_flight_time)
	
	# Z axis (Fake height AND visual scale)
	# Going up
	active_z_tween.tween_property(ball_sprite, "scale", Vector2(arc_height, arc_height), fast_flight_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_z_tween.parallel().tween_property(self, "z_height", get_parent().get_node("Hoop").rim_height + 25.0, fast_flight_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Coming down
	active_z_tween.tween_property(ball_sprite, "scale", Vector2(1.0, 1.0), fast_flight_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	active_z_tween.parallel().tween_property(self, "z_height", 0.0, fast_flight_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# ----------------------------------------------------------------------
	
	
	can_be_picked_up = false
	await get_tree().create_timer(fast_flight_time).timeout
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	can_be_picked_up = true
	
	if state == "SHOOTING" or state == "LAYUP":
		state = "REBOUNDING"
		set_collision_mask_value(1, true)
		set_collision_layer_value(1, true)
		print("Shot timer ended! Ball is live!")
		
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
		velocity = Vector2(cos(random_angle), sin(random_angle)) * 2

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

func _deferred_pickup_reparent(new_player):
	# Double check the ball hasn't been deleted while waiting
	if get_parent() != null and new_player != null:
		get_parent().remove_child(self)
		new_player.add_child(self)
		
		# Snap to the hip after reparenting is finished
		position = Vector2(25, 0)


func stop_tweens():
	if active_move_tween and active_move_tween.is_valid():
		active_move_tween.kill()
	if active_z_tween and active_z_tween.is_valid():
		active_z_tween.kill()
	ball_sprite.scale = Vector2(1.0, 1.0)
