extends VBoxContainer

func update_hit_dice(character: Character) -> void:
	%d4.update_hit_dice(character.get_hit_dice_count(Rules.d4), character.get_hit_dice_count(Rules.d4, true))
	%d6.update_hit_dice(character.get_hit_dice_count(Rules.d6), character.get_hit_dice_count(Rules.d6, true))
	%d8.update_hit_dice(character.get_hit_dice_count(Rules.d8), character.get_hit_dice_count(Rules.d8, true))
	%d10.update_hit_dice(character.get_hit_dice_count(Rules.d10), character.get_hit_dice_count(Rules.d10, true))
	%d12.update_hit_dice(character.get_hit_dice_count(Rules.d12), character.get_hit_dice_count(Rules.d12, true))
