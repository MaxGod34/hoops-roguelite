extends Resource
class_name DefenderStats

@export_group("Identity and Flavor")
@export var defender_name = "Unknown Challenger"
@export var playstyle: String = "Benchwarmer"
@export_multiline var intro_quote: String = "..."

@export_group("Physical Attributes")
@export var shooting_rating: int = 50
@export var finishing_rating: int = 50
@export var handle_rating: int = 50
@export var defense_rating: int = 50
@export var speed_rating: int = 50
@export var strength_rating: int = 50

@export var speed_multiplier: float = 1.0
@export var friction_multiplier: float = 1.0

@export_group("Court Rules")
@export var disable_dribble_moves: bool = false
@export var half_shot_clock: bool = false
@export var make_it_take_it: bool = false
@export var no_take_backs: bool = false
@export var no_threes: bool = false
@export var slippery_floor: bool = false
@export var alternating_shots: bool = false



@export_group("Assets")
@export var body_sprite: Texture2D
@export var accessory_sprite: Texture2D
@export var voice_sfx: AudioStream
