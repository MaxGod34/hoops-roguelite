extends CharacterBody2D


const SPEED = 200.0

var target = null
var is_stunned = false

func _ready():
	# Find player as soon as defender spawns
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]


func _physics_process(delta: float) -> void:
	if is_stunned:
		# Apply friction so they slide backward to a smooth stop
		velocity = velocity.move_toward(Vector2.ZERO, 2000 * delta)
		move_and_slide()
		return
	
	if target:
		# Calculate exact angle to player
		var direction = global_position.direction_to(target.global_position)
		
		# Move towards them
		velocity = direction * SPEED
		move_and_slide()
		
		# Turnover Logic
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			# If defender bumps into player
			if collider.is_in_group("player"):
				# Let player know they got stripped
				if collider.has_method("force_turnover"):
					collider.force_turnover()
				
				# Apply massive shove in opposite direction
				velocity = -direction * 600
				# Stun timer externally
				apply_stun_cooldown()
				
				# Break out of loop
				break
# This way we don't pause the physics process function directly
func apply_stun_cooldown():
	is_stunned = true
	await get_tree().create_timer(1.0).timeout
	is_stunned = false
