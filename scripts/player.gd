extends CharacterBody2D


const SPEED = 500.0
const ACCELERATION = 2500.0
const FRICTION = 3000.0
const JUMP_VELOCITY = -800.0

# Gets gravity from project settings and multiplied by a fast falling effect
# Can be made a variable for different abilities later, but 1.8 is a magic number for now
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 1.8

func _physics_process(delta: float) -> void:
	# Add gravity if not on the floor
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle explosive jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Variable jump height, if you let go of jump while moving up, cut the speed in half
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

	# Get movement input (Left/Right) and apply acceleration
	var direction := Input.get_axis("left", "right")
	if direction:
		# Speed up smoothly toward top speed
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		# Skid to a stop instead of a hard stop
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	move_and_slide()
