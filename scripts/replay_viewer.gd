extends Node2D

var is_playing: bool = false
var current_frame: int = 0
var playback_data: Array = []

@onready var ghost_player = $GhostContainer/GhostPlayer
@onready var ghost_bot = $GhostContainer/GhostBot
@onready var ghost_ball = $GhostContainer/GhostBall
@onready var ui_layer = $UI

var time_passed: float = 0.0
const FPS: float = 60.0
const FRAME_TIME: float = 1.0 / FPS



func _ready():
	hide()
	ui_layer.hide()

func start_replay():
	playback_data = HighlightManager.play_of_the_game
	
	if playback_data.size() == 0:
		print("No highlights recorded! Skipping to Victory Screen.")
		# Fallback just in case they won instantly with no Mach Generated
		return
	
	current_frame = 0
	is_playing = true
	show()
	ui_layer.show()
	
	print("PLAY OF THE GAME: ", playback_data.size(), " frames loaded.")


func _process(delta: float):
	if not is_playing or playback_data.size() == 0: return
	
	time_passed += delta
	
	# Only advance the tape if enough time has passed to match 60 FPS
	while time_passed >= FRAME_TIME:
		time_passed -= FRAME_TIME
	
		# 1. Grab the snapshot for the current frame
		var data = playback_data[current_frame]
		
		# 2. Apply Coordinates (incorporating the fake Z-height)
		ghost_player.global_position = data["player_pos"]
		ghost_player.position.y -= data["player_z"]
		
		ghost_bot.global_position = data["bot_pos"]
		ghost_bot.position.y -= data["bot_z"]
		
		ghost_ball.global_position = data["ball_pos"]
		ghost_ball.position.y += data["ball_sprite_z"]
		ghost_ball.scale = data["ball_scale"]
		
		# 3. Advance the tape
		current_frame += 1
		
		# 4. Loop back to the start if we hit the end of the 5 seconds
		if current_frame >= playback_data.size():
			current_frame = 0
