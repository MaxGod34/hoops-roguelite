extends Node2D
@onready var lbl_energy_wall = $Lbl_EnergyWall

func _ready() -> void:
	lbl_energy_wall.text = "ENERGY: " + str(GameManager.current_energy)
func _process(_delta: float) -> void:
	lbl_energy_wall.text = "ENERGY: " + str(GameManager.current_energy)

# LOOK AT ME, I'M EMPTY, FRIGGIN' EMPTY
# YOU LIKE THAT?!
# HUH?!
# HUH??!!
# HUH???!!!
# GOT A NEW STATION
# TAKE IT TO ST. ELSEWHERE BUB
#8===============================================================================================>
