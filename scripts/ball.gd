extends CharacterBody2D

@onready var ball_sprite = $Sprite2D
@onready var collision = $CollisionShape2D

@export var base_throw_speed = 700.0
@export var roll_friction: float = 400.0

#========FLAGS=========
var is_held: bool = false
var is_dribbling: bool = false
var can_be_picked_up = true # Cooldown Flag
#======================

var player = null

#=========DRIBBLE===========
var current_hand: String = "RIGHT" # RIGHT, LEFT
var hand_offset_x: float = 25.0
#-- Dribble math variables --
var time_passed: float = 0.0
@export var bounce_height: float = 15.0
@export var bounce_speed: float = 8.0

# Standard gravity
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
#============================

# Visual Illusion Vars
var z_height: float = 0.0
var state: String = "LOOSE" # LOOSE, HELD, SHOOTING, REBOUNDING

# Tween Tracking
var active_move_tween: Tween
var active_z_tween: Tween
var cross_tween: Tween

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
				var collider = collision_last.get_collider()
				
				if collider and collider.has_method("pickup"):
					pass
				# Reflect velocity off wall's angle
				# Use 0.8 to reduce speed off wall slightly
				velocity = pre_collision_velocity.bounce(collision_last.get_normal()) * 0.8
		
		var court_left_edge = 42
		var court_right_edge = 1127
		var court_top_edge = 134
		var court_bottom_edge = 618

		if global_position.x < court_left_edge or global_position.x > court_right_edge or global_position.y < court_top_edge or global_position.y > court_bottom_edge:
			# If it escapes, snap it back inside and reverse its velocity so it bounces!
			global_position.x = clamp(global_position.x, court_left_edge + 10, court_right_edge - 10)
			global_position.y = clamp(global_position.y, court_top_edge + 10, court_bottom_edge - 10)
			velocity = -velocity * 0.5 # Bounce back inward with half speed

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
	
	if cross_tween and cross_tween.is_valid():
		cross_tween.kill()
	
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
	await get_tree().create_timer(0.05).timeout
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
	var hoop_rim_height = get_parent().get_node("Hoop").rim_height
	
	
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
	active_z_tween.parallel().tween_property(self, "z_height", hoop_rim_height + 10.0, fast_flight_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
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
		
		# Gravity drop
		var drop_tween = create_tween()
		drop_tween.tween_property(self, "z_height", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		# Anti stuck fix
		var random_angle = randf_range(0, TAU)
		velocity = Vector2(cos(random_angle), sin(random_angle)) * randf_range(50.0, 100.0)
		
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
	
	if active_move_tween and active_move_tween.is_valid():
		active_move_tween.kill()
	if active_z_tween and active_z_tween.is_valid():
		active_z_tween.kill()
	
	state = "REBOUNDING"
	
	# Magnet pull the ball and snap to the center of the net
	global_position = net_center
	
	var hoop = court_node.get_node("Hoop")
	var drop_distance = 60.0
	if hoop and hoop.rim_height > 60.0:
		drop_distance = hoop.rim_height
	
	var floor_pos = net_center + Vector2(0, drop_distance) 
	
	
	active_move_tween = create_tween()
	active_z_tween = create_tween()
	
	var net_bottom_pos = net_center + Vector2(0, 15.0)
	var catch_time = 0.15
	active_move_tween.tween_property(self, "global_position", net_bottom_pos, catch_time).set_trans(
																						Tween.TRANS_LINEAR)
	
	var drop_time = 0.25
	active_move_tween.tween_property(self, "global_position", floor_pos, drop_time).set_trans(
																	Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	
	var total_time = catch_time + drop_time
	active_z_tween.tween_property(ball_sprite, "scale", Vector2(1.0, 1.0), total_time).set_trans(
																						Tween.TRANS_LINEAR)
	active_z_tween.parallel().tween_property(self, "z_height", 0.0, total_time).set_trans(
																						Tween.TRANS_LINEAR)
	
	# Turn layers back on
	active_z_tween.finished.connect(_on_bounce_landed)

func _deferred_pickup_reparent(new_player):
	# Double check the ball hasn't been deleted while waiting
	if get_parent() != null and new_player != null:
		get_parent().remove_child(self)
		new_player.add_child(self)
		
		# Snap to the hip after reparenting is finished and use the CORRECT hand
		var target_x = hand_offset_x if current_hand == "RIGHT" else -hand_offset_x
		position = Vector2(target_x, 0)

func perform_crossover(duration: float):
	# Determine new hand position
	var target_x = -hand_offset_x if current_hand == "RIGHT" else hand_offset_x
	
	# Swap the internal tracker
	current_hand = "LEFT" if current_hand == "RIGHT" else "RIGHT"
	
	if cross_tween and cross_tween.is_valid():
		cross_tween.kill()
	
	
	# Tween the ball's root X position across the body
	cross_tween = create_tween()
	cross_tween.tween_property(self, "position:x", target_x, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	
	# Game Feel/Polish
	var old_speed = bounce_speed	# Snapshot
	bounce_speed = 25.0
	await get_tree().create_timer(duration).timeout
	bounce_speed = old_speed		# Restore

func reject_shot(deflect_dir: Vector2):
	# Kill flight path immidiately
	stop_tweens()
	
	# Reset state so anyone can scramble for it
	state = "LOOSE"
	can_be_picked_up = true
	
	# Re-enable floor collisions so it bounces and players can bump/interact w it
	$CollisionShape2D.set_deferred("disabled", false)
	set_collision_mask_value(1, true)
	set_collision_layer_value(1, true)
	
	# Horizontal Spike
	# Give the ball a massive velocity burst in the direction of the block
	velocity = deflect_dir * 800.0
	
	# Vertical Spike
	# Slam the ball back to the floor visually in just 0.15 seconds
	var spike_tween = create_tween()
	spike_tween.tween_property(self, "z_height", 0.0, 0.15).set_trans(
															Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	spike_tween.parallel().tween_property(ball_sprite, "scale", Vector2(1.0, 1.0), 0.15).set_trans(
															Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)



func stop_tweens():
	if active_move_tween and active_move_tween.is_valid():
		active_move_tween.kill()
	if active_z_tween and active_z_tween.is_valid():
		active_z_tween.kill()
	ball_sprite.scale = Vector2(1.0, 1.0)
