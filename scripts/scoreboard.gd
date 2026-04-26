extends Control

@onready var lbl_player_score = $PanelContainer/VBoxContainer/HBoxScore/Lbl_PlayerScore
@onready var lbl_bot_score = $PanelContainer/VBoxContainer/HBoxScore/Lbl_BotScore
@onready var lbl_player_title =$PanelContainer/VBoxContainer/HBoxScore/Lbl_PlayerTitle
@onready var lbl_bot_title = $PanelContainer/VBoxContainer/HBoxScore/Lbl_BotTitle
@onready var lbl_quarter = $PanelContainer/VBoxContainer/HBoxProgression/Lbl_QuarterValue
@onready var lbl_game = $PanelContainer/VBoxContainer/HBoxProgression/Lbl_GameValue
@onready var lbl_mach = $PanelContainer/VBoxContainer/HBoxProgression/Lbl_MachValue

func _ready():
	update_progression_ui()
	MachManager.mach_level_changed.connect(update_mach_display)


func update_scores(player_pts: int, bot_pts: int, current_mach: int):
	lbl_player_score.text = str(player_pts)
	lbl_bot_score.text = str(bot_pts)
	lbl_mach.text = str(current_mach)
	

func update_progression_ui():
	lbl_quarter.text = str(GameManager.current_quarter)
	lbl_game.text = str(GameManager.current_game)

func update_mach_display(new_mach: int):
	lbl_mach.text = str(new_mach)
