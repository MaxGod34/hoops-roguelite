extends CharacterBody2D

@export var move_speed: float = 100.0
@export var friction: float = 800.0

var state: String = "IDLE" # CHASING, GUARDING, CONTESTING, OFFENSE_IDLE


var player: Node2D = null
var hoop: Node2D = null


var ball: Node2D = null
var held_ball: Node2D = null
var has_ball: bool = false

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
		# Later add other states for driving, shooting, passing
		state = "OFFENSE_IDLE"
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
	# Start a timer that changes them to shooting or driving later


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
