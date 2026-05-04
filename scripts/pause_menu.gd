extends CanvasLayer

@onready var stats_container = $MainLayout/ContentStage/Panel_Clipboard/Col2_Build/StatsGrid
@onready var threads_container = $MainLayout/ContentStage/Panel_Clipboard/Col2_Build/ThreadsGrid
@onready var ledger_container = $MainLayout/ContentStage/Panel_Clipboard/Col3_Ledger/ScrollContainer/LedgerList

# NAV REFERENCES
@onready var panel_clipboard = $MainLayout/ContentStage/Panel_Clipboard
@onready var panel_options = $MainLayout/ContentStage/Panel_Options
@onready var panel_guidebook = $MainLayout/ContentStage/Panel_Guidebook

# MAIN LEFT NAV BUTTONS
@onready var nav_btn_resume = $MainLayout/NavPanel/LeftNav/Btn_Resume
@onready var nav_btn_clipboard = $MainLayout/NavPanel/LeftNav/Btn_Clipboard
@onready var nav_btn_options = $MainLayout/NavPanel/LeftNav/Btn_Options
@onready var nav_btn_guidebook = $MainLayout/NavPanel/LeftNav/Btn_Guidebook
@onready var nav_btn_quit = $MainLayout/NavPanel/LeftNav/Btn_Quit

# Guidebook References
@onready var lbl_general_title = $MainLayout/ContentStage/Panel_Guidebook/VBox/ScrollContainer/ScrollVbox/Lbl_TitleGeneral
@onready var lbl_general_desc = $MainLayout/ContentStage/Panel_Guidebook/VBox/ScrollContainer/ScrollVbox/Lbl_ExplanationGeneral
@onready var lbl_threads_title = $MainLayout/ContentStage/Panel_Guidebook/VBox/ScrollContainer/ScrollVbox/Lbl_TitleThreads
@onready var lbl_threads_desc = $MainLayout/ContentStage/Panel_Guidebook/VBox/ScrollContainer/ScrollVbox/Lbl_ExplanationThreads
@onready var lbl_bait_title = $MainLayout/ContentStage/Panel_Guidebook/VBox/ScrollContainer/ScrollVbox/Lbl_TitleBait
@onready var lbl_bait_desc = $MainLayout/ContentStage/Panel_Guidebook/VBox/ScrollContainer/ScrollVbox/Lbl_ExplanationBait
@onready var lbl_locker_room_title = $MainLayout/ContentStage/Panel_Guidebook/VBox/ScrollContainer/ScrollVbox/Lbl_TitleLockerRoom
@onready var lbl_locker_room_desc = $MainLayout/ContentStage/Panel_Guidebook/VBox/ScrollContainer/ScrollVbox/Lbl_ExplanationLockerRoom

@onready var btn_general = $MainLayout/ContentStage/Panel_Guidebook/VBox/GuidebookNavPanel/GuidebookNav/Btn_General
@onready var btn_threads = $MainLayout/ContentStage/Panel_Guidebook/VBox/GuidebookNavPanel/GuidebookNav/Btn_Threads
@onready var btn_bait = $MainLayout/ContentStage/Panel_Guidebook/VBox/GuidebookNavPanel/GuidebookNav/Btn_Bait
@onready var btn_locker_room = $MainLayout/ContentStage/Panel_Guidebook/VBox/GuidebookNavPanel/GuidebookNav/Btn_LockerRoom


func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect Left Nav Buttons
	nav_btn_resume.pressed.connect(toggle_pause)
	nav_btn_clipboard.pressed.connect(_show_panel.bind(panel_clipboard))
	nav_btn_options.pressed.connect(_show_panel.bind(panel_options))
	nav_btn_guidebook.pressed.connect(_show_panel.bind(panel_guidebook))
	nav_btn_quit.pressed.connect(_quit_to_menu)
	
	# Connect Guidebook Buttons
	btn_general.pressed.connect(_show_guidebook.bind(lbl_general_title, lbl_general_desc))
	btn_threads.pressed.connect(_show_guidebook.bind(lbl_threads_title, lbl_threads_desc))
	btn_bait.pressed.connect(_show_guidebook.bind(lbl_bait_title, lbl_bait_desc))
	btn_locker_room.pressed.connect(_show_guidebook.bind(lbl_locker_room_title, lbl_locker_room_desc))
	

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"): # [ESC]
		toggle_pause()

func toggle_pause():
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	
	if new_pause_state:
		# Just paused, build data
		refresh_data()
		_show_panel(panel_clipboard)
		show()
	else:
		# Just unpaused
		hide()

func refresh_data():
	_update_stats_matrix()
	_update_equipment()
	_update_ledger()


# --- Hub Switcher ---
func _show_panel(target_panel: Control):
	# 1. Hide everything there currently
	panel_clipboard.hide()
	panel_options.hide()
	panel_guidebook.hide()
	
	# 2. Show only the one requested w guidebook exception
	target_panel.show()
	
	if target_panel == panel_guidebook:
		_show_guidebook(lbl_general_title, lbl_general_desc)


func _quit_to_menu():
	# Add Menu to go to later, for now just ends program
	get_tree().quit()


# --- Guidebook Switcher ---
func _show_guidebook(cat_title: Control, cat_desc: Control):
	# 1. Hide everything
	lbl_general_title.hide()
	lbl_general_desc.hide()
	lbl_threads_title.hide()
	lbl_threads_desc.hide()
	lbl_bait_title.hide()
	lbl_bait_desc.hide()
	lbl_locker_room_title.hide()
	lbl_locker_room_desc.hide()
	
	# 2. Show Selected Option
	cat_title.show()
	cat_desc.show()


#======================================
# COLUMN 2: PLAYER BUILD
#======================================
func _update_stats_matrix():
	# 1. Clear old data
	for child in stats_container.get_children():
		child.queue_free()
	
	# 2. Friendly Display Names (Inefficient but clean)
	var display_names = {
		"close_shot": "Close Shot", "mid_shot": "Mid Shot", "three_pt": "3PT",
		"layups": "Layups", "dunks": "Dunks", "ball_handling": "Ball Handle",
		"rebounding": "Rebound", "steal": "Steal", "block": "Block",
		"speed_accel": "Speed", "strength": "Strength", "mach": "Mach"
	}
	
	# 3. Generate the labels dynamically
	for stat_key in PlayerData.base_stats.keys():
		var base_val = PlayerData.base_stats[stat_key]
		var bonus_val = PlayerData.thread_bonuses[stat_key]
		var total_val = PlayerData.get_effective_stat(stat_key)
		
		var stat_label = Label.new()
		stat_label.theme = load("res://scenes/lbl_theme_stats_replay.tres")
		stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stat_label.add_theme_font_size_override("font_size", 28)
		var nice_name = display_names.get(stat_key, stat_key)
		
		# Format text based on buffs/debuffs
		if bonus_val > 0:
			stat_label.text = "%s: %d (+%d)" % [nice_name, total_val, bonus_val]
			stat_label.modulate = Color(0.2, 1.0, 0.2) # Green
		elif bonus_val < 0:
			stat_label.text = "%s: %d (%d)" % [nice_name, total_val, bonus_val]
			stat_label.modulate = Color(1.0, 0.2, 0.2) # Red
		else:
			stat_label.text = "%s: %d" % [nice_name, base_val]
			stat_label.modulate = Color(1, 1, 1) # White
		
		stats_container.add_child(stat_label)

func _update_equipment():
	for child in threads_container.get_children():
		child.queue_free()
	
	for slot in PlayerData.equipment.keys():
		var item = PlayerData.equipment[slot]
		var nice_slot = slot.replace("-", " ").capitalize()
		
		# Flat Button Instead of label
		var eq_btn = Button.new()
		eq_btn.flat = true
		eq_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		eq_btn.theme = load("res://scenes/lbl_theme_stats_replay.tres")
		eq_btn.custom_minimum_size = Vector2(445, 136)
		
		if item != null:
			eq_btn.text = nice_slot
			eq_btn.icon = item.item_texture
			eq_btn.expand_icon = false
			eq_btn.custom_minimum_size = Vector2(445, 136)
			
			eq_btn.modulate = Color(0.8, 0.8, 1.0) # Light blue
			
			# Hover signals
			eq_btn.mouse_entered.connect(_on_item_hovered.bind(item))
			eq_btn.mouse_exited.connect(_hide_item_tooltip)
		else:
			eq_btn.text = "%s\n\n[EMPTY]" % [nice_slot]
			eq_btn.modulate = Color(0.4, 0.4, 0.4) # Greyed Out
			eq_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		threads_container.add_child(eq_btn)

#============================
# COLUMN 3: THE LEDGER
#===========================
func _update_ledger():
	for child in ledger_container.get_children():
		child.queue_free()
	
	if GameManager.active_mutations.size() == 0:
		var empty_label = Label.new()
		empty_label.theme = load("res://scenes/lbl_theme_stats_replay.tres")
		empty_label.text = "-- No Active Curses --"
		empty_label.modulate = Color(0.5, 0.5, 0.5)
		empty_label.add_theme_font_size_override("font_size", 28)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ledger_container.add_child(empty_label)
		return
	
	print("(DEBUG) Generating ledger...")
	for mutation in GameManager.active_mutations:
		var bait = mutation["bait"]
		var remaining = mutation["remaining"]
		var is_warded = mutation.get("is_warded", false)
		
		# Generate New Flat Buttons
		var entry_btn = Button.new()
		entry_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry_btn.add_theme_font_size_override("font_size", 24)
		entry_btn.theme = load("res://scenes/lbl_theme_stats_replay.tres")
		
		# Set Sprite for a better in-menu reminder
		entry_btn.icon = bait.sprite
		entry_btn.expand_icon = false
		entry_btn.flat = true
		entry_btn.custom_minimum_size = Vector2(128, 128)
		
		
		var duration_text = ""
		if bait.duration_type == "Games":
			duration_text = "[%d GAMES]" % remaining
			entry_btn.modulate = Color(1.0, 0.8, 0.2) # Yellow warning
		elif bait.duration_type == "Charges":
			duration_text = "[%d CHARGES]" % remaining
			entry_btn.modulate = Color(1.0, 0.5, 0.0) # Orange warning
		elif bait.duration_type == "Quarter End":
			duration_text = "[QUARTER END]"
			entry_btn.modulate = Color(1.0, 0.2, 0.2) # Red warning
		
		# --- NEW WARD OVERRIDE ---
		if is_warded:
			duration_text += " [WARDED]"
			entry_btn.modulate = Color(0.4, 1.0, 1.0)
		
		entry_btn.text = " - %s\n%s" % [bait.bait_name, duration_text]
		
		# Hover Signals
		entry_btn.mouse_entered.connect(_on_bait_hovered.bind(bait, false))
		entry_btn.mouse_exited.connect(_hide_bait_tooltip)
		
		ledger_container.add_child(entry_btn)


#========================================
# HOVER & TOOLTIP HELPERS
#========================================
func _on_item_hovered(item: AccessoryData):
	if has_node("ItemTooltip"):
		$ItemTooltip.display_item(item)

func _hide_item_tooltip():
	if has_node("ItemTooltip"):
		$ItemTooltip.hide_tooltip()

func _on_bait_hovered(bait: BaitData, in_shop: bool):
	if has_node("BaitTooltip"):
		$BaitTooltip.display_bait(bait, in_shop)

func _hide_bait_tooltip():
	if has_node("BaitTooltip"):
		$BaitTooltip.hide_tooltip()
