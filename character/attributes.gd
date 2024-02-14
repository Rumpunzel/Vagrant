class_name CharacterAttributes
extends Resource

@export var muscle := 0
@export var blood := 0
@export var guts := 0
@export var brain := 0
@export var nerve := 0
@export var heart := 0

func roll_stats(dice_pool: DicePool = DicePool.get_2d6()) -> void:
	muscle = DiceRoller.roll_sum(dice_pool)
	blood = DiceRoller.roll_sum(dice_pool)
	guts = DiceRoller.roll_sum(dice_pool)
	brain = DiceRoller.roll_sum(dice_pool)
	nerve = DiceRoller.roll_sum(dice_pool)
	heart = DiceRoller.roll_sum(dice_pool)

func _to_string() -> String:
	return """
Muscle: %d
Blood: %d
Guts: %d
Brain: %d
Nerve: %d
Heart: %d
""".strip_edges() % [ muscle, blood, guts, brain, nerve, heart ]
