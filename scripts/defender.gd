# defender.gd
extends CharacterBody2D

@export var move_speed: float = 100.0
@export var friction: float = 800.0

var state: String = "IDLE" 
# IDLE, CHASING, GUARDING, CONTESTING, SWIPING
# OFFENSE_IDLE, DRIVING, BOT_SHOOTING, CLEARING_BALL


var player: Node2D = null
var hoop: Node2D = null


var ball: Node2D = null
var held_ball: Node2D = null
var has_ball: bool = false

var active_stats: DefenderStats

@export var dunk_rating: int = 85 # Higher/Lower set a threshold

@export var steal_rating: int = 75
# Steal Mechanic
var swipe_cooldown: float = 0.0
var swipe_range: float = 65.0 	# 5 more than the guard range!

@export var ball_handle: int = 70
var offense_timer: float = 0.0
var size_up_time: float = 1.5
var drive_speed_multiplier: float = 1.2

@export var block_rating: int = 60
var contest_range: float = 75.0
var is_contesting: bool = false

# SHOOTING MECHANICS
var jump_z: float = 0.0
var jump_tween: Tween
var jump_duration: float = 0.6


@export var strength: int = 100


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

func _physics_process(delta: float):
	if not ball or not player or not hoop:
		return # Safety Net
	
	if swipe_cooldown > 0:
		swipe_cooldown -= delta
	
	# Think you stupid bot
	if state != "CHECK_UP_CUTSCENE":
		evaluate_state()
	
	# Act on it...you stupid bot
	match state:
		"BUMPED":
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
		"CHECK_UP_CUTSCENE":
			process_check_up(delta)
		#======================================DEF===============================================
		"GUARDING":
			guard_player(delta)
		"CHASING":
			chase_ball(delta)
		"CONTESTING":
			contest_shot(delta)
		"SWIPTING":
			# Freeze bot so they stand still while reaching
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		#=========================================================================================
		"CLEARING_BALL":
			clear_ball(delta)
		#=====================================OFF=================================================
		"DRIVING":
			drive_to_hoop(delta)
		"BOT_SHOOTING":
			# Stop and shoot
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		"OFFENSE_IDLE":
			offense_idle(delta)
		#=========================================================================================
		"IDLE":
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# MOVE YOUR ASS...stupid bot
	move_and_slide()
	
	# Scan for player while driving
	check_physical_contact()
	
	_vacuum_check()
	
	#==================DRIBBLE CONTROLLER====================
	if has_ball and held_ball != null:
		# Only bounce if the game is live and we aren't mid-check/cutscene
		if get_parent().game_state == "PLAYING" and state != "CHECKING":
			held_ball.is_dribbling = true
		else:
			held_ball.is_dribbling = false
			
	#-- VISUAL JUMP STATE --
	if has_node("Sprite2D"):
		$Sprite2D.position.y = -jump_z
	if held_ball != null and state == "BOT_SHOOTING":
		held_ball.position.y = -jump_z

func initialize_stats(new_stats: DefenderStats):
	if new_stats == null: return
	
	active_stats = new_stats
	
	# Apply Raw State
	move_speed = 100.0 * active_stats.speed_multiplier
	strength = active_stats.strength_rating
	steal_rating = active_stats.steal_rating
	block_rating = active_stats.block_rating
	dunk_rating = active_stats.dunks_rating
	
	if has_node("Sprite2D") and active_stats.body_sprite != null:
		$Sprite2D.texture = active_stats.body_sprite
	
	print("Spawned Titan: ", active_stats.defender_name, " | Playstyle: ", active_stats.playstyle)
	

# -- LOGIC --

func evaluate_state():
	if get_parent().game_state == "GAME_OVER":
		state = "IDLE"
		return
	
	if state in ["SWIPING", "CONTESTING", "BOT_SHOOTING", "CHECK_UP_CUTSCENE"]:
		return
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
		elif player.is_shooting and not is_contesting and global_position.distance_to(
															player.global_position) < contest_range:
			attempt_contest()
			
		elif ball.state == "HELD" and ball.player == player:
			state = "GUARDING"
		
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
		if decision < 0:
			state = "DRIVING"
		else:
			state = "BOT_SHOOTING"
			bot_shoot()


func drive_to_hoop(_delta: float):
	var rim_pos = hoop.get_node("ShotTarget").global_position
	var dist_to_hoop = global_position.distance_to(rim_pos)
	
	if dist_to_hoop < 150.0:
		state = "BOT_SHOOTING"
		bot_shoot()
		return
		
	# Direction to hoop
	var dir_to_hoop = global_position.direction_to(rim_pos)
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
	
	# Stop dribbling and move the ball to the front
	# THE GATHER
	held_ball.is_dribbling = false
	var rim_position = hoop.get_node("ShotTarget").global_position
	
	# -- Distance Check --
	# Calculate how far hoop is to make shot look natural
	var dist = global_position.distance_to(rim_position)
	
	if dist < 180.0: 	# LAYUP/DUNK
		# Are we moving?
		var is_driving = velocity.length() > 20.0
		
		if is_driving:
			# Decide to dunk based on an arbitrary rating
			# 70 seems good m'lord
			var intent_to_dunk = dunk_rating >= 70
			execute_driving_finish(rim_position, intent_to_dunk)
		else:
			print("BOT shoots a standing LAYUP!")
			execute_bot_shot(rim_position, dist, true)
		

	else:				# JUMPER
		print("Bot pulls up for the JUMPER!")
		start_bot_jump_tween(rim_position, dist)




func start_bot_jump_tween(rim_position: Vector2, dist: float):
	jump_tween = create_tween()
	var peak_time = jump_duration / 2.0
	
	# GOING UP
	jump_tween.tween_property(self, "jump_z", 25.0, peak_time).set_trans(
											Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# GOING DOWN
	jump_tween.tween_property(self, "jump_z", 0.0, peak_time).set_trans(
											Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# AI will always release the ball at the apex of their jump
	await get_tree().create_timer(peak_time).timeout
	
	# Double check they aren't stripped/blocked in the air
	if state == "BOT_SHOOTING" and has_ball:
		execute_bot_shot(rim_position, dist, false)

func execute_bot_shot(rim_position: Vector2, dist: float, is_layup: bool):
	get_parent().record_shot(self)
	if held_ball != null:
		held_ball.point_value = get_parent().pending_points
	# Fire the correct shot type
	if is_layup:
		held_ball.layup_ball(rim_position)
	else:
		var flight_time = clamp(dist / held_ball.base_throw_speed, 0.5, 1.2)
		var arc = clamp(dist / 200.0, 1.1, 1.6)
		held_ball.shoot_ball(rim_position, arc, flight_time)
		
	# Detach ball logic
	has_ball = false
	held_ball = null
	state = "CHASING" # Go after the rebound
	
	# Snap visuals back to floor
	if jump_tween and jump_tween.is_valid():
		jump_tween.kill()
	if has_node("Sprite2D"): $Sprite2D.position.y = 0
	jump_z = 0.0



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
		
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player < swipe_range and swipe_cooldown <= 0:
		attempt_swipe()
		
func chase_ball(_delta: float):
	# Sprint straight for the ball's coordinates
	var direction_to_ball = global_position.direction_to(ball.global_position)
	velocity = direction_to_ball * move_speed

func attempt_swipe():
	# Put bot on cooldwon and freeze on the reach
	swipe_cooldown = 2.5
	state = "SWIPING"
	
	# Dice roll o'clock
	var base_chance = 10
	var stat_diff = steal_rating - player.ball_handle
	
	# If player is doing a crossover in front of my face, punish them
	if player.is_tricking:
		stat_diff += 30
		
	# Clamp it at min 5% and max 95% chance
	var success_chance = clamp(base_chance + stat_diff, 5, 95)
	var roll = randi() % 100
	
	print("Bot swipes! Need < ", success_chance, ". Rolled: ", roll)
	
	# The Result
	if roll < success_chance:
		print("STEAL SUCCESSFUL! Ball knocked loose!")
		player.force_turnover()
	else:
		print("WHIFF! Bot reached in and missed! Make him suffer!")
		
	# Freeze bot for 0.4 seconds then let them recover
	await get_tree().create_timer(0.4).timeout
	
	# Return to normal logic if they didn't grab the ball during the freeze
	if state == "SWIPING":
		state = "IDLE"


func contest_shot(delta:float):
	# Freeze horizontal movement while in the air
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Only check for a physical block if the ball has actually left the player's hands
	if ball.state == "SHOOTING":
		
		# Are we horizontally close to the ball?
		if global_position.distance_to(ball.global_position) < 35.0:
			# Are we vertically intersecting? (3D Check)
			# If ball's height and bot's height are wihtin 12 pixels, it's a block
			if abs(ball.z_height - jump_z) < 12.0:
				execute_block()

func execute_block():
	print("GET THAT WEAK SHIT OUTTA HERE!")
	
	# Stop checking for multiple blocks on the same frame
	state = "IDLE"
	
	# Calc a rough vector to spike the ball away from the hoop
	var deflect_dir = (ball.global_position - hoop.global_position).normalized()
	
	# Tell the ball it just got rejected
	ball.reject_shot(deflect_dir)



func clear_ball(_delta: float):
	# Safety Net: Stop backing up if you already have the ball in the clear zone
	if get_parent().bodies_in_clear_zone.has(self):
		get_parent().is_ball_cleared = true
		return
	
	
	
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
	
	if state != "BOT_SHOOTING":
		state = "CHECK_UP_CUTSCENE"

func process_check_up(_delta: float):
	var target_pos = Vector2.ZERO
	var distance_to_target = 0.0
	var court = get_parent()
	
	if check_role == "RECEIVE":
		# Loser walks to the Offense Spawn and waits
		target_pos = court.get_node("OffenseSpawn").global_position
		distance_to_target = global_position.distance_to(target_pos)
		
		if distance_to_target > 5.0:
			var dir = global_position.direction_to(target_pos)
			velocity = dir * (move_speed)
		else:
			# Arrived
			velocity = Vector2.ZERO
			
			
			
	elif check_role == "FETCH":
		# Scorer has a 2 part mission
		if not has_ball:
			# Go get the ball
			var ball_node = get_tree().get_nodes_in_group("ball")[0]
			target_pos = ball_node.global_position
			distance_to_target = global_position.distance_to(target_pos)
			
			# Run slightly faster for game pace
			var dir = global_position.direction_to(target_pos)
			velocity = dir * (move_speed * 1.5)
			
		else:
			# Got the ball, walk to the defense spawn
			target_pos = court.get_node("DefenseSpawn").global_position
			distance_to_target = global_position.distance_to(target_pos)
			
			if distance_to_target > 5.0:
				var dir = global_position.direction_to(target_pos)
				velocity = dir * move_speed
			else:
				# Arrived at defense spawn
				velocity = Vector2.ZERO
				
				# -- WAIT FOR THE RECEIVER TO BE IN PLACE --
				var receiver_target = court.get_node("OffenseSpawn").global_position
				var dist_to_receiver = court.receiver.global_position.distance_to(receiver_target)
				# IF RECEIVER IS MORE THAN 15 PIXELS FROM THEIR SPOT, WAIT!	
				if dist_to_receiver > 15.0:
					return
				# ------------------------------------------
				
				check_role = "WAITING"
				
				await get_tree().create_timer(0.5).timeout
				
				# Auto aim the pass
				var pass_dir = global_position.direction_to(court.receiver.global_position)
				
				if held_ball != null:
					held_ball.throw(pass_dir, Vector2.ZERO, 0.5)
				
				held_ball = null
				has_ball = false

				court.resume_game()
			

func force_turnover():
	if held_ball:
		held_ball.is_dribbling = false
		var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		# Use throw function with zero momentum so it pops out
		held_ball.throw(random_dir, Vector2.ZERO, 0.75)
		
		held_ball = null
		has_ball = false
		
	# Reset physical states so the bot return to the floor in case they are stripped/blocked
	if jump_tween and jump_tween.is_valid():
		jump_tween.kill()
	if has_node("Sprite2D"): $Sprite2D.position.y = 0
	jump_z = 0.0
	
	# Evaluate state will automatically switch them to "CHASING" since ball will be loose


func attempt_contest():
	is_contesting = true
	state = "CONTESTING"
	
	# Add a tiny reaction delay so the bot isn't reading inputs instantly
	await get_tree().create_timer(0.1).timeout
	
	# If player passed the ball during reaction time, cancel the jump
	if not player.has_ball and ball.state != "SHOOTING":
		is_contesting = false
		state = "IDLE"
		return 	# Fallback to exit
		
	print ("BOT BITES! Jumping to contest!")
	
	jump_tween = create_tween()
	var peak_time = jump_duration / 2.0
	
	# Calculate block height based on the attribute
	var max_jump = 15.0 + (block_rating * 0.15)
	
	# Go Up
	jump_tween.tween_property(self, "jump_z", max_jump, peak_time).set_trans(
															Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Go Down
	jump_tween.tween_property(self, "jump_z", 0.0, peak_time).set_trans(
															Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await jump_tween.finished
	
	is_contesting = false
	if state == "CONTESTING":
		state = "IDLE" # Let evaluate state figure out next move/state


func execute_driving_finish(rim_position: Vector2, is_dunk: bool):
	# Lock the bot's state so it stops running normal pathing logic
	state = "BOT_SHOOTING"
	held_ball.is_dribbling = false
	
	# Move ball to the dominant hand high up
	var hip_x = 25.0 if held_ball.current_hand == "RIGHT" else -25.0
	held_ball.position = Vector2(hip_x, -15.0)
	
	var takeoff_time = 1.0
	var dir_to_rim = global_position.direction_to(rim_position)
	var target_spot = Vector2.ZERO
	var max_jump = 0.0
	var peak_scale = Vector2(1.0, 1.0)
	
	#================================
	# BRANCHING LOGIC
	#================================
	if is_dunk:
		print("Bot goes up for the POSTER DUNK!")
		max_jump = 45.0
		peak_scale = Vector2(1.3, 1.3)
		
		var hoops = get_tree().get_nodes_in_group("hoop")
		if hoops.size() > 0 and hoops[0].has_node("DunkSpot"):
			target_spot = hoops[0].get_node("DunkSpot").global_position
		else:
			target_spot = rim_position - (dir_to_rim * 15.0)
	
	else:
		print("Bot goes up for the smooth LAYUP!")
		max_jump = 15.0
		peak_scale = Vector2(1.2, 1.2)
		target_spot = rim_position - (dir_to_rim * 60.0)
	
	# 1. Glide to chosen floor spot
	var drive_tween = create_tween()
	drive_tween.tween_property(self, "global_position", target_spot, takeoff_time / 2.0).set_trans(
																					Tween.TRANS_SINE)
	
	# 2. Visual Jump & Scale Up
	jump_tween = create_tween()
	jump_tween.tween_property(self, "jump_z", max_jump, takeoff_time / 2.0).set_trans(
															Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if has_node("Sprite2D"):
		jump_tween.parallel().tween_property($Sprite2D, "scale", peak_scale, 
							takeoff_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(takeoff_time / 2.0).timeout
	
	#-- APEX ACTIONS --
	if held_ball != null:
		get_parent().record_shot(self, is_dunk)
		held_ball.point_value = get_parent().pending_points
		held_ball.layup_ball(rim_position)
		has_ball = false
		held_ball = null
	
	# RIM HANG
	if is_dunk:
		await get_tree().create_timer(0.3).timeout
	
	# 3. Come Back Down
	jump_tween = create_tween()
	jump_tween.tween_property(self, "jump_z", 0.0, takeoff_time / 2.0).set_trans(
															Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	if has_node("Sprite2D"):
		jump_tween.parallel().tween_property($Sprite2D, "scale", Vector2(1.0, 1.0), 
								takeoff_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await jump_tween.finished
	
	# 4. Regain AI control
	if get_parent().game_state == "PLAYING":
		state = "CHASING" # Automatically crashthe boards for a rebound
	else:
		state = "CHECK_UP_CUTSCENE"
	
	if has_node("Sprite2D"): $Sprite2D.position.y = 0
	jump_z = 0.0


func apply_bump(bump_velocity: Vector2, duration: float):
	var previous_state = state
	state = "BUMPED"
	velocity = bump_velocity
	
	await get_tree().create_timer(duration).timeout
	
	# Only restore if they didn't magically get a steal/rebound during the slide
	if state == "BUMPED":
		state = previous_state

func check_physical_contact():
	# Only calculate bulldozer math if we are driving with the ball
	if not has_ball: return
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Did the player hit an entity that can be bumped?
		if collider.has_method("apply_bump"):
			
			# Don't trigger if someone is already sliding
			if state == "BUMPED" or ("is_bumped" in collider and collider.is_bumped): continue
			
			var str_diff = strength - collider.strength
			var hit_normal = collision.get_normal()
			
			#============================
			# MOMENTUM SHIFT
			# Normal points FROM player TO bot
			#============================
			if str_diff >= 15:
				# BULLDOZE: Offense runs them over
				print("TITAN BULLDOZER! Player gets crushed!")
				# Push Player away
				collider.apply_bump(-hit_normal * 400.0, 0.25)
				# Have player try to make a steal mid bump
				collider.attempt_swipe()
				
			elif str_diff <= -15:
				# BRICK WALL: Bot bounces off!
				print("BRICK WALL: Bot bounces off!")
				# Push player away
				apply_bump(hit_normal * 500.0, 0.15)
				
			else:
				# NEUTRAL: Both take a tiny step back to avoid sticking
				apply_bump(hit_normal * 200.0, 0.1)
				collider.apply_bump(-hit_normal * 200.0, 0.1)

func _vacuum_check():
	if not has_node("PickupZone"): return
	
	var bodies = $PickupZone.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("ball") and body.can_be_picked_up and not body.is_held:
			# Check is the ball flying over my stupid bot head
			if body.z_height > 3.0: continue
			
			#--------------------CHECK-UP FALLBACK----------------------------------------
			if "game_state" in get_parent() and get_parent().game_state == "CHECKING":
				if check_role != "FETCH":
					continue
			#-----------------------------------------------------------------------------
			
			var previous_state = body.state
			var was_inbound_pass = get_parent().is_inbound_pass
			
			
			# Grab the ball
			body.pickup(self)
			held_ball = body
			has_ball = true
			
			print("Bot vacuumed the ball! State was: ", body.state)
			
			get_parent().register_possession_change(self, previous_state)
			
			if previous_state == "LOOSE" or previous_state == "REBOUNDING":
				if not was_inbound_pass:
					get_parent().handle_rebound(self)
	
