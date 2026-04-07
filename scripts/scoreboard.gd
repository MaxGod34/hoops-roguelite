extends CanvasLayer

@onready var lbl_player_score = $PanelContainer/VBoxContainer/HBoxScore/Lbl_PlayerScore
@onready var lbl_bot_score = $PanelContainer/VBoxContainer/HBoxScore/Lbl_BotScore
@onready var lbl_player_title =$PanelContainer/VBoxContainer/HBoxScore/Lbl_PlayerTitle
@onready var lbl_bot_title = $PanelContainer/VBoxContainer/HBoxScore/Lbl_BotTitle
@onready var lbl_quarter = $PanelContainer/VBoxContainer/HBoxProgression/Lbl_QuarterValue
@onready var lbl_game = $PanelContainer/VBoxContainer/HBoxProgression/Lbl_GameValue

func _ready():
	update_progression_ui()


func update_scores(player_pts: int, bot_pts: int):
	lbl_player_score.text = str(player_pts)
	lbl_bot_score.text = str(bot_pts)
	
func show_game_over(winner_name: String):
	lbl_player_title.text = winner_name
	lbl_bot_title.text = "WINS!"

func update_progression_ui():
	lbl_quarter.text = str(GameManager.current_quarter)
	lbl_game.text = str(GameManager.current_game)
