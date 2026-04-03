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

# Stat Tracking
var player_turnovers: int = 0
var bot_turnovers: int = 0
var current_possession: Node2D = null


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
	var shot_clocks = get_tree().get_nodes_in_group("shot_clock")
	if shot_clocks.size() > 0:
		shot_clocks[0].timeout_violation.connect(_on_shot_clock_violation)
	
	# Fire off so we start at 0-0
	score_changed.emit(player_score, bot_score)
	
	#=============GAME START=================
	print("Tip Off! Setting up initial check...")
	# Force bot to grab ball and start on D
	reset_play(bot)


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
		if rebounder == receiver:
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
	
	get_tree().call_group("shot_clock", "reset_clock")
	get_tree().call_group("shot_clock", "stop_clock")
	
	
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
	
	get_tree().call_group("shot_clock", "start_clock")
	
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


func turnover(violator: Node2D):
	print("Violation! Turnover committed by: ", violator.name)
	
	if violator.name == "Player":
		player_turnovers += 1
	else:
		bot_turnovers += 1
	
	if violator.has_method("force_turnover"):
		violator.force_turnover
		
	print("Player TO: " + str(player_turnovers))
	print("Bot TO: " + str(bot_turnovers))
		
	reset_play(violator)

func register_possession_change(new_holder: Node2D, previous_ball_state: String):
	# Did game just start?
	if current_possession == null:
		current_possession = new_holder
		return
	
	# Did someone pick up their own fumble?
	if current_possession == new_holder:
		return
		
	# Then it's a change of possession
	var loser = current_possession
	current_possession = new_holder
	
	# Always reset shot clock on a possession change
	get_tree().call_group("shot_clock", "reset_clock")
	
	# IGNORE CHECK UP PASS REF CMON
	if is_inbound_pass:
		return
	
	
	# For stats: was it a rebound or a turnover?
	if previous_ball_state == "LOOSE" and is_ball_cleared == true:
		print("LIVE BALL TURNOVER! " + loser.name + " lost it to " + new_holder.name)
		
		# Log stat
		if loser.name == "Player":
			player_turnovers += 1
		else:
			bot_turnovers += 1
	
	elif previous_ball_state == "REBOUNDING" or (previous_ball_state == "LOOSE" and is_ball_cleared == false):
		print("DEFENSIVE REBOUND by " + new_holder.name + "! (Shot Clock Reset)")





func _on_hoop_basket_scored(points, scorer):
	if scorer.name == "Player":
		player_score += points
		print("Player Score: ", player_score)
	else:
		bot_score += points
		print("Bot Score: ", bot_score)
		
	score_changed.emit(player_score, bot_score)
		
		
	if player_score >= target_score:
		print("-------VICTORY!--------")
		game_over.emit("Player")
		get_tree().paused = true
	
	elif bot_score >= target_score:
		print("-------DEFEAT!---------")
		game_over.emit("Bot")
		
		$GameOverScreen.show_game_over("Bot", player_score, player_turnovers)
		
		# Freeze everything
		get_tree().paused = true
		
	else:
		reset_play(scorer)


func _on_shot_clock_violation():
	var violator = player # Default
	
	if bot.has_ball or (ball.state == "LOOSE" and last_shooter == bot):
		violator = bot
		
	# TRIGGER IT BOI
	turnover(violator)



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
