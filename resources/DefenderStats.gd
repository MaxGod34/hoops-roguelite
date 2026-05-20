class_name DefenderStats extends Resource

@export_group("Identity and Flavor")
@export var defender_name = "Unknown Challenger"
@export var playstyle: String = "Benchwarmer"
@export_multiline var intro_quote: String = "..."
@export var is_upgraded_form: bool = false

@export_group("Base Stats")
@export var shooting_rating: int = 50
@export var finishing_rating: int = 50
@export var handle_rating: int = 50
@export var defense_rating: int = 50
@export var speed_rating: int = 50
@export var strength_rating: int = 50

@export var speed_multiplier: float = 1.0
@export var friction_multiplier: float = 1.0
@export var inherent_rules: Array[String] = [] #NO_TAKEBACKS
@export_multiline var inherent_rules_description: String = ""
# ALL TAGS HERE
# (NO_TAKEBACKS, NO_THREES,) HALF_SHOT_CLOCK, DISABLE_CROSSOVERS, SLIPPERY FLOOR, 
#(BOSS) ALTERNATING_SHOTS, MAKE_IT_TAKE_IT
@export var upgraded_rules: Array[String] = []
@export_multiline var upgraded_rules_description: String = ""

@export_group("Upgraded Stats")
@export var up_shooting: int = 50
@export var up_finishing: int = 50
@export var up_handle: int = 50
@export var up_defense: int = 50
@export var up_speed: int = 50
@export var up_strength: int = 50


@export_group("Assets")
@export var body_sprite: Texture2D
@export var upgraded_sprite: Texture2D
@export var accessory_sprite: Texture2D
@export var voice_sfx: AudioStream
