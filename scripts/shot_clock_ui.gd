extends CanvasLayer

@onready var time_label = $Lbl_Shot_Clock_Remaining

var max_time: float = 30.0
var current_time: float = 30.0
var is_running: bool = false

var normal_color = Color.WHITE
var warning_color = Color.RED


func _ready() -> void:
	reset_clock()
	# Auto-start for testing
	start_clock()

func _process(delta: float) -> void:
	if is_running:
		current_time -= delta
		
		if current_time <= 0.0:
			current_time = 0.0
			trigger_violation()
			
		update_display()
		
func update_display():
	if current_time < 5.0:
		time_label.text = str(snapped(current_time, 0.1))
		time_label.add_theme_color_override("font_color", warning_color)
		
	else:
		time_label.text = str(int(ceil(current_time)))
		time_label.add_theme_color_override("font_color", normal_color)
		
# Public Functions

func start_clock():
	is_running = true
	
func stop_clock():
	is_running = false
	
func reset_clock():
	current_time = max_time
	update_display()
	
func trigger_violation():
	is_running = false
	time_label.text = "0.0"
	time_label.add_theme_color_override("font_color", warning_color)
	print("BZZZZZZZ! SHOT CLOCK VIOLATION!")
	# Add change possession later
