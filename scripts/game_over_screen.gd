extends CanvasLayer

@onready var lbl_title = $MenuBox/Lbl_Title
@onready var lbl_winner = $MenuBox/Lbl_Winner
@onready var lbl_stats = $MenuBox/Lbl_Stats
@onready var btn_restart = $MenuBox/Btn_Restart



func _ready():
	hide()
	btn_restart.pressed.connect(_on_restart_pressed)

func show_game_over(winner_name: String, p_pts: int, p_to: int):
	lbl_winner.text = "Outballed by the " + winner_name
	lbl_stats.text = "Player Stats:\nPoints: %d   |   Turnovers: %d" % [p_pts, p_to]
	show()


func _on_restart_pressed():
	get_tree().paused = false
	#--- Remove Curse(s) ---
	if GameManager.threads_disabled_next_game:
		GameManager.threads_disabled_next_game = false
		PlayerData.recalculate_thread_bonuses() # Give em their bonuses back
	#-----------------------
	GameManager.reset_run()
	get_tree().reload_current_scene()
