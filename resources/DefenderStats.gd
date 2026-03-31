extends Resource
class_name DefenderStats

@export_group("Identity and Flavor")
@export var defender_name = "Unknown Challenger"
@export var playstyle: String = "Benchwarmer"
@export_multiline var intro_quote: String = "..."

@export_group("Physical Attributes")
@export var speed_multiplier: float = 1.0
@export var friction_multiplier: float = 1.0
@export var vertical_multiplier: float = 1.0
@export var wingspan_reach: float = 1.0

@export_group("Assets")
@export var body_sprite: Texture2D
@export var accessorty_sprite: Texture2D
@export var voice_sfx: AudioStream
