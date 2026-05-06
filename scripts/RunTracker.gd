extends Node


#================================================
# SIGNALS
#================================================
# On Court Actions
signal steal_achieved
signal block_achieved
signal points_scored(amount: int, is_dunk: bool)
signal rebound_achieved(is_offensive: bool)
signal turnover_committed

# Locker Room Actions/Scrub
signal energy_spent(amount: int)
signal thread_sacrifice(altar_section: String) # Tithe, Aegis, Attonement
signal points_scrubbed(amount: int)


#================================================
# STAT VAULTS
#================================================
var run_stats: Dictionary = {}
var game_stats: Dictionary = {}


func _ready() -> void:
	reset_run_stats()
	reset_game_stats()





#================================================
# LIFECYCLE MANAGEMENT
#================================================
func reset_run_stats():
	run_stats = {
		"points": 0, "rebounds": 0, "steals": 0, "blocks": 0,  "turnovers": 0, 
		"energy_spent": 0, "threads_burned": 0, "total_scrubbed": 0
	}

func reset_game_stats():
	game_stats = {
		"points": 0, "rebounds": 0, "steals": 0, "blocks": 0, "turnovers": 0
	}


#================================================
# EVENT TRIGGERS
#================================================
func add_steal():
	run_stats["steals"] += 1
	game_stats["steals"] += 1
	steal_achieved.emit()

func add_block():
	run_stats["blocks"] += 1
	game_stats["blocks"] += 1
	block_achieved.emit()

func add_points(amount: int, is_dunk: bool):
	run_stats["points"] += amount
	game_stats["points"] += amount
	points_scored.emit(amount, is_dunk)

func add_turnover():
	run_stats["turnovers"] += 1
	game_stats["turnovers"] += 1
	turnover_committed.emit()

func add_rebound(is_offensive: bool):
	run_stats["rebounds"] += 1
	game_stats["rebounds"] += 1
	rebound_achieved.emit(is_offensive)

func track_energy_spent(amount: int):
	run_stats["energy_spent"] += amount
	energy_spent.emit()

func add_thread_burned(altar_section: String):
	run_stats["threads_burned"] += 1
	thread_sacrifice.emit(altar_section)

func track_scrub(amount: int):
	run_stats["total_scrubbed"] += amount
	points_scrubbed.emit(amount)
