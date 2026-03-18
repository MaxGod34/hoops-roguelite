extends RigidBody2D

@export var throw_power = 1000.0

var is_held = false
var player = null
var can_be_picked_up = true # Cooldown Flag

var pending_throw = false
var throw_aim = Vector2.ZERO
var throw_vel = Vector2.ZERO
var throw_start_pos = Vector2.ZERO

# When player touches ball
func pickup(new_player):
	# Ignore pickup if we just threw it
	if not can_be_picked_up:
		return
	
	is_held = true
	player = new_player
	
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	freeze = true
	$CollisionShape2D.set_deferred("disabled", true)
	
	# SAFEGUARD 1: Wipe the ball's memory of its old speed when we pick it up
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

func _physics_process(delta: float) -> void:
	if is_held and player:
		# Snap ball's pos to player's pos
		global_position = player.global_position + Vector2(30, 20)

func throw(aim_direction: Vector2, player_velocity: Vector2):
	# Stand-Still Fix
	# If standing still, default to throwing "up" the court 
	# so it doesn't spawn inside chest
	if aim_direction == Vector2.ZERO:
		aim_direction = Vector2.UP 
	
	is_held = false
	
	# Double check momentum is zeroed out before the throw
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

	# Move it out of the chest safely
	throw_start_pos = player.global_position + (aim_direction * 80)
	throw_aim = aim_direction
	throw_vel = player_velocity
	pending_throw = true
	# old code -> global_position = player.global_position + Vector2(30,20) + (aim_direction * 80)
	
	player = null
	
	await get_tree().physics_frame
	
	# UNFREEZE so physics take over again
	freeze = false
	$CollisionShape2D.set_deferred("disabled", false)
	
	# Anti-Self-Pass Fix
	can_be_picked_up = false
	await get_tree().create_timer(0.3).timeout
	can_be_picked_up = true
	
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if pending_throw:
		pending_throw = false
		
		# 1. Force the actual physics hitboxes to teleport to the new coordinates
		var new_transform = state.transform
		new_transform.origin = throw_start_pos
		state.transform = new_transform
		
		# 2. Wipe the engine's memory of any old bouncing momentum
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		
		# 3. Apply massive shove directly to the physics state
		state.apply_central_impulse((throw_aim * throw_power) + throw_vel)
