# Court.gd
extends Node2D

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

# Modifier Flag for No Take Backs
var force_no_take_back: bool = false

# Check-Up Vars
var game_state: String = "PLAYING" # Playing or Checking
var inbounder: Node2D = null
var receiver: Node2D = null


func _ready():
	$ClearZone.body_entered.connect(_on_clear_zone_body_entered)
	$Hoop.basket_scored.connect(_on_hoop_basket_scored)


func record_shot(shooter: Node2D):
	last_shooter = shooter
	# The instant the ball is shot, the ball is uncleared and we'll set it back if need be
	is_ball_cleared = false
	
	if $ClearZone.overlaps_body(shooter):
		pending_points = 3
		print(shooter.name + " put up a 3 pter!")
	else:
		pending_points = 2
		print(shooter.name + " put up a 2 pter!")
	
	
func handle_rebound(rebounder: Node2D):
	if game_state == "CHECKING":
		return
	
	if force_no_take_back:
		is_ball_cleared = true
		return
		
	if rebounder == last_shooter:
		is_ball_cleared = true
		print("OFFENSIVE REBOUND! Live Ball!")
	else:
		# Check if you are already standing in the Clear Zone when obtaining ball
		if $ClearZone.overlaps_body(rebounder):
			is_ball_cleared = true
			print("Defensive Rebound caught outside the arc! Ball Cleared!")
		else:
			is_ball_cleared = false
			print("Defensive Rebound! CLEAR BALL ASAP!")

func reset_play(scorer: Node2D):
	game_state = "CHECKING"
	is_ball_cleared = true
	
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
	
	# Give brains back
	player.has_control = true
	bot.state = "OFFENSE_IDLE" if bot.has_ball else "GUARDING"

func _on_hoop_basket_scored(points, scorer):
	if scorer.name == "Player":
		player_score += points
		print("Player Score: ", player_score)
	else:
		bot_score += points
		print("Bot Score: ", bot_score)
		
	if player_score >= target_score or bot_score >= target_score:
		print("GAME OVER!")
	else:
		reset_play(scorer)

func _on_clear_zone_body_entered(body: Node2D):
	#print("SOMETHING TOUCHED THE CLEAR ZONE: ", body.name)
	# Check if body entering zone has the ball
	if body.get("has_ball") == true:
		print(body.name, " entered the zone WITH the ball.")
		if not is_ball_cleared:
			is_ball_cleared = true
			print("Ball Cleared! Attack the rack!")
