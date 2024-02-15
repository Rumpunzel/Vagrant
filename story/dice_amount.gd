extends SpinBox

func update_dice_amount(available_hit_dice: int, die: DiceRoller.Dice) -> void:
	max_value = available_hit_dice
	suffix = "/ %dd%d" % [available_hit_dice, die]
	value = available_hit_dice
	editable = available_hit_dice > 0
