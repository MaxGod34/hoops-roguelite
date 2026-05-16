# Player.gd
extends CharacterBody2D

var active_shader: ShaderMaterial = null

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
var swipe_range: float = 90.0

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
	
	if has_node("VisualSkin"):
		active_shader = $VisualSkin.material as ShaderMaterial
		var breath_tween = create_tween().set_loops()
		breath_tween.tween_property($VisualSkin, "scale:y", 1.05, 1.0).set_trans(Tween.TRANS_SINE)
		breath_tween.tween_property($VisualSkin, "scale:y", 0.95, 1.0).set_trans(Tween.TRANS_SINE)
	
	
	update_player_stats()
	PlayerData.stats_updated.connect(update_player_stats)
	
func _process(delta: float):
	_update_mach_visuals(delta)

func _update_mach_visuals(delta: float):
	if active_shader == null or not has_node("VisualSkin"): return
	
	var current_mach = MachManager.current_mach
	
	# Target Vars
	var target_core: Color
	var target_outline: Color
	var target_wobble: float
	var target_intensity: float
	var target_outline_size: float
	
	# Determine Zeus' look based on current momentum
	if current_mach < 1.99:
		# Base Level
		target_core = Color("00E5FF") # Cyan Core
		target_outline = Color(0.5, 0.8, 1.0) * 1.1 # Mach 2 Coil
		target_wobble = 5.0
		target_intensity = 0.01
		target_outline_size = 2.0
		
	elif current_mach < 2.99:
		# Heating up
		target_core = Color("FFD700") # Gold Core
		target_outline = Color(0.5, 0.8, 1.0) * 1.2 # White Outline
		target_wobble = 10.0
		target_intensity = 0.02
		target_outline_size = 2.5
	
	elif current_mach < 3.99:
		# OVERDRIVE (Mach 3)
		target_core = Color("FFFFFF") # Pure white core
		target_outline = Color(0.8, 0.2, 1.0) * 1.3 # Cyan Outline
		target_wobble = 30.0
		target_intensity = 0.03
		target_outline_size = 3.0
	elif current_mach <= 4.99:
		# MACH 4!
		target_core = Color("FFFFFF")
		target_outline = Color(1.0, 0.8, 0.2) * 1.4
		target_wobble = 40.0
		target_intensity = 0.04
		target_outline_size = 4.0
	else:
		# Mach 5+
		target_core = Color("FFFFFF")
		target_outline = Color(1.0, 0.2, 0.2) * 1.5
		target_wobble = 50.0
		target_intensity = 0.05
		target_outline_size = 5.0
	
	# --- (Smooth Blending Lerp) ---
	$VisualSkin.modulate = $VisualSkin.modulate.lerp(target_core, delta * 4.0)
	var current_outline = active_shader.get_shader_parameter("outline_color") as Color
	if current_outline != null:
		active_shader.set_shader_parameter("outline_color", current_outline.lerp(target_outline, delta * 4.0))
	
	var current_wobble = active_shader.get_shader_parameter("wobble_speed") as float
	active_shader.set_shader_parameter("wobble_speed", lerpf(current_wobble, target_wobble, delta * 4.0))
	
	var current_intensity = active_shader.get_shader_parameter("wobble_intensity") as float
	active_shader.set_shader_parameter("wobble_intensity", lerpf(current_intensity, target_intensity, delta * 4.0))
	
	var current_outline_width = active_shader.get_shader_parameter("outline_width") as float
	active_shader.set_shader_parameter("outline_width", lerpf(current_outline_width, target_outline_size, delta * 4.0))



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
	if "game_state" in get_parent() and get_parent().game_state == "PRE_GAME":
		return # Play dead til the VS screen is done
	
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
			
		
		if has_node("VisualSkin"):
			$VisualSkin.position.y = -jump_z
		if is_contesting:
			check_for_block()
			

			
	else:
		# NORMAL MOVEMENT
		var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if direction:
			velocity = velocity.move_toward(direction * current_speed, ACCELERATION * delta)
			
			
			#====================== PAPER MARIO FLIP ===========================
			var target_facing = sign($VisualSkin.scale.x)
			
			if direction.x < 0:
				target_facing = -1.0
			elif direction.x > 0:
				target_facing = 1.0
			if target_facing == 0: target_facing = 1.0 # Failsafe
			
			$VisualSkin.scale.x = lerp($VisualSkin.scale.x, target_facing, 0.35)
			#===================================================================
		else:
			# Skid to a stop
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
		if has_node("VisualSkin"):
			var target_tilt = velocity.x * 0.001
			$VisualSkin.rotation = lerp($VisualSkin.rotation, target_tilt, 0.15)


		
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
		
	if has_node("VisualSkin"):
		$VisualSkin.position.y = -jump_z
	if held_ball != null and is_shooting:
		held_ball.position.y = -jump_z
	
	
	if Input.is_action_just_pressed("dribble_move") and held_ball and has_control and not is_shooting and not is_tricking:
		var can_dribble = true
		var active_stats = GlobalData.get_current_enemy_data()
		
		if active_stats != null and "DISABLE_CROSSOVERS" in active_stats.inherent_rules:
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
	if has_node("VisualSkin"):
		$VisualSkin.position.y = 0

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
	
	var active_stats = GlobalData.get_current_enemy_data()
	#~~~~~~~~~~~~~~~~~~~ --- EPSILON ERROR (Steals = -pts) --- ~~~~~~~~~~~~~~~~~
	var original_score = get_parent().player_score
	
	if active_stats != null:
		print("DEBUG: Checking for Epsilon Error...")
		if "FATAL_ERROR" in active_stats.inherent_rules:
			get_parent().player_score = max(0, get_parent().player_score - 3)
		elif "MARGIN_OF_ERROR" in active_stats.inherent_rules:
			get_parent().player_score = max(0, get_parent().player_score - 1)
	if get_parent().player_score != original_score:
		get_parent().score_changed.emit(
			get_parent().player_score, 
			GameManager.cumulative_opponent_score, 
			MachManager.visual_mach
		)
	#---------------------------------------------------------------------------
	
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
	if has_node("VisualSkin"): $VisualSkin.position.y = 0
	jump_z = 0.0
	
	# Safety Net
	if held_ball ==null:
		dribble_picked_up = false
		return
	
	var hoops_in_scene = get_tree().get_nodes_in_group("hoop")
	if hoops_in_scene.size() > 0:
		var target_hoop = hoops_in_scene[0]
		var rim_position = target_hoop.get_node("ShotTarget").global_position
		# Record Shot with Court so it sets pending_points (2 or 3)
		get_parent().record_shot(self)
		held_ball.point_value = get_parent().pending_points
		
		#=========================THE MONSTER MATH==============================
		var dist_to_hoop = global_position.distance_to(rim_position)
		var base_chance = float(shooting_rating) 
		var shot_mod = 1.0	# [1.0 for 2s], [0.5 for 3s]
		var release_mod = 1.0	# [1.0 for non-perfect], [2.0 for perfect]
		
		# 1. Shot Selection Modifier
		if get_parent().pending_points == 3:
			shot_mod = 0.5 # Otherwise it's a 2, keep at 1.0
		
		# 2. Release Timing
		var gather_time = 0.15
		var time_to_peak = gather_time + (jump_duration / 2.0)	# 0.15 + 0.3 = 0.45s target
		var time_diff = abs(shoot_timer - time_to_peak)
		
		if time_diff < 0.1: # Perfect Release
			release_mod = 2.0
			print("IRISH SPRING GREEN! Perfect Release (x2)")
		else:
			print("Normal Release. Off by: ", time_diff, "s")
		
		var raw_chance = base_chance * shot_mod * release_mod # All Bonuses
		
		# 3. Defender Pressure
		var bot = get_parent().get_node("Defender")
		var dist_to_bot = global_position.distance_to(bot.global_position)
		var contest_penalty = 0.0
		
		if dist_to_bot < 75.0: # Contest Range
			contest_penalty = bot.defense_rating * (1.0 - (dist_to_bot / 75.0))
			print("Contested! Penalty: -", contest_penalty)
		
		# 4. Final Dice Roll
		var final_chance = clamp(raw_chance - contest_penalty, 0.0, 100.0)
		
		# 4B. GAMMA ARENA RULE INTERCEPT
		var active_stats = GlobalData.get_current_enemy_data()
		if active_stats != null and get_parent().pending_points == 3:
			if "HIGH_GRAVITY" in active_stats.inherent_rules or "EVENT_HORIZON" in active_stats.inherent_rules:
				final_chance = 0.0
				print("GRAVITY CRUSH! 3-Pointers are physically impossible, besides one workaround!")
		
		# Apollo's Chalk Overrides ALL
		if GameManager.apollo_chalk_active:
			final_chance = 100.0
			GameManager.apollo_chalk_active = false
			print("APOLLO'S CHALK USED! Guaranteed Swish!")
		
		var roll = randf() * 100.0
		var is_make = roll <= final_chance
		print("Player Shot: Needed ", final_chance, " | Rolled: ", roll, " | Make: ", is_make)
		
		# 5. Apply Physics Target
		var final_target = rim_position
		held_ball.is_miss = not is_make		# STAMP YOUR DESTINY BALL
		
		if not is_make:
			# Offset the target so it hits rim/backboard
			var miss_offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
			miss_offset += miss_offset.normalized() * 15.0 # Ensure it's far enough away
			final_target += miss_offset
		#=======================================================================
		
		# Fire ball
		if dist_to_hoop < 180.0:
			held_ball.layup_ball(final_target)
		else:
			held_ball.shoot_ball(final_target)
	

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
	velocity = Vector2.ZERO
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
	var current_facing = sign($VisualSkin.scale.x)
	if current_facing == 0: current_facing = 1.0
	
	if is_dunk:
		print("Player goes up for the POSTER DUNK!")
		max_jump = 45.0 # Tie to attribute later
		peak_scale = Vector2(1.3 * current_facing, 1.3)
		var hoops = get_tree().get_nodes_in_group("hoop")
		if hoops.size() > 0 and hoops[0].has_node("DunkSpot"):
			target_spot = hoops[0].get_node("DunkSpot").global_position
		else:
			target_spot = rim_position - (dir_to_rim * 15.0) # Fallback
	
	else:
		print("Player goes up for the smooth LAYUP!")
		max_jump = 15.0 # Lower, controlled jump
		peak_scale = Vector2(1.2 * current_facing, 1.2)
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
	if has_node("VisualSkin"):
		jump_tween.parallel().tween_property($VisualSkin, "scale", peak_scale, takeoff_time / 2.0).set_trans(
											Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Wait for apex
	await get_tree().create_timer(takeoff_time / 2.0).timeout
	
	# APEX ACTIONS
	if held_ball != null:
		get_parent().record_shot(self, is_dunk)
		held_ball.point_value = get_parent().pending_points
		
		# 1. The Maeth
		var base_chance = float(finishing_rating) * (1.0 if is_dunk else 2.0)
		var bot = get_parent().get_node("Defender")
		var dist_to_bot = global_position.distance_to(bot.global_position)
		var contest_penalty = 0.0
		
		# Consider a variable to mess with contest range
		if dist_to_bot < 75.0:
			var def_multiplier = 1.5 if is_dunk else 1.0 # Dunks are harder on a defender
			contest_penalty = (bot.defense_rating * def_multiplier) * (1.0 - (dist_to_bot / 75.0))
			print("Paint Contested! Penalty: -", contest_penalty)
			
		var final_chance = clamp(base_chance - contest_penalty, 0.0, 100.0)
		
		# Apollo's Chalk Override
		if GameManager.apollo_chalk_active:
			final_chance = 100.0
			GameManager.apollo_chalk_active = false
			print("APOLLO'S CHALK USED! Guaranteed Swish!")
			
		var roll = randf() * 100.0
		var is_make = roll <= final_chance
		print("Finishing Attempt (Dunk: ", is_dunk, ") | Needed: ", final_chance, "% | Rolled: ", roll, " | Make: ", is_make)
		
		# 2. The Execution
		var final_target = rim_position
		held_ball.is_miss = not is_make
		
		if not is_make and is_dunk:
			print("STUFFED BY THE RIM!")
			MachManager.reduce_mach(1.0)
			get_tree().call_group("shot_clock", "reset_clock")
			
			# --- VIOLENT RIM REJECTION ---
			var start_pos = held_ball.global_position
			held_ball.get_parent().remove_child(held_ball)
			get_parent().add_child(held_ball)
			held_ball.global_position = start_pos
			held_ball.player = null
			
			# Calculate Angle straight back to the player
			var deflect_dir = (global_position - rim_position).normalized()
			if deflect_dir == Vector2.ZERO: deflect_dir = Vector2.DOWN
			
			# Spike ball like it's a block
			held_ball.reject_shot(deflect_dir)
			
			held_ball = null
			has_ball = false
			dribble_picked_up = false
			#--------------------------------
		else:
			# It's either a make or a missed layup
			if not is_make:
				var miss_offset = Vector2(randf_range(-25, 25), randf_range(-25, 25))
				miss_offset += miss_offset.normalized() * 15.0
				final_target += miss_offset
			
			held_ball.layup_ball(final_target)
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
	if has_node("VisualSkin"):
		jump_tween.parallel().tween_property($VisualSkin, "scale", Vector2(
				1.0 * current_facing, 1.0), takeoff_time / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await jump_tween.finished
	
	# 4. Regain control (SAFETY NET)
	if get_parent().game_state == "PLAYING": has_control = true
	
	is_shooting = false
	if has_node("VisualSkin") : $VisualSkin.position.y = 0
	jump_z = 0.0

func apply_bump(bump_velocity: Vector2, duration: float):
	is_bumped = true
	velocity = bump_velocity
	
	if is_tricking: is_tricking = false
	
	await get_tree().create_timer(duration).timeout
	is_bumped = false

func check_physical_contact():
	if is_bumped: return
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Did the player hit an entity that can be bumped?
		if collider.has_method("apply_bump"):
			
			# Don't trigger if someone is already sliding
			if is_bumped or ("is_bumped" in collider and collider.is_bumped) or collider.get("state") == "BUMPED":
				continue
			
			var str_diff = strength - collider.strength
			var hit_normal = collision.get_normal()
			
			#============================
			# Scenario 1: On-Ball/Bulldozer/Brick Wall
			# Normal points from defender to player
			#============================
			if has_ball:
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
			
			elif collider.get("has_ball") == true:
				pass
			
			#=====================================
			# Scenario 2: Off-Ball/Boxout
			#=====================================
			else:
				# Calculate a 90-degree sidestep vector to prevent vibrating and sticking
				var sidestep = hit_normal.orthogonal()
				
				# Randomize the sidestep direction so it feels organic
				if randf() > 0.5: sidestep = -sidestep
				
				if str_diff >= 15:
					# Box out: we are stronger, push them back to the side
					print("BOX OUT! Stronger player clears space!")
					collider.apply_bump((-hit_normal * 350.0) + (sidestep * 150.0), 0.2)
					
				elif str_diff <= -15:
					# BOXED out: we are weaker, we bounce off them
					print("BOXED OUT! Weaker player repelled! YOU!")
					apply_bump((hit_normal * 350.0) + (sidestep * 150.0), 0.2)
				
				else:
					# JOSTLE: equal strength, both take a quick bump sideways
					apply_bump((hit_normal * 200.0) + (sidestep * 150.0), 0.15)
					collider.apply_bump((-hit_normal * 200.0) - (sidestep * 150.0), 0.15)



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
	if has_node("VisualSkin"):
		enter_tween.tween_property($VisualSkin, "scale", Vector2(0.8, 0.8), trans_time)
