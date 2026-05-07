# Player.gd
extends CharacterBody2D


var base_speed: float = 400.0
var current_speed: float = 400.0
const ACCELERATION = 2500.0

var friction = 2000.0

# For moving test ball around, magic number
const PUSH_FORCE = 20.0

var held_ball = null
var has_control: bool = true
var has_ball: bool = false


var is_bumped: bool = false

# Steal Mechanic
var is_swiping: bool = false
var swipe_cooldown: float = 0.0
var swipe_range: float = 65.0

var is_contesting: bool = false

#=== Shooting & Dribble Mechanics ===
var dribble_picked_up: bool = false
var is_shooting: bool = false
var shoot_timer: float = 0.0

var jump_z: float = 0.0 # Visual Jump Height
var jump_tween: Tween
var jump_duration: float = 0.6 # Total air time (up & down)

var is_tricking: bool = false
#====================================

# Stats pulled from PlayerData
var shooting_rating: int = 50
var finishing_rating: int = 50
var strength: int = 50
var defense_rating: int = 50
var handle_rating: int = 50


# Check Up Vars
var check_role: String = "" # FETCH, RECEIVE

func _ready():
	# Door Transition Resets
	modulate.a = 1.0
	if has_node("Sprite2D"):
		$Sprite2D.scale = Vector2(1.0, 1.0)
	
	update_player_stats()
	PlayerData.stats_updated.connect(update_player_stats)
	

	

func update_player_stats():
	# Sync player mechanics with the global true stats
	shooting_rating = PlayerData.get_effective_stat("shooting")
	finishing_rating = PlayerData.get_effective_stat("finishing")
	handle_rating = PlayerData.get_effective_stat("handle")
	defense_rating = PlayerData.get_effective_stat("defense")
	# Speed modifier 2*value 
	# /(i.e. 100 SPEED = 400.0 + 200.0 = 600.0 move_speed) 
	var speed_rating = PlayerData.get_effective_stat("speed")
	current_speed = base_speed + (speed_rating * 2.0)
	
	strength = PlayerData.get_effective_stat("strength")
	
	print("Player Stats Refreshed! Current Speed: ", speed_rating)


func _physics_process(delta: float) -> void:
	# Removed jump mechanics for top down 8-way movement implementation
	
	if swipe_cooldown > 0:
		swipe_cooldown -= delta
	
	if Input.is_action_just_pressed("block") and not has_ball and not is_contesting:
		attempt_block()
	
	
	# MOVEMENT AND FREEZE LOGIC
	if not has_control or is_tricking or is_swiping or dribble_picked_up or is_contesting or is_bumped:
		if not has_control and "game_state" in get_parent() and get_parent().game_state == "CHECKING" and not is_shooting:
			process_check_up(delta)
			
		else:
			# Let the dash friction out smoothly ignoring player input
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			
		
		if has_node("Sprite2D"):
			$Sprite2D.position.y = -jump_z
		if is_contesting:
			check_for_block()
			

			
	else:
		# NORMAL MOVEMENT
		var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if direction:
			velocity = velocity.move_toward(direction * current_speed, ACCELERATION * delta)
		else:
			# Skid to a stop instead of a hard stop
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)


		
	#-- Passing Logic --
	if Input.is_action_just_pressed("pass") and held_ball and not is_shooting and has_control and not is_tricking:
		# Default to throwing 'up" if player is totally still, otherwise throw in movement direction
		var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var aim_dir = direction
		if aim_dir == Vector2.ZERO and velocity != Vector2.ZERO:
			aim_dir = velocity.normalized()
		elif aim_dir == Vector2.ZERO and velocity == Vector2.ZERO:
			aim_dir = Vector2.UP
			
		held_ball.throw(aim_dir, velocity)
		held_ball = null # Hands will now be empty
		has_ball = false
		
		dribble_picked_up = false
		
	#-- SHOOTING --
	if Input.is_action_just_pressed("shoot") and held_ball and has_control and not is_tricking:
		# Get Court Data
		var hoops_in_scene = get_tree().get_nodes_in_group("hoop")
		if hoops_in_scene.size() > 0:
			var target_hoop = hoops_in_scene[0]
			var rim_position = target_hoop.get_node("ShotTarget").global_position
			var dist_to_hoop = global_position.distance_to(rim_position)
			
			# Is the player moving (If velocity is greater than deadzone check)
			var is_driving = velocity.length() > 50.0
			
			var intent_to_dunk = Input.is_action_pressed("style_modifier")
			
			# Context Decision
			if dist_to_hoop < 180.0 and is_driving:
				# Untimed smooth finish (layup/dunk)
				execute_driving_finish(rim_position, intent_to_dunk)
			
			else:
				# Standard Gather (Jump Shot or standing close shot/pump fake)
				is_shooting = true
				dribble_picked_up = true
				shoot_timer = 0.0
				held_ball.is_dribbling = false
		
				# Move ball to the front of the player towards the hoop
				var dir_to_hoop = global_position.direction_to(target_hoop.global_position)
				held_ball.position = dir_to_hoop * 25
	
	if is_shooting and has_control:
		if Input.is_action_pressed("shoot"):
			# THE HOLD
			shoot_timer += delta
			
			# If held past the 0.15s "gather window", start the jump!
			if shoot_timer > 0.15 and (jump_tween == null or not jump_tween.is_valid()):
				start_jump_tween()
				
		if Input.is_action_just_released("shoot") and held_ball:
			# THE RELEASE
			if shoot_timer <= 0.15:
				# IT WAS A TAP! A TAP! pump fake bb
				is_shooting = false
				print("PUMP FAKE! Dribble is dead!")
				await get_tree().create_timer(0.1).timeout
				if held_ball == null:
					return
				# Bring ball back to the hip
				var hip_x = 25 if held_ball.current_hand == "RIGHT" else -25
				held_ball.position = Vector2(hip_x, 0)
				
			else:
				# Released DURING the jump! SHOOT IT!
				execute_shot()
		
	if has_node("Sprite2D"):
		$Sprite2D.position.y = -jump_z
	if held_ball != null and is_shooting:
		held_ball.position.y = -jump_z
	
	
	if Input.is_action_just_pressed("dribble_move") and held_ball and has_control and not is_shooting and not is_tricking:
		var can_dribble = true
		var active_stats = GlobalData.get_current_enemy_data()
		
		if active_stats != null and active_stats.disable_dribble_moves:
			can_dribble = false
			print("Tree McGee's roots grab your ankles! No Crossovers!")
		
		
		if can_dribble:
			execute_crossover()
	
	if Input.is_action_just_pressed("steal") and not has_ball and swipe_cooldown <= 0 and has_control and not is_contesting:
		attempt_swipe()
	
	move_and_slide()
	
	check_physical_contact()
	
	_vacuum_check()
	
				
					
	if has_ball and held_ball != null:
		# Only bounce if the game is live and player has control
		if get_parent().game_state == "PLAYING" and has_control and not dribble_picked_up:
			held_ball.is_dribbling = true
		else:
			held_ball.is_dribbling = false
				




func start_check_sequence(role: String):
	check_role = role
	has_control = false


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
			velocity = dir * (current_speed * 0.75)
		else:
			# Arrived
			velocity = Vector2.ZERO
			
			
	elif check_role == "FETCH":
		# Scorer has a 2 part mission
		if not has_ball:
			# 1. Go get the ball
			var ball_node = get_tree().get_nodes_in_group("ball")[0]
			target_pos = ball_node.global_position
			distance_to_target = global_position.distance_to(target_pos)
			
			# run slightly faster for game pace
			var dir = global_position.direction_to(target_pos)
			velocity = dir * (current_speed * 0.75)
			
			
		else:
			# 2. Got the ball, walk to the defense spawn
			target_pos = court.get_node("DefenseSpawn").global_position
			distance_to_target = global_position.distance_to(target_pos)
			held_ball.is_dribbling = false
			
			if distance_to_target > 5.0:
				var dir = global_position.direction_to(target_pos)
				velocity = dir * (current_speed * 0.5)
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
				
				
			
				# Resume Game!
				court.resume_game()



func force_turnover():
	if held_ball:
		held_ball.is_dribbling = false
		var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		held_ball.throw(random_dir, Vector2.ZERO, 0.75)
		
		
		held_ball = null
		has_ball = false
		
		
	dribble_picked_up = false
	is_shooting = false
	is_tricking = false
	is_swiping = false
	jump_z = 0.0
	
	if jump_tween and jump_tween.is_valid():
		jump_tween.kill()
	if has_node("Sprite2D"):
		$Sprite2D.position.y = 0

func execute_crossover():
	is_tricking = true
	var trick_duration = 0.3
	
	# Tell the ball to animate the crossover
	held_ball.perform_crossover(trick_duration)
	
	# Determine Dash Direction (Toward's new ball hand)
	var side_dash = Vector2.RIGHT if held_ball.current_hand == "RIGHT" else Vector2.LEFT
	var dash_dir = side_dash
	
	# Game Feel/Polish: if player is moving, blend dash so it angles forward
	var current_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if current_input != Vector2.ZERO:
		dash_dir = (current_input * 2.0 + side_dash).normalized()
		
	# Apply a massive burst of velocity on the dash
	velocity = dash_dir * (current_speed * 1.7)
	
	# Wait for the tree to finish before giving controller back
	await get_tree().create_timer(trick_duration).timeout
	is_tricking = false
	
	#========= Eventually add style/mach meter stuff here...============

func attempt_swipe():
	is_swiping = true
	swipe_cooldown = 1.5
	
	var bot = get_parent().get_node("Defender")
	
	# Am I close enough and does the bot have the ball?
	if bot.has_ball and global_position.distance_to(bot.global_position) < swipe_range:
		
		# Dice roll o'clock
		var base_chance = 90
		var stat_diff = defense_rating - bot.handle_rating
		
		# Clamp the math min: 5, max: 95
		var success_chance = clamp(base_chance + stat_diff, 5, 95)
		var roll = randi() % 100
		
		print("Player Reaches! Need < ", success_chance, ". Rolled: ", roll)
		
		# The Result
		if roll < success_chance:
			print("RIPPED IT! Ball knocked loose!")
			# MACH INJECTION: NICE STEAL
			MachManager.add_mach(0.75)
			bot.force_turnover()
			RunTracker.add_steal()
		else:
			print("PLAYER WHIFFED THE STEAL!")
			
	else:
		print("PLAYER REACHED AT THE AIR! MOVE CLOSER!")
		
	# Whiff penalty freeze
	await get_tree().create_timer(0.4).timeout
	is_swiping = false

func start_jump_tween():
	jump_tween = create_tween()
	var peak_time = jump_duration / 2.0
	
	# GOING UP
	jump_tween.tween_property(self, "jump_z", 25.0, peak_time).set_trans(
									Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# GOING DOWN
	jump_tween.tween_property(self, "jump_z", 0.0, peak_time).set_trans(
									Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# If the Tween finishes and they nver let go, force a late shot
	jump_tween.finished.connect(func():
			if is_shooting:
				print("HELD TOO LONG! VERY LATE RELEASE!")
				execute_shot()
	)
	
func execute_shot():
	is_shooting = false
	
	# Stop them from floating if they release early
	if jump_tween and jump_tween.is_valid():
		jump_tween.kill()
		
	# Snap visuals back to ground
	if has_node("Sprite2D"): $Sprite2D.position.y = 0
	jump_z = 0.0
	
	#-- TIMING MATH --
	var gather_time = 0.15
	var time_to_peak = gather_time + (jump_duration / 2.0)	# 0.15 + 0.3 = 0.45s target
	
	var time_difference = abs(shoot_timer - time_to_peak)
	
	if time_difference < 0.1: # 100 millisecond window for a perfect release
		print("IRISH SPRING GREEN! Perfect Release! Double Shot %")
		# Add actual attribute implementation later here
	else:
		print("Normal Release. Off by: ", time_difference, " seconds.")
	
	
	# SAFETY NET FOR STEALS & STUFF
	if held_ball == null:
		print("Ball was stolen mid_air! Aborting shot!")
		dribble_picked_up = false
		return
	
	
	var hoops_in_scene = get_tree().get_nodes_in_group("hoop")
	if hoops_in_scene.size() > 0:
		var target_hoop = hoops_in_scene[0]
		var rim_position = target_hoop.get_node("ShotTarget").global_position
		
		get_parent().record_shot(self)
		held_ball.point_value = get_parent().pending_points
		
		var dist_to_hoop = global_position.distance_to(rim_position)
		if dist_to_hoop < 180.0:
			held_ball.layup_ball(rim_position)
		else:
			held_ball.shoot_ball(rim_position)
			
	held_ball = null
	has_ball = false
	dribble_picked_up = false

func attempt_block():
	is_contesting = true
	print("Player goes up for the block!")
	
	jump_tween = create_tween()
	var peak_time = jump_duration / 2.0
	var max_jump = 15 + (defense_rating * 0.15)
	
	# Going Up
	jump_tween.tween_property(self, "jump_z", max_jump, peak_time).set_trans(
															Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Going Down
	jump_tween.tween_property(self, "jump_z", 0.0, peak_time).set_trans(
															Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await jump_tween.finished
	is_contesting = false
	
func check_for_block():
	# Scan for the ball in the scene
	var ball_nodes = get_tree().get_nodes_in_group("ball")
	if ball_nodes.size() > 0:
		var active_ball = ball_nodes[0]
		
		# Only block it if it's officially in the air
		if active_ball.state == "SHOOTING":
			
			# Are we horizontally close
			if global_position.distance_to(active_ball.global_position) < 35.0:
				
				# 3D Interact: Are our Z-height matching?
				if abs(active_ball.z_height - jump_z) < 12.0:
					execute_block(active_ball)

func execute_block(active_ball):
	print("PLAYER SAYS UNH UH, NOT TODAY! BLOCKED!")
	
	# Stop checking for multiple blocks
	is_contesting = false
	
	# Send it flying back the other way
	var hoops = get_tree().get_nodes_in_group("hoop")
	if hoops.size() > 0:
		var target_hoop = hoops[0]
		var deflect_dir = (active_ball.global_position - target_hoop.global_position).normalized()
		active_ball.reject_shot(deflect_dir)
		# MACH INJECTION: SWAT
		MachManager.add_mach(1.0)
		
		# --- THE TRACKER ---
		RunTracker.add_block()
														


func execute_driving_finish(rim_position: Vector2, is_dunk: bool):
	print("Player triggers a driving finish!")
	
	has_control = false
	is_shooting = true	# Let's bot know we are mid-shot
	held_ball.is_dribbling = false
	
	# Move ball to the dominant/driving hand high up
	var hip_x = 25 if held_ball.current_hand == "RIGHT" else -25
	held_ball.position = Vector2(hip_x, -15)	# 15 pixels "up"
	
	var takeoff_time = 1.0
	var dir_to_rim = global_position.direction_to(rim_position)
	var target_spot = Vector2.ZERO
	var max_jump = 0.0
	var peak_scale = Vector2(1.0, 1.0)
	#===============================================
	# BRANCHING LOGIC
	#===============================================
	if is_dunk:
		print("Player goes up for the POSTER DUNK!")
		max_jump = 45.0 # Tie to attribute later
		peak_scale = Vector2(1.3, 1.3)
		var hoops = get_tree().get_nodes_in_group("hoop")
		if hoops.size() > 0 and hoops[0].has_node("DunkSpot"):
			target_spot = hoops[0].get_node("DunkSpot").global_position
		else:
			target_spot = rim_position - (dir_to_rim * 15.0) # Fallback
	
	else:
		print("Player goes up for the smooth LAYUP!")
		max_jump = 15.0 # Lower, controlled jump
		peak_scale = Vector2(1.2, 1.2)
		# Stop short! 60 pxls away from the rim
		target_spot = rim_position - (dir_to_rim * 60.0)
	#=================================================
	
	# 1. Glide to chosen spot
	var drive_tween = create_tween()
	drive_tween.tween_property(self, "global_position", 
											target_spot, takeoff_time / 2.0).set_trans(Tween.TRANS_SINE)
	
	
	
	# 2. Visual Jump
	jump_tween = create_tween()
	jump_tween.tween_property(self, "jump_z", max_jump, takeoff_time / 2.0).set_trans(
											Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if has_node("Sprite2D"):
		jump_tween.parallel().tween_property($Sprite2D, "scale", peak_scale, takeoff_time / 2.0).set_trans(
											Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Wait for apex
	await get_tree().create_timer(takeoff_time / 2.0).timeout
	
	# APEX ACTIONS
	if held_ball != null:
		get_parent().record_shot(self, is_dunk)
		held_ball.point_value = get_parent().pending_points
		held_ball.layup_ball(rim_position)
		held_ball = null
		has_ball = false
		dribble_picked_up = false
		
	# RIM HANG
	if is_dunk:
		await get_tree().create_timer(0.3).timeout
	
	# 3. Come back down
	jump_tween = create_tween()
	jump_tween.tween_property(self, "jump_z", 0.0, takeoff_time / 2.0).set_trans(
											Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if has_node("Sprite2D"):
		jump_tween.parallel().tween_property($Sprite2D, "scale", Vector2(
				1.0, 1.0), takeoff_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await jump_tween.finished
	
	# 4. Regain control (SAFETY NET)
	if get_parent().game_state == "PLAYING": has_control = true
	
	is_shooting = false
	if has_node("Sprite2D") : $Sprite2D.position.y = 0
	jump_z = 0.0

func apply_bump(bump_velocity: Vector2, duration: float):
	is_bumped = true
	velocity = bump_velocity
	
	if is_tricking: is_tricking = false
	
	await get_tree().create_timer(duration).timeout
	is_bumped = false

func check_physical_contact():
	# Only calculate bulldozer math if we are driving with the ball
	if not has_ball: return
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Did the player hit an entity that can be bumped?
		if collider.has_method("apply_bump"):
			
			# Don't trigger if someone is already sliding
			if is_bumped or collider.state == "BUMPED": continue
			
			var str_diff = strength - collider.strength
			var hit_normal = collision.get_normal()
			
			#============================
			# MOMENTUM SHIFT
			# Normal points FROM defender to us
			#============================
			if str_diff >= 15:
				# BULLDOZE: Offense runs them over
				print("BULLDOZER! Defender gets crushed!")
				# Push Defender away
				collider.apply_bump(-hit_normal * 400.0, 0.25)
				# Have defender try to make a steal mid bump
				collider.attempt_swipe()
				# MACH INJECTION
				MachManager.add_mach(0.75)
				
			elif str_diff <= -15:
				# BRICK WALL: Offense bounces off!
				print("BRICK WALL: Offense bounces off!")
				# Push player away
				apply_bump(hit_normal * 500.0, 0.15)
				
			else:
				# NEUTRAL: Both take a tiny step back to avoid sticking
				apply_bump(hit_normal * 200.0, 0.1)
				collider.apply_bump(-hit_normal * 200.0, 0.1)
				



func _vacuum_check():
	if not has_node("PickupZone"): return
	
	# Actively scan the zone every frame
	var bodies = $PickupZone.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("ball") and body.has_method("pickup"):
			if body.z_height > 3.0: continue
			
		#--------------------CHECK-UP FALLBACK----------------------------------------
			if "game_state" in get_parent() and get_parent().game_state == "CHECKING":
				if check_role != "FETCH":
					continue
		#-----------------------------------------------------------------------------
			
			if not body.is_held and body.can_be_picked_up and not is_shooting:
				# State Snapshot
				var previous_state = body.state
				var previous_owner = get_parent().current_possession
				var was_inbound_pass = get_parent().is_inbound_pass
				
				# Grab Ball
				body.pickup(self)
				held_ball = body # Remember which ball we just grabbed
				has_ball = true
				
				get_parent().register_possession_change(self, previous_state)
				
				# Use previous state cuz of OoOperations
				# Tell ref if we got a rebound or a steal
				if (previous_state == "LOOSE" or previous_state == "REBOUNDING") and get_parent().game_state != "CHECKING":
					if not was_inbound_pass:	
						get_parent().handle_rebound(self)
					
						if previous_state == "LOOSE" and previous_owner == self:
							print("Recovered Own Fumble! No Mach reward!")
						else:
							MachManager.add_mach(0.3) # HUSTLE BONUS


func walk_through_door(door_pos: Vector2):
	has_control = false
	is_shooting = false
	velocity = Vector2.ZERO
	
	var trans_time: float = 0.4
	var enter_tween = create_tween()
	enter_tween.set_parallel(true)
	
	# 1. Walk them to the center of the door and slightly up into the tunnel
	var target_pos = door_pos + Vector2(0, -30)
	enter_tween.tween_property(self, "global_position", target_pos, trans_time).set_trans(Tween.TRANS_SINE)
	
	# 2. Fade them into the darkness
	enter_tween.tween_property(self, "modulate:a", 0.0, trans_time)
	
	# 3. Shrink them slightly to sell 3D depth of walking away
	if has_node("Sprite2D"):
		enter_tween.tween_property($Sprite2D, "scale", Vector2(0.8, 0.8), trans_time)
