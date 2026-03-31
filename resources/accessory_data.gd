extends Resource
class_name AccessoryData

@export var item_name: String = "Unknown Item"
@export_enum("head", "outfit", "ball", "left_shoe", "right_shoe", "left_arm", "right_arm") var slot_type: String = "ball"
@export var item_texture: Texture2D

# Potential Attribute Buffs
@export var close_shot_bonus: int = 0
@export var mid_shot_bonus: int = 0
@export var three_pt_bonus: int = 0
@export var layups_bonus: int = 0
@export var dunks_bonus: int = 0
@export var ball_handling_bonus: int = 0
@export var speed_bonus: int = 0
@export var strength_bonus: int = 0
@export var vertical_bonus: int = 0
@export var steal_bonus: int = 0
@export var block_bonus: int = 0
@export var rebounding_bonus: int = 0

# Unique Passive Effects (ID)
@export var passive_effect: String = ""



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
