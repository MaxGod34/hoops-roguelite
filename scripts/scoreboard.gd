extends CanvasLayer

@onready var lbl_player_score = $Panel/VBoxContainer/HBoxScore/Lbl_PlayerScore
@onready var lbl_bot_score = $Panel/VBoxContainer/HBoxScore/Lbl_BotScore
@onready var lbl_player_title = $Panel/VBoxContainer/HBoxTitle/Lbl_PlayerTitle
@onready var lbl_bot_title = $Panel/VBoxContainer/HBoxTitle/Lbl_BotTitle

func update_scores(player_pts: int, bot_pts: int):
	lbl_player_score.text = str(player_pts)
	lbl_bot_score.text = str(bot_pts)
	
func show_game_over(winner_name: String):
	lbl_player_title.text = winner_name
	lbl_bot_title.text = "WINS!"
