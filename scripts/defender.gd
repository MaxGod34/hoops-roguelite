# defender.gd
extends CharacterBody2D

@export var move_speed: float = 100.0
@export var friction: float = 800.0

var state: String = "IDLE" 
# IDLE, CHASING, GUARDING, CONTESTING, 
# OFFENSE_IDLE, DRIVING, BOT_SHOOTING, CLEARING_BALL


var player: Node2D = null
var hoop: Node2D = null


var ball: Node2D = null
var held_ball: Node2D = null
var has_ball: bool = false

var offense_timer: float = 0.0
var size_up_time: float = 1.5
var drive_speed_multiplier: float = 1.2

# Check Up Vars
var check_role: String = "" # FETCH, RECEIVE


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
	if state != "CHECK_UP_CUTSCENE":
		evaluate_state()
	
	# Act on it...you stupid bot
	match state:
		
		"CHECK_UP_CUTSCENE":
			process_check_up(delta)
		
		"GUARDING":
			guard_player(delta)
		"CHASING":
			chase_ball(delta)
		"CONTESTING":
			contest_shot(delta)
		
		"CLEARING_BALL":
			clear_ball(delta)

		"DRIVING":
			drive_to_hoop(delta)
		"BOT_SHOOTING":
			# Stop and shoot
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		"OFFENSE_IDLE":
			offense_idle(delta)
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
		
		# Check rulebook first
		if not get_parent().is_ball_cleared:
			state = "CLEARING_BALL"
		# If cleared, PROCEED TO BALL OUT
		elif state not in ["OFFENSE_IDLE", "DRIVING", "BOT_SHOOTING"]:
			
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
	
	if dist_to_hoop < 180.0:
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
	
	# Tell the court/ref we are shooting
	get_parent().record_shot(self)
	
	# Give pts to the ball
	ball.point_value = get_parent().pending_points
	
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

func clear_ball(delta: float):
	# Calculate Vector pointing away directly from the hoop
	var dir_away_from_hoop = hoop.global_position.direction_to(global_position)
	
	# Safety Fallback just in case they are exactly on the same pixel
	if dir_away_from_hoop == Vector2.ZERO:
		dir_away_from_hoop = Vector2.DOWN
		
	# Apply a little bit of hustle to take ball back
	velocity = dir_away_from_hoop * (move_speed * drive_speed_multiplier)
	
	# Once the bot clears the ClearZone area2D, court script flags is_ball_cleared to true
	# Next frame, evaluate_state() snaps them out and into OFFENSE_IDLE with the sizeup timer


func start_check_sequence(role: String):
	check_role = role
	state = "CHECK_UP_CUTSCENE"

func process_check_up(delta: float):
	var target_pos = Vector2.ZERO
	var distance_to_target = 0.0
	var court = get_parent()
	
	if check_role == "RECEIVE":
		# Loser walks to the Offense Spawn and waits
		target_pos = court.get_node("OffenseSpawn").global_position
		distance_to_target = global_position.distance_to(target_pos)
		
		if distance_to_target > 32.0:
			var dir = global_position.direction_to(target_pos)
			velocity = dir * (move_speed)
		else:
			# Arrived
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			
			
	elif check_role == "FETCH":
		# Scorer has a 2 part mission
		if not has_ball:
			# 1. Go get the ball
			var ball_node = get_tree().get_nodes_in_group("ball")[0]
			target_pos = ball_node.global_position
			distance_to_target = global_position.distance_to(target_pos)
			
			# run slightly faster for game pace
			var dir = global_position.direction_to(target_pos)
			velocity = dir * (move_speed * 1.5)
			
		else:
			# 2. Got the ball, walk to the defense spawn
			target_pos = court.get_node("DefenseSpawn").global_position
			distance_to_target = global_position.distance_to(target_pos)
			
			if distance_to_target > 15.0:
				var dir = global_position.direction_to(target_pos)
				velocity = dir * move_speed
			else:
				# Arrived at defense spawn
				velocity = Vector2.ZERO
				
				# Auto aim the pass
				var pass_dir = global_position.direction_to(court.receiver.global_position)
				
				held_ball.throw(pass_dir, Vector2.ZERO)
				
				held_ball = null
				has_ball = false
			
				# Resume Game!
				court.resume_game()
			


func _on_pickup_zone_body_entered(body: Node2D) -> void:
	# Is it the ball and is it allowed to be grabbed?
	if body.is_in_group("ball") and body.can_be_picked_up:
		# Check is the ball flying over my stupid bot head
		if body.z_height > 3.0:
			return
		
		# Snapshot of state
		var previous_state = body.state
			
		# Grab the ball!
		body.pickup(self)
		held_ball = body
		has_ball = true
		
		print("Bot grabbed the ball! State was: ", body.state)
		
		# If the ball was loose, it means it's a rebound or a steal
		if previous_state == "LOOSE" or previous_state == "REBOUNDING":
			get_parent().handle_rebound(self)
		
		
		# Physics process will change the state automatically because
		# The bot has the ball now
		# Will snap to OFFENSE_IDLE
