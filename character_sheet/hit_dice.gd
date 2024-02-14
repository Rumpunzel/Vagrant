extends HBoxContainer

func update_hit_dice(new_hit_dice: DicePool) -> void:
	if new_hit_dice == null:
		%d4.update_counter(0)
		%d6.update_counter(0)
		%d8.update_counter(0)
		%d10.update_counter(0)
		%d12.update_counter(0)
	else:
		%d4.update_counter(new_hit_dice.get_dice_count(DiceRoller.Dice.d4))
		%d6.update_counter(new_hit_dice.get_dice_count(DiceRoller.Dice.d6))
		%d8.update_counter(new_hit_dice.get_dice_count(DiceRoller.Dice.d8))
		%d10.update_counter(new_hit_dice.get_dice_count(DiceRoller.Dice.d10))
		%d12.update_counter(new_hit_dice.get_dice_count(DiceRoller.Dice.d12))
