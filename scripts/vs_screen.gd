extends CanvasLayer

signal match_started

@onready var lbl_terminal = $MainSplit/Terminal/Lbl_TerminalText
@onready var enemy_sprite = $MainSplit/ContainmentZone/EnemySprite
@onready var containment_zone = $MainSplit/ContainmentZone
@onready var main_split = $MainSplit
@onready var background = $Background

var is_animating: bool = false
var is_exiting: bool = false
var intro_tween: Tween
var breath_tween: Tween

var first_boot_location: Array = ["INITIALIZING CLIMB","Debugging Tryout Algorithm","Initializing Tartarus Descent", "Surveying Mt. Othrys"]
var second_boot_sector: Array = ["ALPHA", "BETA", "GAMMA", "DELTA", "EPSILON", "ZETA", "ETA", "THETA", 
									"IOTA", "KAPPA", "LAMBDA", "MU", "NU", "XI", "OMICRON", "PI", "RHO", 
									"SIGMA", "TAU", "UPSILON", "PHI", "CHI", "PSI", "OMEGA"]

func _ready():
	#boot_sequence("Larry1", load("res://assets/opponents/Larry1V1.1.png"), ["NO_THREES"], false)
	pass

# Pass enemy data resource into function when the match is loaded
func boot_sequence(enemy_name: String, enemy_texture: Texture2D, arena_rules: Array, is_upgraded: bool):
	show()
	is_animating = true
	is_exiting = false
	lbl_terminal.visible_ratio = 0.0
	containment_zone.modulate.a = 0.0 # Hide initially
	
	main_split.modulate.a = 0.0
	if background: background.modulate.a = 1.0
	
	enemy_sprite.texture = enemy_texture
	
	#================================== Paint Job ==============================
	var mat = enemy_sprite.material as ShaderMaterial
	if not is_upgraded:
		enemy_sprite.modulate = Color("b500ff")
		if mat!= null:
			mat.set_shader_parameter("outline_color", Color("000000"))
	else: # Q3 and Q4
		enemy_sprite.modulate = Color("ff4500")
		if mat != null:
			mat.set_shader_parameter("outline_color", Color("ffff00")) # Yellow outline
	#===========================================================================
	
	# 1. Generate gritty terminal text dynamically
	var rule_string = "NONE"
	if arena_rules.size() > 0:
		rule_string = str(arena_rules) # ["NO_CROSSOVERS", "NO_THREES"]
	
	var threat_tier = "UPGRADED" if is_upgraded else "STANDARD"
	var rand_sector = randi() % 99 + 1
	
	var boot_text = "> " + first_boot_location[GameManager.current_quarter - 1] + "...\n"
	boot_text += "> SCANNING SECTOR " + second_boot_sector.pick_random() + "-" + str(rand_sector) + "...\n"
	boot_text += "> ANOMALY DETECTED.\n> CONTAINMENT PROTOCOLS ENGAGED.\n"
	boot_text += "> DECRYPTING ENTITY SIGNATURE...\n"
	boot_text += "> .......................................................\n\n"
	boot_text += "> WARNING: COMBATANT REVEALED.\n\n"
	boot_text += "> DESIGNATION: " + enemy_name.to_upper() + "\n\n"
	boot_text += "> THREAT LEVEL: " + threat_tier + "\n\n"
	boot_text += "> ARENA OVERRIDE: " + rule_string + "\n\n\n\n"
	boot_text += "> PRESS [SHOOT/PASS] TO INITIALIZE BALL."
	
	lbl_terminal.text = boot_text
	
	# 2. Sequence the Animation
	intro_tween = create_tween()
	# Fade in screen 0.25 sec
	intro_tween.tween_property(main_split, "modulate:a", 1.0, 0.25)
	# Type out first half
	intro_tween.chain().tween_property(lbl_terminal, "visible_ratio", 0.5, 2.0).set_trans(Tween.TRANS_LINEAR)
	# Flash Conatinment Box
	intro_tween.tween_callback(flash_containment_box)
	# Type the rest (identity and rules)
	intro_tween.tween_property(lbl_terminal, "visible_ratio", 1.0, 2.0).set_trans(Tween.TRANS_LINEAR)
	# Done
	intro_tween.finished.connect(func(): is_animating = false)

func flash_containment_box():
	# Snap visibility on, flash pure white then return to normal
	containment_zone.modulate.a = 1.0
	
	enemy_sprite.pivot_offset = enemy_sprite.size / 2.0
	
	var mat = enemy_sprite.material as ShaderMaterial
	var original_color = enemy_sprite.modulate
	var original_wobble = 5.0
	
	if mat != null:
		var param = mat.get_shader_parameter("wobble_speed")
		if param != null: original_wobble = param
	
	# Glitch Snap
	enemy_sprite.modulate = Color("ffd700")
	enemy_sprite.scale = Vector2(0.1, 2.2)
	
	if mat != null:
		mat.set_shader_parameter("wobble_speed", 100.0)
	
	
	var flash_tween = create_tween()
	flash_tween.set_parallel(true)
	flash_tween.tween_property(enemy_sprite, "modulate", original_color, 0.1).set_trans(Tween.TRANS_BOUNCE)
	
	flash_tween.tween_property(enemy_sprite, "scale", Vector2(1.0, 1.0), 0.3)\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_OUT)
	
	
	if mat != null:
		flash_tween.tween_property(mat, "shader_parameter/wobble_speed", original_wobble, 0.5)\
			.set_trans(Tween.TRANS_EXPO)\
			.set_ease(Tween.EASE_OUT)
	
	flash_tween.chain().tween_callback(start_breathing)
	
	
# Skip/Override
func _input(event):
	# If player presses interact/shoot/pass while animating, skip the typewriter
	if is_animating and event.is_action_pressed("interact"):
		if intro_tween and intro_tween.is_valid():
			intro_tween.kill()
		
		# Snap everything to its final state
		if background: background.modulate.a = 1.0
		main_split.modulate.a = 1.0
		lbl_terminal.visible_ratio = 1.0
		containment_zone.modulate.a = 1.0
		
		enemy_sprite.modulate = Color("ff4500") if "UPGRADED" in lbl_terminal.text else Color("b500ff")
		enemy_sprite.scale = Vector2.ONE
		start_breathing()
		
		is_animating = false
		get_viewport().set_input_as_handled()
	
	# If animation is done and they press it again, start the match, raise/check exit flag:
	elif not is_animating and not is_exiting and event.is_action_pressed("interact"):
		start_match()


func start_match():
	is_exiting = true
	
	match_started.emit()
	
	var outro_tween = create_tween()
	
	outro_tween.parallel().tween_property(main_split, "modulate:a", 0.0, 0.2)
	if background:
		outro_tween.parallel().tween_property(background, "modulate:a", 0.0, 0.2)
	
	await outro_tween.finished
	hide()



# BREATHIN, BREATHIN, BITCH STOP BREATHIN
func start_breathing():
	enemy_sprite.pivot_offset = enemy_sprite.size / 2.0
	
	if breath_tween and breath_tween.is_valid():
		breath_tween.kill()
	
	breath_tween = create_tween().set_loops()
	breath_tween.tween_property(enemy_sprite, "scale", Vector2(1.04, 1.04), 0.75)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	breath_tween.tween_property(enemy_sprite, "scale", Vector2(0.96, 0.96), 0.75)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
