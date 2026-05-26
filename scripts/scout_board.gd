extends Control

@onready var opp_sprite = $VBoxContainer/TopRow/OpponentTexture
@onready var opp_name = $VBoxContainer/TopRow/Lbl_Opp_Name

@onready var opp_shooting_val = $VBoxContainer/StatsGrid/Lbl_ShootingValue
@onready var opp_finishing_val = $VBoxContainer/StatsGrid/Lbl_FinishingValue
@onready var opp_handle_val = $VBoxContainer/StatsGrid/Lbl_HandleValue
@onready var opp_defense_val = $VBoxContainer/StatsGrid/Lbl_DefenseValue
@onready var opp_speed_val = $VBoxContainer/StatsGrid/Lbl_SpeedValue
@onready var opp_strength_val = $VBoxContainer/StatsGrid/Lbl_StrengthValue


@onready var opp_ability_val = $VBoxContainer/AbilityRow/Lbl_AbilitiesValue
@onready var opp_arena_rule_val = $VBoxContainer/ArenaRow/Lbl_ArenaRuleValue

@onready var btn_leave_scout = $VBoxContainer/Btn_Leave



func _ready() -> void:
	visible = false
	btn_leave_scout.pressed.connect(_on_leave_button_pressed)


func open_menu():
	# 1. Freeze player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = false
		players[0].velocity = Vector2.ZERO
	
	populate_stats()
	
	# 2. Start it completely off screen to the right
	var screen_width = get_viewport_rect().size.x
	position.x = screen_width
	visible = true
	
	# 3. Swoop it in to the center
	var slide_tween = create_tween()
	slide_tween.tween_property(self, "position:x", 0.0, 0.75)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func populate_stats():
	var enemy_stats = GlobalData.get_current_enemy_data()
	# Set all values
	opp_name.text = enemy_stats.defender_name
	#opp_sprite.texture = GlobalData.get_current_enemy_data().accessory_sprite
	opp_shooting_val.text = str(enemy_stats.shooting_rating)
	opp_finishing_val.text = str(enemy_stats.finishing_rating)
	opp_handle_val.text = str(enemy_stats.handle_rating)
	opp_defense_val.text = str(enemy_stats.defense_rating)
	opp_speed_val.text = str(enemy_stats.speed_rating)
	opp_strength_val.text = str(enemy_stats.strength_rating)

	
	opp_ability_val.text = "N/A"
	
	
	opp_arena_rule_val.text = enemy_stats.inherent_rules_description


func _on_leave_button_pressed():
	var screen_width = get_viewport_rect().size.x
	
	# 1. Slide it back off screen to the right
	var slide_tween = create_tween()
	slide_tween.tween_property(self, "position:x", screen_width, 0.75)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
	
	# 2. Wait for it to finish sliding before turning it off
	await slide_tween.finished
	visible = false
	
	# 3. Unfreeze player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].has_control = true
	
