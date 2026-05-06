extends Node2D
@onready var lbl_energy_wall = $Lbl_EnergyWall
@onready var lbl_banked_wall = $Lbl_BankedWall
@onready var lbl_opponent_score = $Lbl_OpponentScore

func _ready() -> void:
	lbl_energy_wall.text = "ENERGY: " + str(GameManager.current_energy)
	lbl_banked_wall.text = "BANKED: " + str(GameManager.banked_energy)
	lbl_opponent_score.text = "OPP\n" + str(GameManager.cumulative_opponent_score)
func _process(_delta: float) -> void:
	lbl_energy_wall.text = "ENERGY: " + str(GameManager.current_energy)
	lbl_banked_wall.text = "BANKED: " + str(GameManager.banked_energy)
	lbl_opponent_score.text = "OPP\n" + str(GameManager.cumulative_opponent_score)

# LOOK AT ME, I'M EMPTY, FRIGGIN' EMPTY
# YOU LIKE THAT?!
# DO YA?
# DO YA?!
# HUH?!
# HUH??!!
# HUH???!!!
# GOT A NEW STATION?
# TAKE IT TO ST. ELSEWHERE BUB
#8===============================================================================================>
