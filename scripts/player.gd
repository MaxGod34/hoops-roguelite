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
		
	# Shooting Logic
	if Input.is_action_just_pressed("shoot") and held_ball:
		# Default to throwing 'up" if player is totally still, otherwise throw in movement direction
		var aim_dir = direction
		if aim_dir == Vector2.ZERO and velocity != Vector2.ZERO:
			aim_dir = velocity.normalized()
		elif aim_dir == Vector2.ZERO and velocity == Vector2.ZERO:
			aim_dir = Vector2.UP
			
		held_ball.throw(aim_dir, velocity)
		held_ball = null # Hands will now be empty

	move_and_slide()
	
	#--Ball Collision Logic--
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# If we bump into the ball
		if collider is RigidBody2D:
			# Chck if ball has the pickup function, make sure player isn't holding it already
			if collider.has_method("pickup") and not collider.is_held:
				collider.pickup(self)
				held_ball = collider # Remember which ball we just grabbed
