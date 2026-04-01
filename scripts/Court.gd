# Court.gd
extends Node2D

# Scoreboard Signals
signal score_changed(player_score, bot_score)
signal game_over(winner_name)

# Player/Bot/Ball References
@onready var player = get_node("Player")
@onready var bot = get_node("Defender")
@onready var ball = get_node("Ball")

# Score Tracking
var player_score: int = 0
var bot_score: int = 0
var target_score: int = 11
var pending_points: int = 2

# Ref Variables
var is_ball_cleared: bool = true
var last_shooter: Node2D = null
var bodies_in_clear_zone: Array = []
var is_inbound_pass: bool = false

# Modifier Flag for No Take Backs
var force_no_take_back: bool = false

# Check-Up Vars
var game_state: String = "PLAYING" # Playing or Checking
var inbounder: Node2D = null
var receiver: Node2D = null


func _ready():
	$ClearZone.body_entered.connect(_on_clear_zone_body_entered)
	$ClearZone.body_exited.connect(_on_clear_zone_body_exited)
	$Hoop.basket_scored.connect(_on_hoop_basket_scored)
	
	#--Boot Up Scan--
	await get_tree().physics_frame
	
	# Manually check who is in the zone
	var overlaps = $ClearZone.get_overlapping_bodies()
	for body in overlaps:
		if body is CharacterBody2D and not bodies_in_clear_zone.has(body):
			bodies_in_clear_zone.append(body)
			
	# Connect Signals
	score_changed.connect($Scoreboard.update_scores)
	game_over.connect($Scoreboard.show_game_over)
	
	# Fire off so we start at 0-0
	score_changed.emit(player_score, bot_score)


func record_shot(shooter: Node2D):
	last_shooter = shooter
	# The instant the ball is shot, the ball is uncleared and we'll set it back if need be
	is_ball_cleared = false
	

	
	
	print("--- SHOT WENT UP ---")
	print("Shooter Name: ", shooter.name)
	print("Who is in the VIP List right now: ", bodies_in_clear_zone)
	# ------------------------------
	
	if bodies_in_clear_zone.has(shooter) or $ClearZone.overlaps_body(shooter):
		pending_points = 3
		print(shooter.name + " put up a 3 pter!")
	else:
		pending_points = 2
		print(shooter.name + " put up a 2 pter!")
	
	
func handle_rebound(rebounder: Node2D):
	#-- Reroutes --
	if game_state == "CHECKING":
		return # Check Up Reroute
	if force_no_take_back:
		is_ball_cleared = true
		return # Ol Reggies/Accessory Reroute
	if is_inbound_pass:
		is_inbound_pass = false
		return
	#--------------
	
	if rebounder == last_shooter:
		is_ball_cleared = true
		print("OFFENSIVE REBOUND! Live Ball!")
	else:
		# Check if you are already standing in the Clear Zone when obtaining ball
		if bodies_in_clear_zone.has(rebounder):
			is_ball_cleared = true
			print("Defensive Rebound caught outside the arc! Ball Cleared!")
		else:
			is_ball_cleared = false
			print("Defensive Rebound! CLEAR BALL ASAP!")

func reset_play(scorer: Node2D):
	game_state = "CHECKING"
	is_ball_cleared = true
	
	# Allows phasing through each other during the transition
	player.add_collision_exception_with(bot)
	bot.add_collision_exception_with(player)
	
	is_inbound_pass = true
	
	# SCORER fetches the ball and plays defense
	# Former defender goes to the top of the key
	if scorer == player:
		inbounder = player
		receiver = bot
	else:
		inbounder = bot
		receiver = player
		
	# Give them their stage directions
	inbounder.start_check_sequence("FETCH")
	receiver.start_check_sequence("RECEIVE")



func resume_game():
	game_state = "PLAYING"
	print("CHECK-UP COMPLETE! GAME ON!")
	
	# Anti phasing, recollision logic
	player.remove_collision_exception_with(bot)
	bot.remove_collision_exception_with(player)
	
	
	# -- 3pt fix --
	await get_tree().physics_frame
	await get_tree().physics_frame
	bodies_in_clear_zone.clear()
	
	var overlaps = $ClearZone.get_overlapping_bodies()
	for body in overlaps:
		if body is CharacterBody2D:
			bodies_in_clear_zone.append(body)
	
	# Give brains back
	player.has_control = true
	bot.state = "OFFENSE_IDLE" if bot.has_ball else "GUARDING"
	is_ball_cleared = true

func _on_hoop_basket_scored(points, scorer):
	if scorer.name == "Player":
		player_score += points
		print("Player Score: ", player_score)
	else:
		bot_score += points
		print("Bot Score: ", bot_score)
		
	score_changed.emit(player_score, bot_score)
		
		
	if player_score >= target_score or bot_score >= target_score:
		game_over.emit(scorer.name)
		print("GAME OVER!")
	else:
		reset_play(scorer)

func _on_clear_zone_body_entered(body: Node2D):
	#print("SOMETHING TOUCHED THE CLEAR ZONE: ", body.name)
	if not bodies_in_clear_zone.has(body):
		bodies_in_clear_zone.append(body)
	# Check if body entering zone has the ball
	if body.get("has_ball") == true:
		if not is_ball_cleared:
			is_ball_cleared = true
			print("Ball Cleared! Attack the rack!")

func _on_clear_zone_body_exited(body: Node2D):
	# Remove them from the list
	if bodies_in_clear_zone.has(body):
		bodies_in_clear_zone.erase(body)
