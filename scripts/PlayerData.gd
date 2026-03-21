extends Node

# 12 Attribute Matrix
var stats = {
	# Shooting
	"close_shot": 50,
	"mid_shot": 50,
	"three_pt": 50,
	# Finishing
	"layups": 50,
	"dunks": 50,
	# Handle/Rebound
	"ball_handling": 50,
	"rebounding": 50,
	# Defense
	"steal": 50,
	"block": 50,
	# Physicals
	"speed_accel": 50,
	"strength": 50,
	"vertical": 50
}

# Inventory
var equipment = {
	"left_shoe": null,
	"right_shoe": null,
	"left_arm": null,
	"right_arm": null,
	"headwear": null,
	"outfit": null,
	"ball": null
}

# Stat Upgrade Currency (Placeholder name)
var amps = 500

# -- STYX CONTRACTS --
var active_contracts = {}

func advance_game_state():
	var contracts_to_remove = []
	
	for contract in active_contracts:
		active_contracts[contract] -= 1
		if active_contracts[contract] <= 0:
			contracts_to_remove.append(contract)
			
	for contract in contracts_to_remove:
		active_contracts.erase(contract)
		print("Contract Expired: ", contract)


# -- HELPER FUNCTIONS --
func upgrade_stat(stat_name: String, amount: int):
	if stats.has(stat_name):
		stats[stat_name] += amount
		stats[stat_name] = clamp(stats[stat_name], 0, 100)
		print(stat_name + " upgraded to: " + str(stats[stat_name]))
