extends Node2D
# ---------------- UI REFERENCES ------------------
@onready var upgrade_menu = $UpgradeMenu
@onready var close_button = $UpgradeMenu/Panel/VBoxContainer/BottomRow/Btn_CloseMenu
@onready var lbl_amps = $UpgradeMenu/Panel/VBoxContainer/BottomRow/Lbl_Amps
# -- OFFENSE UPGRADE BUTTONS --
@onready var btn_close_shot = $UpgradeMenu/Panel/VBoxContainer/OffenseHBox/CloseShotCol/Btn_CloseShot
@onready var btn_mid_shot = $UpgradeMenu/Panel/VBoxContainer/OffenseHBox/MidShotCol/Btn_MidShot
@onready var btn_3pt = $UpgradeMenu/Panel/VBoxContainer/OffenseHBox/Col3pt/Btn_3pt
@onready var btn_layup = $UpgradeMenu/Panel/VBoxContainer/OffenseHBox/LayupCol/Btn_Layup
@onready var btn_dunk = $UpgradeMenu/Panel/VBoxContainer/OffenseHBox/DunkCol/Btn_Dunk
@onready var btn_ball_handle = $UpgradeMenu/Panel/VBoxContainer/OffenseHBox/BallHandleCol/Btn_BallHandle
# -- OFFENSE UPGRADE LABELS --
@onready var lbl_close_shot_val = $UpgradeMenu/Panel/VBoxContainer/OffenseHBox/CloseShotCol/Value_CloseShot
@onready var lbl_mid_shot_val = $UpgradeMenu/Panel/VBoxContainer/OffenseHBox/MidShotCol/Value_MidShot
@onready var lbl_3pt_val = $UpgradeMenu/Panel/VBoxContainer/OffenseHBox/Col3pt/Value_3pt
@onready var lbl_layup_val = $UpgradeMenu/Panel/VBoxContainer/OffenseHBox/LayupCol/Value_Layup
@onready var lbl_dunk_val = $UpgradeMenu/Panel/VBoxContainer/OffenseHBox/DunkCol/Value_Dunk
@onready var lbl_ball_handle_val = $UpgradeMenu/Panel/VBoxContainer/OffenseHBox/BallHandleCol/Value_BallHandle
# -- DEFENSE/REBOUND/PHYSICALS BUTTONS --
@onready var btn_speed_accel = $UpgradeMenu/Panel/VBoxContainer/DefRebPhysicalsHBox/SpeedAccelCol/Btn_SpeedAccel
@onready var btn_strength = $UpgradeMenu/Panel/VBoxContainer/DefRebPhysicalsHBox/StrengthCol/Btn_Strength
@onready var btn_vertical = $UpgradeMenu/Panel/VBoxContainer/DefRebPhysicalsHBox/VerticalCol/Btn_Vertical
@onready var btn_steal = $UpgradeMenu/Panel/VBoxContainer/DefRebPhysicalsHBox/StealCol/Btn_Steal
@onready var btn_block = $UpgradeMenu/Panel/VBoxContainer/DefRebPhysicalsHBox/BlockCol/Btn_Block
@onready var btn_rebound = $UpgradeMenu/Panel/VBoxContainer/DefRebPhysicalsHBox/ReboundCol/Btn_Rebound
# -- DEFENSE/REBOUND/PHYSICALS LABELS --
@onready var lbl_speed_accel_val = $UpgradeMenu/Panel/VBoxContainer/DefRebPhysicalsHBox/SpeedAccelCol/Value_SpeedAccel
@onready var lbl_strength_val = $UpgradeMenu/Panel/VBoxContainer/DefRebPhysicalsHBox/StrengthCol/Value_Strength
@onready var lbl_vertical_val = $UpgradeMenu/Panel/VBoxContainer/DefRebPhysicalsHBox/VerticalCol/Value_Vertical
@onready var lbl_steal_val = $UpgradeMenu/Panel/VBoxContainer/DefRebPhysicalsHBox/StealCol/Value_Steal
@onready var lbl_block_val = $UpgradeMenu/Panel/VBoxContainer/DefRebPhysicalsHBox/BlockCol/Value_Block
@onready var lbl_rebound_val = $UpgradeMenu/Panel/VBoxContainer/DefRebPhysicalsHBox/ReboundCol/Value_Rebound

var player_in_zone = false




func _ready() -> void:
	upgrade_menu.visible = false
	close_button.pressed.connect(_on_close_button_pressed)
	# -- OFFENSE BINDS --
	btn_close_shot.pressed.connect(_attempt_upgrade.bind("close_shot"))
	btn_mid_shot.pressed.connect(_attempt_upgrade.bind("mid_shot"))
	btn_3pt.pressed.connect(_attempt_upgrade.bind("three_pt"))
	btn_layup.pressed.connect(_attempt_upgrade.bind("layups"))
	btn_dunk.pressed.connect(_attempt_upgrade.bind("dunks"))
	btn_ball_handle.pressed.connect(_attempt_upgrade.bind("ball_handling"))
	# -- DEF/REB/PHYS BINDS --
	btn_speed_accel.pressed.connect(_attempt_upgrade.bind("speed_accel"))
	btn_strength.pressed.connect(_attempt_upgrade.bind("strength"))
	btn_vertical.pressed.connect(_attempt_upgrade.bind("vertical"))
	btn_steal.pressed.connect(_attempt_upgrade.bind("steal"))
	btn_block.pressed.connect(_attempt_upgrade.bind("block"))
	btn_rebound.pressed.connect(_attempt_upgrade.bind("rebound"))
	
	update_ui()



func _on_zone_upgrades_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_zone = true
		# Add a prompt later


func _on_zone_upgrades_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_zone = false

# Interaction Logic
func _process(_delta: float) -> void:
	if player_in_zone and not upgrade_menu.visible and Input.is_action_just_pressed("interact"):
		open_menu()
		
func open_menu():
	upgrade_menu.visible = true
	# Find player and freeze them
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = false
		
func _on_close_button_pressed():
	upgrade_menu.visible = false
	
	# Find player unfreeze them
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = true

func _attempt_upgrade(stat_name: String):
	var upgrade_cost = 100
	
	if PlayerData.amps >= upgrade_cost and PlayerData.base_stats[stat_name] < 100:
		PlayerData.amps -= upgrade_cost
		PlayerData.upgrade_stat(stat_name, 1)
		
		update_ui()
	else:
		print("Cannot upgrade! Out of amps or stat is maxed out!")
		
func update_ui():
	#lbl_amps.text = "Amps: " + str(PlayerData.amps)
	# Update 12 stat labels
	# OFFENSE
	lbl_close_shot_val.text = str(PlayerData.base_stats["close_shot"])
	lbl_mid_shot_val.text = str(PlayerData.base_stats["mid_shot"])
	lbl_3pt_val.text = str(PlayerData.base_stats["three_pt"])
	lbl_layup_val.text = str(PlayerData.base_stats["layups"])
	lbl_dunk_val.text = str(PlayerData.base_stats["dunks"])
	lbl_ball_handle_val.text = str(PlayerData.base_stats["ball_handling"])
	# DEFENSE
	lbl_speed_accel_val.text = str(PlayerData.base_stats["speed_accel"])
	lbl_strength_val.text = str(PlayerData.base_stats["strength"])
	lbl_steal_val.text = str(PlayerData.base_stats["steal"])
	lbl_block_val.text = str(PlayerData.base_stats["block"])
	lbl_rebound_val.text = str(PlayerData.base_stats["rebounding"])
