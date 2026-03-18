extends CharacterBody2D


const SPEED = 500.0
const ACCELERATION = 2500.0
const FRICTION = 3000.0

# For moving test ball around, magic number
const PUSH_FORCE = 20.0

var held_ball = null


func _physics_process(delta: float) -> void:
	# Removed jump mechanics for top down 8-way movement implementation

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
		
	if Input.is_action_just_pressed("shoot") and held_ball:
		# Find Hoop in the scene
		var hoops_in_scene = get_tree().get_nodes_in_group("hoop")
		
		if hoops_in_scene.size() > 0:
			var target_hoop = hoops_in_scene[0]
			
			# Get the target from the Marker2D
			var rim_position = target_hoop.get_node("RimTarget").global_position
			
			# Calculate exact angle from player to hoop
			var aim_dir = global_position.direction_to(rim_position)
			
			# On a shot we will ignore any momentum (velocity)
			# Stop on a dime, shoot a clean jumper 
			held_ball.throw(aim_dir, Vector2.ZERO)
			held_ball = null

	move_and_slide()
	
	#--Ball Collision Logic--
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# If we bump into the ball
		if collider is RigidBody2D:
			# Check if ball has the pickup function, make sure player isn't holding it already
			if collider.has_method("pickup") and not collider.is_held:
				collider.pickup(self)
				held_ball = collider # Remember which ball we just grabbed


func force_turnover():
	if held_ball:
		# Create a random direction for the ball to pop out
		var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		
		# Use throw function with zero player momentum so it pops out
		held_ball.throw(random_dir, Vector2.ZERO)
		
		held_ball = null
