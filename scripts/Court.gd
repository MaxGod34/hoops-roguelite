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

# Opponent Unique Vars
var sammy_required_shot: int = 0 # 0 means any shot is allowed


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

	
	$ReplayViewer.replay_finished.connect(_on_replay_finished)
	$ReplayViewer.replay_tick.connect(_on_replay_tick)
	
	
	var shot_clocks = get_tree().get_nodes_in_group("shot_clock")
	if shot_clocks.size() > 0:
		shot_clocks[0].timeout_violation.connect(_on_shot_clock_violation)
	
	# ================ WHEEL OF FATE MODIFIERS ==================
	if GameManager.start_up_1_0:
		player_score = 1
		print("Wheel Buff: Player starts up 1")
	elif GameManager.start_down_0_1:
		bot_score = 1
		print("Wheel Debuff: Bot starts up 1")
	
	if GameManager.start_mach_3:
		MachManager.add_mach(2.0)
		print("Wheel Buff: Starting at Mach 3")
	
	GameManager.start_up_1_0 = false
	GameManager.start_down_0_1 = false
	GameManager.start_mach_3 = false
	# ===========================================================
	
	
	# Fire off so we start at 0-0 plus any wheel buffs/debuffs
	score_changed.emit(player_score, bot_score, MachManager.visual_mach)
	
	
	#===========Enemy Initialization==========
	var pool_to_pull = "Q1_REGULAR"
	
	if GameManager.current_game == GameManager.max_games_per_quarter:
		pool_to_pull = "Q1_BOSS"
	
	var next_enemy = GlobalData.pick_random_enemy(pool_to_pull)
	
	if next_enemy == "":
		print("Pool empty!")
		return
		
	GlobalData.current_enemy_id = next_enemy
	var active_stats = GlobalData.get_current_enemy_data()
	
	if bot and bot.has_method("initialize_stats"):
		bot.initialize_stats(active_stats)
	
	apply_arena_rules(active_stats)
	#========================================
	
	#=============GAME START=================
	print("Tip Off! Setting up initial check...")
	
	HighlightManager.start_recording()
	
	# Force bot to grab ball and start on D
	reset_play(bot)

func _physics_process(_delta: float):
	if game_state in ["PLAYING", "CHECKING", "GAME_OVER"]:
		# Only record if the ball is actually in the scene tree
		var active_ball = null
		var balls = get_tree().get_nodes_in_group("ball")
		if balls.size() > 0:
			active_ball = balls[0]
		
		var current_clock: float = 0.0
		var shot_clocks = get_tree().get_nodes_in_group("shot_clock")
		if shot_clocks.size() > 0:
			current_clock = shot_clocks[0].current_time
		
		HighlightManager.record_frame(
			player, 
			bot, 
			active_ball, 
			player_score, 
			bot_score, 
			MachManager.current_mach,
			current_clock
		)



func _process(_delta: float):
	$CanvasLayer/DebugMach.text = "MACH: X" + str(MachManager.visual_mach) + " (" + str(
														snapped(MachManager.current_mach, 0.01)) + ")"


func record_shot(shooter: Node2D):
	last_shooter = shooter
	# The instant the ball is shot, the ball is uncleared and we'll set it back if need be
	is_ball_cleared = false
	
	var attempted_points = 2
	var active_stats = GlobalData.get_current_enemy_data()
	
	var threes_allowed = true
	if active_stats != null and active_stats.no_threes:
		threes_allowed = false
	
	
	print("--- SHOT WENT UP ---")
	print("Shooter Name: ", shooter.name)
	print("Who is in the VIP List right now: ", bodies_in_clear_zone)
	# ------------------------------
	
	if threes_allowed and (bodies_in_clear_zone.has(shooter) or $ClearZone.overlaps_body(shooter)):
		attempted_points = 3

	# SAMMY SPICE RULE
	if active_stats != null and active_stats.alternating_shots:
		if sammy_required_shot != 0 and attempted_points != sammy_required_shot:
			print("BZZZZZT! Sammy Spice Violation! Expected a ", sammy_required_shot, "!")
			turnover(shooter)
			return
		
		# Legal shot
		sammy_required_shot = 2 if attempted_points == 3 else 3
		print("Next shot must be a: ", sammy_required_shot)
	
	
	pending_points = attempted_points
	print(shooter.name + " puts up a " + str(pending_points) + " pter")
	

	
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
	
	var active_stats = GlobalData.get_current_enemy_data()
	if active_stats != null and active_stats.make_it_take_it:
		print("ARENA RULE: Make It Take It! Scorer keeps the ball!")
		
		# RESET
		inbounder = scorer
		receiver = scorer
		
		# Scorer keeps the ball, the scored on has to fetch
		# Inbounder will be the player if the bot scored, otherwise, bot must be inbounder
		inbounder = player if scorer == bot else bot
		receiver = scorer
	
	
	# Give them their stage directions
	inbounder.start_check_sequence("FETCH")
	receiver.start_check_sequence("RECEIVE")
	
	self.receiver = receiver



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
	
	if violator == player:
		MachManager.reset_to_base() # Full Reset on a Turnover
		player_turnovers += 1
	else:
		bot_turnovers += 1
	
	if violator.has_method("force_turnover"): violator.force_turnover()
		
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


func apply_arena_rules(stats: DefenderStats):
	if stats == null: return
	# Speed Glove
	if stats.half_shot_clock:
		print("ARENA RULE: 1/2 Shot Clock Active!")
		get_tree().call_group("shot_clock", "set_active_max", 15.0)
	else:
		get_tree().call_group("shot_clock", "set_active_max", 30.0)
	# Tree McGee
	if stats.disable_dribble_moves:
		print("ARENA RULE: Crossovers Disabled!")
	# Ol' Reggie
	if stats.no_take_backs:
		print("ARENA RULE: Ol Reggie says NO TAKE BACKS! NO 3s!")
		force_no_take_back = true
	else:
		force_no_take_back = false
	# Janitor
	if stats.slippery_floor:
		print("ARENA RULE: ICE RINK! SLIPPERY FLOOR ACTIVE!")
		player.friction = 400.0
	else:
		player.friction = 2000.0


func _on_hoop_basket_scored(points, scorer):
	if scorer.name == "Player":
		player_score += points
		print("Player Score: ", player_score)
	else:
		bot_score += points
		print("Bot Score: ", bot_score)
		
	
	
	#========================
	# MACH MODIFIERS
	#========================
	if scorer == player:
		if points == 3:
			MachManager.add_mach(0.75) # FROM DEEEEEEP
		else:
			MachManager.add_mach(0.5)	# STANDARD +0.5 add more on a dunk elsewhere
	elif scorer == bot:
		MachManager.reduce_mach(1.0)	# THE CROWD GOES BOOOOO

	score_changed.emit(player_score, bot_score, MachManager.visual_mach)

	if player_score >= target_score:
		game_state = "GAME_OVER"
		print("-------VICTORY!--------")
		game_over.emit("Player")
		get_tree().call_group("shot_clock", "stop_clock")
		bot.state = "IDLE"
		await get_tree().create_timer(1.5).timeout
		
		HighlightManager.force_pending_capture()
		HighlightManager.stop_recording()
		
		# Mark the enemy as defeated!
		GlobalData.mark_current_enemy_defeated()
		
		get_tree().paused = true
		
		# Hide the real physical entities
		player.hide()
		bot.hide()
		if ball: ball.hide()
		
		# Roll the tape!
		$ReplayViewer.start_replay(MachManager.visual_mach)
		
		
		
	
	
	
	elif bot_score >= target_score:
		game_state = "GAME_OVER"
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


func _on_replay_finished():
	# 1. Determine base drops based on current game in quarter
	var drop_count = 1
	var current_game = GameManager.current_game
	if current_game == 3 or current_game == 4:
		drop_count = 2
	elif current_game == 5 or current_game == 6:
		drop_count = 3
	elif current_game == 7:
		pass
	
	# 2. Check Wheel of Fate +1 bonus
	if GameManager.wheel_extra_thread_next_game:
		drop_count += 1
		print("Wheel Buff: Dropping an extra thread!")
		GameManager.wheel_extra_thread_next_game = false
	
	# 3. Roll the loot!
	var rewards_array: Array[AccessoryData] = []
	
	for i in range(drop_count):
		var reward = LootManager.roll_for_loot()
		# Make sure we still have items in the pool
		if reward != null:
			rewards_array.append(reward)
	
	# 4. Send the array to the victory screen
	if rewards_array.size() > 0:
		$CanvasLayer/VictoryScreen.show_victory(rewards_array)
	else:
		# Safety Fallback: If loot pool is empty, go straight to locker room
		get_tree().paused = false
		TransitionManager.transition_to_scene("res://scenes/LockerRoom.tscn")

func _on_replay_tick(p_score, b_score, mach_val, clock_val):
	# Instantly update visual scoreboard to the frame's exact score
	score_changed.emit(p_score, b_score, mach_val)
	
	# Update the Mach text to show what the coil was doing at the exact moment
	$CanvasLayer/DebugMach.text = "MACH: X" + str(mach_val) + " (REPLAY)"
	
	get_tree().call_group("shot_clock", "force_displayed_time", clock_val)
