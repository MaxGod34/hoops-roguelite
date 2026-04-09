extends CanvasLayer

@onready var ball = $TextureRect
@onready var bg_fade = $BgFade

@onready var screen_center = get_viewport().get_visible_rect().size / 2

func _ready():
	bg_fade.modulate.a = 0
	ball.position = Vector2(
		screen_center.x - (ball.size.x / 2), 
		get_viewport().get_visible_rect().size.y + 100)
	ball.scale = Vector2.ZERO


func transition_to_scene(target_scene_path: String):
	# Lock input so the player can't pause or move during transition
	get_tree().root.set_process_input(false)
	
	var transition_tween = create_tween()
	
	# PHASE 1: in which Dorris gets her Orts 
	# THE TOSS UP
	# Bring ball to the center of the screen while slightly scaling it up
	transition_tween.tween_property(ball, "position", 
		Vector2(screen_center.x - (ball.size.x/2), 
		screen_center.y - (ball.size.y/2)), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	transition_tween.parallel().tween_property(ball, "scale", Vector2(2.0, 2.0), 0.3)
	
	# PHASE 2: ELECTIRC SMDOO
	# At the camera now
	# Scale the ball massively to cover the screen. Fase the background in just in case the round ball can't cover
	transition_tween.tween_property(ball, "scale", 
		Vector2(50.0, 50.0), 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	
	transition_tween.parallel().tween_property(bg_fade, "modulate:a", 1.0, 0.2).set_delay(0.2)
	
	# PHASE 3: REVENGE OF THE SCRIPT
	# Scene Swap
	# Wait for the ball to fully cover the screen, then instantly change the level
	await transition_tween.finished
	get_tree().change_scene_to_file(target_scene_path)
	
	# PHASE 4: IDK MAN
	# Reveal
	var reveal_tween = create_tween()
	
	# Shrink the ball back down and fade the background out
	reveal_tween.tween_property(ball, "scale", 
		Vector2.ZERO, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	reveal_tween.parallel().tween_property(bg_fade, "modulate:a", 0.0, 0.3)
	
	# Put the ball back down and fade the background out
	await reveal_tween.finished
	ball.position = Vector2(screen_center.x - (ball.size.x / 2), get_viewport().get_visible_rect().size.y + 100)
	
	# Give the player their controls back
	get_tree().root.set_process_input(true)
	
	
