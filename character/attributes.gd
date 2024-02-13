class_name CharacterAttributes
extends Resource

signal attributes_changed(new_attributes: CharacterAttributes)

@export var muscle := 0
@export var blood := 0
@export var guts := 0
@export var brain := 0
@export var nerve := 0
@export var heart := 0

func roll_stats(dice_pool: DicePool = DicePool.get_2d6()) -> void:
	muscle = dice_pool.roll_sum()
	blood = dice_pool.roll_sum()
	guts = dice_pool.roll_sum()
	brain = dice_pool.roll_sum()
	nerve = dice_pool.roll_sum()
	heart = dice_pool.roll_sum()
	attributes_changed.emit(self)

func _to_string() -> String:
	return """
Muscle: %d
Blood: %d
Guts: %d
Brain: %d
Nerve: %d
Heart: %d
""".strip_edges() % [ muscle, blood, guts, brain, nerve, heart ]
