extends CharacterBody2D

@export var move_speed: float = 100.0
@export var friction: float = 800.0

var state: String = "IDLE" # IDLE, CHASING, GUARDING, CONTESTING, OFFENSE_IDLE, DRIVING, BOT_SHOOTING


var player: Node2D = null
var hoop: Node2D = null


var ball: Node2D = null
var held_ball: Node2D = null
var has_ball: bool = false

var offense_timer: float = 0.0
var size_up_time: float = 1.5
var drive_speed_multiplier: float = 1.2


func _ready():
	# Find the ball
	var balls = get_tree().get_nodes_in_group("ball")
	if balls.size() > 0: ball = balls[0]
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0: player = players[0]
	# Find the hoop
	var hoops = get_tree().get_nodes_in_group("hoop")
	if hoops.size() > 0: hoop = hoops[0]


func _physics_process(delta: float) -> void:
	if not ball or not player or not hoop:
		return # Safety Net
		
	# Think you stupid bot
	evaluate_state()
	
	# Act on it...you stupid bot
	match state:
		"GUARDING":
			guard_player(delta)
		"CHASING":
			chase_ball(delta)
		"CONTESTING":
			contest_shot(delta)
		"OFFENSE_IDLE":
			offense_idle(delta)
		"DRIVING":
			drive_to_hoop(delta)
		"BOT_SHOOTING":
			# Stop and shoot
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		"IDLE":
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# MOVE YOUR ASS...stupid bot
	move_and_slide()

# -- LOGIC --

func evaluate_state():
	# -- Top Level Split
	if ball.state == "HELD" and ball.player == self:
		# ===============================================
		# 		OFFENSE (Bot has the ball)
		# ===============================================
		if state not in ["OFFENSE_IDLE", "DRIVING", "BOT_SHOOTING"]:
			
			state = "OFFENSE_IDLE"
			offense_timer = size_up_time
	else:
		# ===============================================
		#		DEFENSE (Bot does not have ball)
		# ===============================================
		if ball.state == "LOOSE" or ball.state == "REBOUNDING":
			state = "CHASING"
		elif ball.state == "HELD" and ball.player == player:
			state = "GUARDING"
		elif ball.state == "SHOOTING":
			state = "CONTESTING"
		else:
			# Default Fallback
			state = "IDLE"



# -- ACTIONS --
func offense_idle(delta: float):
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	# Start a timer that changes them to shooting or driving
	offense_timer -= delta
	if offense_timer <= 0:
		# Make a decision, random for now
		var decision = randi() % 100
		if decision < 50:
			state = "DRIVING"
		else:
			state = "BOT_SHOOTING"
			bot_shoot()

func drive_to_hoop(delta: float):
	var dist_to_hoop = global_position.distance_to(hoop.global_position)
	
	if dist_to_hoop < 100.0:
		state = "BOT_SHOOTING"
		bot_shoot()
		return
		
	# Direction to hoop
	var dir_to_hoop = global_position.direction_to(hoop.global_position)
	var move_dir = dir_to_hoop
	
	# Avoid obstacles/player
	var dist_to_player = global_position.distance_to(player.global_position)
	var dir_to_player = global_position.direction_to(player.global_position)
	
	# Check alignment > 0.7 means the player is mostly in front of them
	var alignment = dir_to_hoop.dot(dir_to_player)
	
	# If player is close AND in the way, steer around them
	if dist_to_player < 150.0 and alignment > 0.5:
		# Get a vector 90 degrees from player
		var evasion_dir = dir_to_player.orthogonal()
		
		# Determine which way to juke based on 2D cross product
		var cross = dir_to_hoop.x * dir_to_player.y - dir_to_hoop.y * dir_to_player.x
		if cross < 0:
			evasion_dir = -evasion_dir # Juke the other way
			
		# Blend the hoop direction and the evasion direction
		move_dir = (dir_to_hoop + (evasion_dir * 1.5)).normalized()
		
	# Apply speed burst on a drive
	velocity = move_dir * (move_speed * drive_speed_multiplier)
	
func bot_shoot():
	if not has_ball or not held_ball:
		return
	
	# Calculate how far hoop is to make shot look natural
	var dist = global_position.distance_to(hoop.global_position)
	var flight_time = clamp(dist / ball.base_throw_speed, 0.5, 1.2)
	var arc = clamp(dist / 200.0, 1.1, 1.6)
	
	# Detach ball logic
	has_ball = false
	held_ball = null
	
	# Tell the ball to fire using the shoot function
	ball.shoot_ball(hoop.global_position, arc, flight_time)
	
	# After shooting, they should go to rebound the ball
	
	state = "CHASING"
	
		


func guard_player(delta: float):
	# Find spot between player and the basket
	# 1. Which way is the hoop from the player?
	var direction_to_hoop = player.global_position.direction_to(hoop.global_position)
	
	# 2. Pick a spot 60 pixels towards the hoop from player
	var ideal_defensive_spot = player.global_position + (direction_to_hoop * 60.0)
	
	# 3. Move to the ideal spot
	var direction_to_spot = global_position.direction_to(ideal_defensive_spot)
	var distance_to_spot = global_position.distance_to(ideal_defensive_spot)
	
	# If defender is close enough to the spot, hit the breaks to remove jitter
	if distance_to_spot > 5.0:
		velocity = direction_to_spot * move_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
func chase_ball(delta: float):
	# Sprint straight for the ball's coordinates
	var direction_to_ball = global_position.direction_to(ball.global_position)
	velocity = direction_to_ball * move_speed
	
func contest_shot(delta:float):
	# For now, just stop and watch the ball go towards the hoop
	# Later add z_height on a jump so defender can block the shot
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)



func _on_pickup_zone_body_entered(body: Node2D) -> void:
	# Is it the ball and is it allowed to be grabbed?
	if body.is_in_group("ball") and body.can_be_picked_up:
		# Check is the ball flying over my stupid bot head
		if body.z_height > 3.0:
			return
			
		# Grab the ball!
		body.pickup(self)
		held_ball = body
		has_ball = true
		
		# Physics process will change the state automatically because
		# The bot has the ball now
		# Will snap to OFFENSE_IDLE
