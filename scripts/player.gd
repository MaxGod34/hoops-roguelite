# Player.gd
extends CharacterBody2D


const SPEED = 500.0
const ACCELERATION = 2500.0
const FRICTION = 3000.0

# For moving test ball around, magic number
const PUSH_FORCE = 20.0

var held_ball = null
var has_control = true
var has_ball: bool = false

# Check Up Vars
var check_role: String = "" # FETCH, RECEIVE


func _physics_process(delta: float) -> void:
	# Removed jump mechanics for top down 8-way movement implementation
	
	# FREEZE LOGIC
	if not has_control:
		if get_parent().game_state == "CHECKING":
			process_check_up(delta)
		else:
			velocity = Vector2.ZERO


	# Get movement input (Left/Right) and apply acceleration
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction:
		# Speed up smoothly toward top speed
		velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
	else:
		# Skid to a stop instead of a hard stop
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		
	# Passing Logic
	if Input.is_action_just_pressed("pass") and held_ball:
		# Default to throwing 'up" if player is totally still, otherwise throw in movement direction
		var aim_dir = direction
		if aim_dir == Vector2.ZERO and velocity != Vector2.ZERO:
			aim_dir = velocity.normalized()
		elif aim_dir == Vector2.ZERO and velocity == Vector2.ZERO:
			aim_dir = Vector2.UP
			
		held_ball.throw(aim_dir, velocity)
		held_ball = null # Hands will now be empty
		has_ball = false
		
	if Input.is_action_just_pressed("shoot") and held_ball:
		# Find Hoop in the scene
		var hoops_in_scene = get_tree().get_nodes_in_group("hoop")
		
		if hoops_in_scene.size() > 0:
			var target_hoop = hoops_in_scene[0]
			# Get the target from the Marker2D
			var rim_position = target_hoop.get_node("ShotTarget").global_position
			
			
			# Tell the court/ref we are shooting
			get_parent().record_shot(self)
			
			held_ball.point_value = get_parent().pending_points
			
			# -- Distance check --
			var dist_to_hoop = global_position.distance_to(rim_position)
			if dist_to_hoop < 120.0:
				print("Player puts up a LAYUP!")
				held_ball.layup_ball(rim_position)
			else:
				print("Player shoots a JUMPER!")
				held_ball.shoot_ball(rim_position)
			#---------------------
			held_ball = null
			has_ball = false

	move_and_slide()
	
	#--Ball Collision Logic--
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# If we bump into the ball
		if collider is CharacterBody2D and collider.has_method("pickup"):
			if collider.z_height > 3.0: return
			
			# Check if ball has the pickup function, make sure player isn't holding it already
			elif not collider.is_held:
				# State Snapshot
				var previous_state = collider.state
				# Grab Ball
				collider.pickup(self)
				held_ball = collider # Remember which ball we just grabbed
				has_ball = true
				
				get_parent().register_possession_change(self, previous_state)
				
				# Use previous state cuz of OoOperations
				# Tell ref if we got a rebound or a steal
				if previous_state == "LOOSE" or previous_state == "REBOUNDING":
					get_parent().handle_rebound(self)
				

func start_check_sequence(role: String):
	check_role = role
	has_control = false


func process_check_up(delta: float):
	var target_pos = Vector2.ZERO
	var distance_to_target = 0.0
	var court = get_parent()
	
	if check_role == "RECEIVE":
		# Loser walks to the Offense Spawn and waits
		target_pos = court.get_node("OffenseSpawn").global_position
		distance_to_target = global_position.distance_to(target_pos)
		
		if distance_to_target > 15.0:
			var dir = global_position.direction_to(target_pos)
			velocity = dir * (SPEED * 0.75)
		else:
			# Arrived
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			
			
	elif check_role == "FETCH":
		# Scorer has a 2 part mission
		if not has_ball:
			# 1. Go get the ball
			var ball_node = get_tree().get_nodes_in_group("ball")[0]
			target_pos = ball_node.global_position
			distance_to_target = global_position.distance_to(target_pos)
			
			# run slightly faster for game pace
			var dir = global_position.direction_to(target_pos)
			velocity = dir * (SPEED * 0.75)
			
		else:
			# 2. Got the ball, walk to the defense spawn
			target_pos = court.get_node("DefenseSpawn").global_position
			distance_to_target = global_position.distance_to(target_pos)
			
			if distance_to_target > 15.0:
				var dir = global_position.direction_to(target_pos)
				velocity = dir * (SPEED * 0.5)
			else:
				# Arrived at defense spawn
				velocity = Vector2.ZERO
				
				# -- WAIT FOR THE RECEIVER TO BE IN PLACE --
				var receiver_target = court.get_node("OffenseSpawn").global_position
				var dist_to_receiver = court.receiver.global_position.distance_to(receiver_target)
				# IF RECEIVER IS MORE THAN 15 PIXELS FROM THEIR SPOT, WAIT!	
				if dist_to_receiver > 15.0:
					return
				# ------------------------------------------
				
				check_role = "WAITING"
				
				await get_tree().create_timer(0.5).timeout
				
				# Auto aim the pass
				var pass_dir = global_position.direction_to(court.receiver.global_position)
				
				
				if held_ball != null:
					held_ball.throw(pass_dir, Vector2.ZERO, 0.5)
				
				
				held_ball = null
				has_ball = false
				
				
			
				# Resume Game!
				court.resume_game()



func force_turnover():
	if held_ball:
		# Create a random direction for the ball to pop out
		var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		
		# Use throw function with zero player momentum so it pops out
		held_ball.throw(random_dir, Vector2.ZERO)
		
		held_ball = null
		has_ball = false
